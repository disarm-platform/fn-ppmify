library(ppmify)
source("function/helpers.R")
library(httr)

function(params) {
  # run function and catch result

  points <- params$points
  offset_raster <- params$offset
  reference_raster <- offset_raster # TODO - allow this to be controlled as parameter in function when offset not provided using boundary and resolution
  points_coords <- st_coordinates(points)
  
  # Make ppmify object
  ppmx <- ppmify::ppmify(points_coords, 
                         area = offset_raster,
                         #covariates = offset_raster, 
                         density = params$density, #TODO change to be automatic
                         method = "grid")
  
  # Aggregate points in space/time (i.e. aggregate points in same pixel)
  ppm_cases_points_counts <- aggregate_points_space_time(points, ppmx, 3, reference_raster)
  
  # Make these population extractions the weights
  ppm_cases_points_counts$weights <- raster::extract(offset_raster,
                                                     cbind(ppm_cases_points_counts$x, ppm_cases_points_counts$y))
  
  # If an offset (population) is provided, change the weights to be scaled by population
  if(!is.null(params$offset)){
    ppm_int_points_period <- get_int_points_offset_weights(ppmx, offset_raster, params$num_periods)
  }
  
  # add model month column for integration points (already generated as 'month')
  ppm_df <- rbind(ppm_cases_points_counts, ppm_int_points_period)

  # add column of 1's to cells with cases and 0's to cells without
  # this will act as your outcome in the poisson model
  ppm_df$outcome <- ifelse(ppm_df$points > 0, 1, 0)
  
  # change any 0's in the points column to 1
  # this will act as regression weights in the poisson model
  ppm_df$regression_weights <- ppm_df$points
  ppm_df$regression_weights[ppm_df$regression_weights == 0] <- 1
  
  # divide the offset by the number of cases in each cell
  ppm_df$weights <- ppm_df$weights/ppm_df$regression_weights
  
  # Get covariate values at data and prediction points
  ##### AT data points
  ppm_df_sf <- st_as_sf(SpatialPoints(ppm_df[,c("x", "y")]))
  input_data_list <- list(
    points = geojson_list(ppm_df_sf),
    layer_names = c("elev_m", "dist_to_water_m", paste0("bioclim", c(1, 4, 12, 15)))
  )
  
  response <-
    httr::POST(
      url = "https://faas.srv.disarm.io/function/fn-covariate-extractor",
      body = as.json(input_data_list),
      content_type_json(),
      timeout(300)
    )
  
  response_content <- content(response)
  ppm_df_sf_with_covar <- st_read(as.json(response_content$result), quiet = TRUE)
  
  # Merge with ppm_df 
  ppm_df <- cbind(ppm_df, as.data.frame(ppm_df_sf_with_covar))

  if(params$prediction_frame==FALSE){
    return(list(ppm_df))
  }else{
  
  ##### At prediction points
  pred_point_coords <- coordinates(reference_raster)[which(!is.na(reference_raster[])),]
  pred_points_sf <- st_as_sf(SpatialPoints(pred_point_coords))
  input_data_list_pred_points <- list(
    points = geojson_list(pred_points_sf),
    layer_names = c("elev_m", "dist_to_water_m", paste0("bioclim", c(1, 4, 12, 15)))
  )
  
  response_pred_points <-
    httr::POST(
      url = "https://faas.srv.disarm.io/function/fn-covariate-extractor",
      body = as.json(input_data_list_pred_points),
      content_type_json(),
      timeout(300)
    )
  
  response_content_pred_points <- content(response_pred_points)
  pred_points_with_covar <- st_read(as.json(response_content_pred_points$result), quiet = TRUE)
  ppm_df_pred <- cbind(pred_points_with_covar, pred_point_coords)
  ppm_df_pred$offset <- offset_raster[which(!is.na(offset_raster[]))]
  
  return(list(ppm_df = ppm_df,
              ppm_df_pred = ppm_df_pred))
  }
}

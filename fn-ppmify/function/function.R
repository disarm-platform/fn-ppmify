library(ppmify)
source("function/helpers.R")
library(httr)

function(params) {
  # run function and catch result

  points <- params$points
  exposure_raster <- params$exposure
  prediction_exposure_raster <- params$prediction_exposure
  prediction_exposure_raster <- raster::resample(prediction_exposure_raster, exposure_raster)
  reference_raster <- exposure_raster # TODO - allow this to be controlled as parameter in function when exposure not provided using boundary and resolution
  points_coords <- st_coordinates(points)
  
  # Make ppmify object
  ppmx <- ppmify::ppmify(points_coords, 
                         area = exposure_raster,
                         #covariates = exposure_raster, 
                         density = params$density, #TODO change to be automatic
                         method = "grid")
  
  # Aggregate points in space/time (i.e. aggregate points in same pixel)
  ppm_cases_points_counts <- aggregate_points_space_time(points, ppmx, params$num_periods, params$date_start_end, reference_raster)
  
  # Make these population extractions the weights
  ppm_cases_points_counts$exposure <- raster::extract(exposure_raster,
                                                     cbind(ppm_cases_points_counts$x, ppm_cases_points_counts$y))
  
  # If an exposure (population) is provided, change the weights to be scaled by population
  if(!is.null(params$exposure)){
    ppm_int_points_period <- get_int_points_exposure_weights(ppmx, exposure_raster, params$num_periods)
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
  
  # divide the exposure by the number of cases in each cell
  ppm_df$weights <- ppm_df$weights/ppm_df$regression_weights
  
  # Get covariate values at data and prediction points
  ##### AT data points
  ppm_df_sf <- st_as_sf(SpatialPoints(ppm_df[,c("x", "y")]))
  input_data_list <- list(
    points = geojson_list(ppm_df_sf),
    layer_names = params$layer_name,
    resolution = params$resolution
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
  
  # Drop unnessecary columns
  ppm_df <- subset(ppm_df, select=-c(weights, points, geometry))

  if(params$prediction_frame==FALSE){
    return(list(ppm_df = ppm_df))
  }else{
  
  ##### At prediction points
  pred_point_coords <- coordinates(reference_raster)[which(!is.na(reference_raster[])),]
  pred_points_sf <- st_as_sf(SpatialPoints(pred_point_coords))
  input_data_list_pred_points <- list(
    points = geojson_list(pred_points_sf),
    layer_names = params$layer_name
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
  ppm_df_pred$exposure <- prediction_exposure_raster[which(!is.na(exposure_raster[]))]
  
  # Drop unnessecary columns
  ppm_df_pred <- as.data.frame(ppm_df_pred)
  ppm_df_pred <- subset(ppm_df_pred, select=-c(geometry))
  
  return(list(ppm_df = ppm_df,
              ppm_df_pred = ppm_df_pred))
  }
}

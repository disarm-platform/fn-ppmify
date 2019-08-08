library(lubridate)
library(velox)

get_int_points_exposure_weights <- function(ppmx, offset_raster, num_periods){

  # First identify which are the local_cases and integration rows
  # in the ppm object
  ppm_int_points <- ppmx[ppmx$points==0,]
  ppm_case_points_coords <- ppmx[ppmx$points==1,c("x", "y")]
  
  # extract population within each voronoi polygon around each integration point
  # First remove any pixels with cases as you need to estimate population in pixels without cases
  dd <- deldir::deldir(ppm_int_points$x, ppm_int_points$y)
  tiles <- deldir::tile.list(dd)
  
  
  offset_raster_non_case_pixels <- offset_raster
  offset_raster_non_case_pixels[raster::cellFromXY(offset_raster_non_case_pixels,
                                                   ppm_case_points_coords)] <- NA
  
  polys <- vector(mode = "list", length = length(tiles))
  for (i in seq(along = polys)) {
    pcrds <- cbind(tiles[[i]]$x, tiles[[i]]$y)
    pcrds <- rbind(pcrds, pcrds[1,])
    polys[[i]] <- sp::Polygons(list(sp::Polygon(pcrds)), ID = as.character(i))
  }
  spoly <- sp::SpatialPolygons(polys)

  # Extract from offset raster
  offset_raster_velox <- velox(offset_raster_non_case_pixels)
  ppm_int_points$weights <- offset_raster_velox$extract(spoly, fun = function(x){sum(x, na.rm = TRUE)})

  # Remove any points with 0 offset
  ppm_int_points <- ppm_int_points[-which(ppm_int_points$weights <= 0),]
  
  # For a temporal model
  # Repeat the ppm integration points 12 times for each month
  ppm_int_points_period <- NULL
  
  for(i in 1:num_periods){
    ppm_int_points$period <- i
    ppm_int_points_period <- rbind(ppm_int_points_period, ppm_int_points)
  }
  return(ppm_int_points_period)
}  

# Deal with case points
# First aggregate any cases occuring in the same pixel in the same month
# # loop through each month and identify any cases in the same pixel
aggregate_points_space_time <- function(points, ppmx, num_periods, date_start_end, reference_raster){

      ppm_cases_points <- ppmx[ppmx$points==1,]
      ppm_cases_points_counts <- ppm_cases_points[FALSE,]
      
      # Define date breaks
      dates <- seq(ymd(date_start_end[1]), ymd(date_start_end[2]), 1)
      date_breaks <- c(levels(cut.Date(dates, num_periods, right=TRUE, include.lowest = TRUE)),
                       date_start_end[2])
      
      for(i in 1:num_periods){
        
        cases_model_period <- as.numeric(cut.Date(ymd(points$date), ymd(date_breaks)))
        cases_period <- ppm_cases_points[cases_model_period==i,]
        cases_period$period <- i
        
        if(nrow(cases_period)>0){
          
          # calculate which cell each case is in
          cases_period$case_pixel <- raster::cellFromXY(reference_raster,
                                                       cbind(cases_period$x, cases_period$y))
          
          # Aggregate number of cases by cell
          cell_counts <- raster::aggregate(cases_period$case_pixel,
                                           by = list(cases_period$case_pixel), length)
          
          # create aggregated ppm data frame for aggregated case counts
          cases_period_trimmed <- cases_period[match(cell_counts$Group.1, cases_period$case_pixel),]
          
          # Aggregate case coordinates to be the centroid of the pixel
          cases_period_trimmed[,c("x","y")] <- sp::coordinates(reference_raster)[cases_period_trimmed$case_pixel,]
          
          # change number of points to be aggregate number
          cases_period_trimmed$points <- cell_counts$x
          
          # take the columns you need
          cases_period_trimmed<- cases_period_trimmed[, 1:5]
          #names(cases_period_trimmed) <- names(ppm_cases_points)
          
          # bind to complete the loop
          ppm_cases_points_counts <- rbind(ppm_cases_points_counts, cases_period_trimmed)
        }
      }
      return(ppm_cases_points_counts)
}
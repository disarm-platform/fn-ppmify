library(downloader)
library(sf)

function(params) {
  # TODO: Write when we have a specific need
  # check if any params are strings that start with 'http' (any case)
  # tryCatch retrieve that file, 
  #   stop() if problems, 
  #   otherwise, write to temp disk, replace parameter with temp filename

  # Get points if URL used
  if(substr(params$points, 1, 4)=="http"){
    params$points <- st_read(params$points)
  }else{
    params$points <- st_read(as.json(params$points), quiet = TRUE)
  }
  
  # Download offset
  if(!is.null(params$offset)){
    temp_file <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".tif")
  
  download(params$offset,
           destfile = temp_file)
  params$offset <- raster(temp_file)
  }
  
  # Download any covariates
  if(!is.null(params$covariates)){
    temp_file <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".tif")
    
    download(params$covariates,
             destfile = temp_file)
    params$covariates <- raster(covariates)
  }
  
  return(params)
}

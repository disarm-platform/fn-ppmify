
function(params) {

 if(!is.null(params$covariates)){
   stop("Sorry, haven't implemented ability to pass in custom covariates yet..")
 }
  
  if(is.null(params$resolution)){
    params$resolution <- 1
  }
  
  return(params)
}
library(mgcv)
library(jsonlite)
library(httr)
library(geojsonio)

# Generate some points
input_data_list <- fromJSON("~/Documents/Work/MEI/DiSARM/GitRepos/fn-ppmify/fn-ppmify/test_req.json")
input_data_list$prediction_frame=TRUE

# Call model
response <-
  httr::POST(
    url = "https://faas.srv.disarm.io/function/fn-ppmify",
    body = as.json(input_data_list),
    content_type_json(),
    timeout(600)
  )

# Get contents of the response
response_content <- content(response)

result <- fromJSON(as.json(response_content$result))
ppm_df <- result$ppm_df
ppm_df_pred <- result$ppm_df_pred

ppm_df <- ppm_df[-which(ppm_df$exposure==0),]
system.time(test_gam <- bam(outcome ~ s(x, y, period, bs="gp") + s(elev_m) + s(dist_to_water_m) +
                  s(bioclim1), 
                offset = log(ppm_df$exposure), 
                weights = ppm_df$regression_weights, 
                data =ppm_df, 
                family="poisson"))

system.time(test_gam <- gam(outcome ~ s(x, y, period, bs="gp") + s(elev_m) + s(dist_to_water_m) +
                              s(bioclim1) + s(bioclim4) + s(bioclim12) + s(bioclim15), 
                            offset = log(ppm_df$weights), 
                            weights = ppm_df$regression_weights, 
                            data =ppm_df, 
                            family="poisson"))

test_gbm <- gbm(outcome ~ offset(log(ppm_df$weights)) + period + elev_m + dist_to_water_m +
                  bioclim1 + bioclim4 + bioclim12 + bioclim15, 
                weights = ppm_df$regression_weights, 
                data = ppm_df, 
                cv.folds = 5,
                distribution="poisson")         

# Predict across offset raster
# Set period
ppm_df_pred$period <- 3
prediction <- exp(predict(test_gam, newdata=ppm_df_pred) + log(ppm_df_pred$exposure))
sum(prediction)
pred_raster <- raster(input_data_list$prediction_exposure)
pred_raster[!is.na(pred_raster[])] <- prediction / pred_raster[!is.na(pred_raster[])]
plot(pred_raster)

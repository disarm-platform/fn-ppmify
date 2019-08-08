# fn-ppmify

Given a set of points in space/time, this function generates data frames necessary to fit and predict from a point process model. All covariates, and offset raster if provided, will be resampled to the same extent using the resolution provided by the user.

## Parameters

A JSON object containing:
- `points` - {GeoJSON or URL to GeoJSON} Required. Points representing the outcome of interest with the following properties
  - `date` - {String}. Date associated with the point in yyyy-mm-dd format. If `null`, the point will be removed. 
- `layer_name` - {Array}. Optional. Names of the bioclimatic/environmental layers to use as covariates. Currently only uses static covariates. See [here under 'Layer names'](https://github.com/disarm-platform/fn-covariate-extractor/blob/master/SPECS.md) for a list of options. If none provided, spatial only model is assumed. 
- `covariates`. {Base64 encoded raster of covariates or URL to valid `.tif`}. Optional additional covariate layer(s). If multiple layers, should be a single .tif file of the raster stack. CURRENTLY DOESN'T WORK.
- `exposure` - {Base64 encoded raster of exposure (to be used as offset) or URL to valid `.tif`}. Required. Raster representing the population over which points arose. Currently only accepts a single raster which is used across all time periods.  
- `resolution` - {Integer}. Resolution in km2 of to resample covariates and offset to (>= 1km2). Defaults to 1. 
- `date_start_end` - {Array}. Required. Array of 2 values representing the start and end times over which points were observed in yyyy-mm-dd format. 
- `num_periods` - {Integer}. Number of time periods over which to aggregate points, where `1` considers all points in a single time period (equivalent to assuming a spatial only model). Defaults to `1`. 
- `density` - {integer}. Required. Density of quadrature points to generate (points / square km)
- `prediction_frame` - {Boolean}. Do you want to also return a data frame required for prediction (i.e. raster cells)? Defaults to FALSE.
- `prediction_exposure` - {Base64 encoded raster of exposure to be used for prediction or URL to valid `.tif`}. Optional population raster to use for prediction. This may be different to `exposure` if `points` arose from a different population to that you wish to predict to. Automatically resampled to the same resolution as `exposure`. Defaults to `exposure`. 
 

## Constraints



## Response

A JSON object 'ppm_df' containing the following fields:
- `x`. Longitude in decimal degrees
- `y`. Latitude in decimal degrees
- `exposure`. Populations for that point in space and time to be used as offset (when logged). 
- `period`. A number 1 through number of layers as determined by `date_start_end` and `aggregation_period`.
- `outcome`. {integer} Whether the point is an observation (1) or a quadrature point (0). 
- `regression_weights`. {integer} Number of `outcomes` per space-time cell, to be used as a regression weight


Note that other values of layers specified in `layer_name` will appear as additional fields.

If `prediction_frame == `TRUE` a nested JSON with 'ppm_df` and 'ppm_df_pred', a similarly structured JSON object of prediction points (without `outcome` field), will be returned.  Note that `ppm_df_pred` does not include `period`.
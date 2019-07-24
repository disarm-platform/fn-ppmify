# fn-ppmify

Given a set of points in space/time, this function generates data frames necessary to fit and predict from a point process model. All covariates, and offset raster if provided, will be resampled to the same extent using the resolution provided by the user.

## Parameters

A JSON object containing:
- `points` - {GeoJSON or URL to GeoJSON} Required. Points representing the outcome of interest with the following properties
  - `date` - {String}. Optional. Date associated with the point in yyyy-mm-dd format. If `null`, the point will be removed. 
- `layer_name` - {Array}. Optional. Names of the bioclimatic/environmental layers to use as covariates. Currently only uses static covariates. See [here under 'Layer names'](https://github.com/disarm-platform/fn-covariate-extractor/blob/master/SPECS.md) for a list of options. If none provided, spatial only model is assumed. 
- `covariates`. {Base64 encoded raster of offset or URL to valid `.tif`}. Optional additional covariate layer(s). If multiple layers, should be a single .tif file of the raster stack. CURRENTLY DOESN'T WORK.
- `offset` - {Base64 encoded raster of offset or URL to valid `.tif`}. Optional. Raster representing the (population) offset and area over which points arose. Currently only accepts a single offset which is used across all time periods. If not provided, `offset` proportional to area will be returned. 
- `resolution` - {Integer}. Resolution in km2 of to resample covariates and offset to (>= 1km2). Defaults to 1. 
- `boundary` - {GeoJSON or URL to GeoJSON}. Boundary defining area over which points arose. Only required if `offset` not provided.
- `date_start_end` - {Array}. Required. Array of 2 values representing the start and end times over which points were observed in yyyy-mm-dd format. 
- `num_periods` - {Integer}. Number of time periods over which to aggregate points, where `1` considers all points in a single time period (equivalent to assuming a spatial only model). Defaults to `1`. 
- `density` - {integer}. Required. Density of quadrature points to generate (points / square km)
- `prediction_frame` - {Boolean}. Do you want to also return a data frame required for prediction (i.e. raster cells)? Defaults to FALSE.

 

## Constraints



## Response

A JSON object 'model_frame' containing the following fields:
- `points`. {integer} Whether the point is an observation (1) or a quadrature point (0). 
- `lng`. Longitude in decimal degrees
- `lat`. Latitude in decimal degrees
- `offset`. Population offset for that point in space and time. 
- `period`. A number 1 through number of layers as determined by `date_start_end` and `aggregation_period`.

Note that other values of layers specified in `layer_name` and/or `covariates` will appear as additional fields.

If `prediction_frame == TRUE` a nested JSON with 'model_frame` and 'prediction_frame' a similarly structured JSON object of prediction points (without `points` field) will be returned.  
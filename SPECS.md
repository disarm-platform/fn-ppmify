# fn-ppmify

Given a set of points in space/time, this function generates data frames necessary to fit and predict from a point process model 

## Parameters

A JSON object containing:
- `points` - {GeoJSON or URL to GeoJSON} Required. Points representing the outcome of interest with the following properties
  - `date` - {string}. Date associated with the point in dd-mm-yyyy format. If `null`, the point will be removed, unless all points have `null` in which case a data frame to fit spatial only model is assumed. 
- `layer_name` - {array}. Names of the bioclimatic/environmental layers to use as covariates. Currently only uses static covariates. See [here under 'Layer names'](https://github.com/disarm-platform/fn-covariate-extractor/blob/master/SPECS.md) for a list of options. 
- `offset` - {Base64 encoded raster of offset or URL to valid `.tif`}. Raster representing the (population) offset. Currently only accepts a single offset which is used across all time periods.
- `date_start_end` - {array}. Array of 2 values representing the start and end times over which points were observed in dd-mm-yyyy format. 
- `aggregation_period` - {string}. Time periods over which to aggregate points. One of `day`, `week`, `month`, `year` or `whole` where `whole` considers all points in a single time period (equivalent to assuming a spatial only model). Any time periods that are not complete are dropped - i.e. if the start date is mid month and `period` is month, observations from that month will be dropped.
- `density` - {integer}. Density of quadrature points to generate (points / square km)
- `boundary` - {GeoJSON or URL to GeoJSON}. Required. Polygon representing the area over which points are observed.
- `prediction_frame` - {Boolean}. Do you want to also return a data frame required for prediction (i.e. raster cells)?
- `prediction_resolution` - {Integer}. Resolution in km2 of prediction data frame. Ignored if `prediction_frame == FALSE`
 

## Constraints



## Response

A JSON object 'model_frame' containing the following fields:
- `points`. {integer} Whether the point is an observation (1) or a quadrature point (0). 
- `lng`. Longitude in decimal degrees
- `lat`. Latitude in decimal degrees
- `offset`. Population offset for that point in space and time. 
- `period`. A number 1 through number of layers as determined by `date_start_end` and `aggregation_period`.

Note that other values of layers specified in `layer_name` will appear as additional fields.

If `prediction_frame == TRUE` a nested JSON with 'model_frame` and 'prediction_frame' a similarly structured JSON object of prediction points (without `points` field) will be returned.  
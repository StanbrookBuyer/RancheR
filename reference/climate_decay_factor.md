# Climate scaling factor for dung decay

Computes the multiplier applied to a reference decay rate to adjust it
for a location's climate, combining a Q10 temperature response with a
saturating moisture response. The factor equals 1 at the reference
climate.

## Usage

``` r
climate_decay_factor(
  temp_C,
  precip_mm,
  q10 = 2,
  precip_half_sat = rancher_constants$ref_precip_warmq_mm,
  ref_temp_C = rancher_constants$ref_temp_warmq_C,
  ref_precip_mm = rancher_constants$ref_precip_warmq_mm
)
```

## Arguments

- temp_C:

  Mean temperature of the warmest quarter at the target location (deg C;
  WorldClim BIO10).

- precip_mm:

  Precipitation of the warmest quarter at the target location (mm;
  WorldClim BIO18).

- q10:

  Temperature sensitivity: the factor by which decay changes per 10
  deg C. Defaults to 2.0, a typical value for biological decomposition.

- precip_half_sat:

  Half-saturation constant for the moisture response (mm). Larger values
  make decay less sensitive to rainfall. Defaults to the reference
  site's warmest-quarter precipitation.

- ref_temp_C, ref_precip_mm:

  Reference-site climate the factor is normalised to. Defaults to the
  calibration values in
  [rancher_constants](https://StanbrookBuyer.github.io/RancheR/reference/rancher_constants.md).

## Value

A list with `temp_factor`, `moist_factor`, and their product
`climate_factor`.

## Examples

``` r
# Reference climate -> factor of 1
climate_decay_factor(27.31, 522)
#> $temp_factor
#> [1] 1
#> 
#> $moist_factor
#> [1] 1
#> 
#> $climate_factor
#> [1] 1
#> 
# Warmer, wetter -> faster decay
climate_decay_factor(30, 700)
#> $temp_factor
#> [1] 1.204972
#> 
#> $moist_factor
#> [1] 1.145663
#> 
#> $climate_factor
#> [1] 1.380492
#> 
```

# Estimate local dung decay rates from a location's climate

Estimates scenario-specific dung decay rates (g/day) at any location by
scaling the reference Central Florida rates by the local climate, using
a Q10 temperature response and a saturating moisture response (see
[`climate_decay_factor()`](https://StanbrookBuyer.github.io/RancheR/reference/climate_decay_factor.md)).
Climate is taken from WorldClim warmest-quarter bioclim variables,
matching the summer window in which the reference rates were measured.

## Usage

``` r
estimate_local_decay(
  lat,
  lon,
  q10 = 2,
  precip_half_sat = rancher_constants$ref_precip_warmq_mm,
  climate = NULL,
  res = c("10", "5", "2.5"),
  path = NULL,
  quiet = FALSE
)
```

## Arguments

- lat, lon:

  Latitude and longitude in decimal degrees (WGS84).

- q10, precip_half_sat:

  Passed to
  [`climate_decay_factor()`](https://StanbrookBuyer.github.io/RancheR/reference/climate_decay_factor.md).

- climate:

  Optional named numeric vector with `temp_warmq_C` and
  `precip_warmq_mm` to use instead of downloading (bypasses terra).

- res:

  WorldClim spatial resolution in arc-minutes: `"10"` (default, ~18 km,
  smallest download), `"5"`, or `"2.5"` (~4.6 km, finer but larger).

- path:

  Directory to cache downloaded layers. Defaults to a per-user cache
  directory.

- quiet:

  If `TRUE`, suppress the download progress message.

## Value

A list with:

- location:

  Named vector of `lat`, `lon`.

- climate:

  Warmest-quarter temperature (deg C) and precipitation (mm) used.

- reference_climate:

  The reference-site climate the scaling is anchored to.

- temp_factor, moist_factor, climate_factor:

  Scaling components.

- decay_rates:

  Named vector of estimated decay rates (g/day) for the three scenarios
  at this location.

## Details

The same climate factor is applied to all three scenarios: it adjusts
the abiotic decomposition backdrop that beetle activity adds to. Supply
your own `climate` to avoid any download (useful offline or for
testing).

To feed the result into the economic model, pass a scaled rate as the
`decay_override` of
[`calc_dung_beetle_benefit()`](https://StanbrookBuyer.github.io/RancheR/reference/calc_dung_beetle_benefit.md).

## Examples

``` r
# Offline: supply climate directly (a cooler, wetter site)
estimate_local_decay(
  lat = 44.0, lon = -89.5,
  climate = c(temp_warmq_C = 21, precip_warmq_mm = 300)
)
#> $location
#>   lat   lon 
#>  44.0 -89.5 
#> 
#> $climate
#>    temp_warmq_C precip_warmq_mm 
#>              21             300 
#> 
#> $reference_climate
#>    temp_warmq_C precip_warmq_mm 
#>           27.31          522.00 
#> 
#> $temp_factor
#> [1] 0.6457287
#> 
#> $moist_factor
#> [1] 0.729927
#> 
#> $climate_factor
#> [1] 0.4713348
#> 
#> $decay_rates
#>     No beetles (low decay rate)  Managed (low beetle abundance) 
#>                        1.767505                        3.407751 
#> Natural (high beetle abundance) 
#>                        5.057422 
#> 
if (FALSE) { # \dontrun{
# Online: look up climate automatically (needs terra + internet)
est <- estimate_local_decay(lat = 31.5, lon = -97.1)
calc_dung_beetle_benefit(
  num_cattle     = 200,
  scenario       = "Managed (low beetle abundance)",
  decay_override = est$decay_rates[["Managed (low beetle abundance)"]]
)
} # }
```

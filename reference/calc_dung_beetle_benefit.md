# Estimate the annual economic benefit of dung beetles to a ranch

Estimates the annual economic value that dung beetles provide to a
cattle operation by reducing the area of pasture fouled by dung pats,
which frees up grazing area and effectively increases carrying capacity.
Figures are based on empirical pat-decay data from Central Florida
pasture research.

## Usage

``` r
calc_dung_beetle_benefit(
  num_cattle,
  scenario = "Managed (low beetle abundance)",
  pat_weight_g = rancher_constants$initial_pat_g,
  decay_override = NA_real_,
  income_per_cow = rancher_constants$income_per_cow,
  acre_per_cow = rancher_constants$acre_per_cow,
  climate_factor = 1
)
```

## Arguments

- num_cattle:

  Number of cattle on the operation.

- scenario:

  Dung beetle abundance scenario; one of
  [`dung_scenarios()`](https://StanbrookBuyer.github.io/RancheR/reference/dung_scenarios.md).
  Defaults to `"Managed (low beetle abundance)"`.

- pat_weight_g:

  Initial dung pat weight in grams.

- decay_override:

  Optional custom decay rate (g/day). Leave as `NA` to use the scenario
  default. When supplied, fouled-area is scaled from the no-beetle
  baseline rather than read from the empirical table.

- income_per_cow:

  Ranch-level income per cow (\$/yr).

- acre_per_cow:

  Acres required per cow per year.

- climate_factor:

  Climate scaling factor for the location, as returned by
  [`estimate_local_decay()`](https://StanbrookBuyer.github.io/RancheR/reference/estimate_local_decay.md)
  (`$climate_factor`). Slower decay (a factor below 1, e.g. cooler/drier
  sites) means both the no-beetle baseline and the beetle scenarios foul
  pasture for proportionally longer, so the avoided fouling - and
  therefore the dollar benefit - scales by `1 / climate_factor`.
  Defaults to `1` (the Central Florida reference climate). Use this,
  with the empirical `scenario` path, to get a location-adjusted
  benefit; it composes correctly with the climate model whereas
  `decay_override` does not.

## Value

A list with components:

- annual_value:

  Estimated annual economic benefit (\$).

- additional_cows:

  Equivalent additional cows the freed pasture supports.

- days_to_decay:

  Time for a single pat to decay (days).

- decay_rate:

  Decay rate used (g/day).

- fouled_used:

  Fouled GAU per cow per year used in the calculation.

- avoided_gau_per_cow:

  GAU per cow per year of fouling avoided vs. the no-beetle baseline
  (after any climate scaling).

- climate_factor:

  The climate scaling factor applied.

## Examples

``` r
calc_dung_beetle_benefit(num_cattle = 100)
#> $annual_value
#> [1] 454.8576
#> 
#> $additional_cows
#> [1] 0.5601695
#> 
#> $days_to_decay
#> [1] 112.61
#> 
#> $decay_rate
#> [1] 7.23
#> 
#> $fouled_used
#> [1] 31820
#> 
#> $avoided_gau_per_cow
#> [1] 20272
#> 
#> $climate_factor
#> [1] 1
#> 
calc_dung_beetle_benefit(
  num_cattle = 250,
  scenario   = "Natural (high beetle abundance)"
)
#> $annual_value
#> [1] 1684.344
#> 
#> $additional_cows
#> [1] 2.074316
#> 
#> $days_to_decay
#> [1] 75.87791
#> 
#> $decay_rate
#> [1] 10.73
#> 
#> $fouled_used
#> [1] 22065
#> 
#> $avoided_gau_per_cow
#> [1] 30027
#> 
#> $climate_factor
#> [1] 1
#> 
# Location-adjusted: feed in a climate factor from estimate_local_decay()
calc_dung_beetle_benefit(num_cattle = 200, climate_factor = 0.44)
#> $annual_value
#> [1] 2067.535
#> 
#> $additional_cows
#> [1] 2.546225
#> 
#> $days_to_decay
#> [1] 112.61
#> 
#> $decay_rate
#> [1] 7.23
#> 
#> $fouled_used
#> [1] 31820
#> 
#> $avoided_gau_per_cow
#> [1] 46072.73
#> 
#> $climate_factor
#> [1] 0.44
#> 
```

# Paper-derived constants for the dung beetle valuation model

Default parameters and empirical values from the Central Florida pasture
research underlying this package. Exposed so users can inspect or reuse
them.

## Usage

``` r
rancher_constants
```

## Format

A named list with elements:

- initial_pat_g:

  Initial dung pat weight (grams).

- decay_no_beetles:

  Pat decay rate with no beetles (g/day).

- decay_managed:

  Pat decay rate, managed / low beetle abundance (g/day).

- decay_natural:

  Pat decay rate, natural / high beetle abundance (g/day).

- income_per_cow:

  Ranch-level income per cow (\$/yr).

- acre_per_cow:

  Acres required per cow per year.

- gau_per_acre:

  Grazing-area units per acre (m^2 per acre).

- fouled_gau_per_cow_year:

  Named vector of empirically fouled GAU per cow per year, by scenario.

- ref_lat, ref_lon:

  Latitude/longitude of the Central Florida site where the decay rates
  were measured.

- ref_temp_warmq_C:

  WorldClim BIO10 (mean temperature of the warmest quarter, deg C) at
  the reference site; the temperature anchor for climate scaling.

- ref_precip_warmq_mm:

  WorldClim BIO18 (precipitation of the warmest quarter, mm) at the
  reference site; the moisture anchor for climate scaling.

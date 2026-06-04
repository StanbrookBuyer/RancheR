# RancheR

Calculation functions for estimating the annual economic benefit of dung
beetles to Florida cattle ranchers. These are the same calculations that
power the RancheR Shiny app, packaged so others can use them directly in
R.

Based on empirical pat-decay data from Central Florida pasture research
(Stanbrook-Buyer, Bhat & King, 2024).

## Install

``` r

# install.packages("devtools")
devtools::install_github("StanbrookBuyer/RancheR")
# or, from a local copy:
devtools::install("path/to/RancheR")
```

## Use

``` r

library(RancheR)

# Available abundance scenarios
dung_scenarios()

# Estimate benefit for a 100-head operation under managed beetle abundance
res <- calc_dung_beetle_benefit(
  num_cattle = 100,
  scenario   = "Managed (low beetle abundance)"
)

res$annual_value     # estimated annual benefit ($)
res$additional_cows  # equivalent extra cows the freed pasture supports

# Override any parameter
calc_dung_beetle_benefit(
  num_cattle     = 250,
  scenario       = "Natural (high beetle abundance)",
  pat_weight_g   = 800,
  income_per_cow = 900,
  acre_per_cow   = 2.5
)

# Inspect the underlying constants
rancher_constants
```

## Citation

If you use `RancheR`, please cite the underlying paper (or run
`citation("RancheR")`):

> Stanbrook-Buyer, R., Bhat, M., & King, J. R. (2024). Economic value of
> dung removal by dung beetles in US sub-tropical pastures. *Basic and
> Applied Ecology*, *79*, 123–130.
> <https://doi.org/10.1016/j.baae.2024.07.001>

## License

MIT

# RancheR

[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.20558680-1682D4?logo=zenodo&logoColor=white)](https://doi.org/10.5281/zenodo.20558680)

Calculation functions for estimating the annual economic benefit of dung
beetles to Florida cattle ranchers. These are the same calculations that
power the [RancheR Shiny app](https://rstanbrook-rancher.hf.space/),
packaged so others can use them directly in R.

The package does two things:

- **Economic benefit** —
  [`calc_dung_beetle_benefit()`](https://StanbrookBuyer.github.io/RancheR/reference/calc_dung_beetle_benefit.md)
  turns dung beetle activity into an annual dollar value for a cattle
  operation.
- **Climate-adjusted decay** —
  [`estimate_local_decay()`](https://StanbrookBuyer.github.io/RancheR/reference/estimate_local_decay.md)
  rescales the reference decay rates for any location’s climate
  (WorldClim warmest-quarter temperature and precipitation), so the
  economics reflect *your* conditions, not just Central Florida.

Based on empirical pat-decay data from Central Florida pasture research
(Stanbrook-Buyer, Bhat & King, 2024).

## Install

``` r

# install.packages("devtools")
devtools::install_github("StanbrookBuyer/RancheR")
# or, from a local copy:
devtools::install("path/to/RancheR")
```

### Docker

A ready-to-run image (R + RancheR + `terra`/GDAL, so the climate
functions work) is published to the GitHub Container Registry on each
release:

``` bash
docker pull ghcr.io/stanbrookbuyer/rancher:latest

# interactive R session with RancheR preloaded
docker run --rm -it ghcr.io/stanbrookbuyer/rancher:latest

# a one-off calculation
docker run --rm ghcr.io/stanbrookbuyer/rancher:latest Rscript -e \
  'RancheR::calc_dung_beetle_benefit(100, "Managed (low beetle abundance)")$annual_value'
```

Or build it yourself from the repo with `docker build -t rancher .`.

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

## Climate-adjusted decay

The reference decay rates were measured at a single Central Florida site
in summer. To estimate decay elsewhere,
[`estimate_local_decay()`](https://StanbrookBuyer.github.io/RancheR/reference/estimate_local_decay.md)
rescales them by how a location’s climate differs from that reference,
using a Q10 temperature response and a saturating moisture response
(calibrated so the reference site reproduces the measured rates
exactly).

``` r

# Look up climate automatically from WorldClim (needs the `terra` package
# and an internet connection on first use):
est <- estimate_local_decay(lat = 31.5, lon = -97.1)   # central Texas
est$decay_rates        # scenario decay rates (g/day) for this location

# ...or supply warmest-quarter climate directly (no download, works offline):
est <- estimate_local_decay(
  lat = 44.0, lon = -89.5,                              # central Wisconsin
  climate = c(temp_warmq_C = 20.3, precip_warmq_mm = 290)
)
est$decay_rates        # climate-adjusted decay rates (g/day)

# Feed the climate factor into the economic model. Where decay is slower
# (cooler/drier), beetles avert more fouled-pasture-time, so the benefit is
# higher than at the Florida reference:
calc_dung_beetle_benefit(
  num_cattle     = 200,
  scenario       = "Managed (low beetle abundance)",
  climate_factor = est$climate_factor
)$annual_value
```

See the [Get Started
vignette](https://StanbrookBuyer.github.io/RancheR/articles/RancheR.html)
for the full climate model, including maps and the
temperature/precipitation response surface.

## Citation

If you use `RancheR`, please cite package from the underlying paper:

> Stanbrook-Buyer, R., Bhat, M., & King, J. R. (2024). Economic value of
> dung removal by dung beetles in US sub-tropical pastures. *Basic and
> Applied Ecology*, *79*, 123–130.
> <https://doi.org/10.1016/j.baae.2024.07.001>

### 

> Stanbrook-Buyer, R., Bhat, M., & King, J. R. (2026). RancheR: Economic
> Benefit of Dung Beetles to Florida Ranchers (Version 0.1.0) \[R
> package\]. Zenodo. <https://doi.org/10.5281/zenodo.20558680>

## License

MIT

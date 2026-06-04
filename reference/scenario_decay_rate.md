# Decay rate (g/day) for a scenario

Returns the scenario's empirical pat decay rate, unless a positive
`decay_override` is supplied (in which case the override is used).

## Usage

``` r
scenario_decay_rate(scenario, decay_override = NA_real_)
```

## Arguments

- scenario:

  One of
  [`dung_scenarios()`](https://StanbrookBuyer.github.io/RancheR/reference/dung_scenarios.md).

- decay_override:

  Optional custom decay rate (g/day). Use `NA` (default) to fall back to
  the scenario value.

## Value

Decay rate in grams per day.

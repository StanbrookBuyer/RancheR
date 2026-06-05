#' Paper-derived constants for the dung beetle valuation model
#'
#' Default parameters and empirical values from the Central Florida pasture
#' research underlying this package. Exposed so users can inspect or reuse them.
#'
#' @format A named list with elements:
#' \describe{
#'   \item{initial_pat_g}{Initial dung pat weight (grams).}
#'   \item{decay_no_beetles}{Pat decay rate with no beetles (g/day).}
#'   \item{decay_managed}{Pat decay rate, managed / low beetle abundance (g/day).}
#'   \item{decay_natural}{Pat decay rate, natural / high beetle abundance (g/day).}
#'   \item{income_per_cow}{Ranch-level income per cow ($/yr).}
#'   \item{acre_per_cow}{Acres required per cow per year.}
#'   \item{gau_per_acre}{Grazing-area units per acre (m^2 per acre).}
#'   \item{fouled_gau_per_cow_year}{Named vector of empirically fouled GAU per
#'     cow per year, by scenario.}
#'   \item{ref_lat, ref_lon}{Latitude/longitude of the Central Florida site
#'     where the decay rates were measured.}
#'   \item{ref_temp_warmq_C}{WorldClim BIO10 (mean temperature of the warmest
#'     quarter, deg C) at the reference site; the temperature anchor for
#'     climate scaling.}
#'   \item{ref_precip_warmq_mm}{WorldClim BIO18 (precipitation of the warmest
#'     quarter, mm) at the reference site; the moisture anchor for climate
#'     scaling.}
#' }
#' @export
rancher_constants <- list(
  initial_pat_g    = 814.17,
  decay_no_beetles = 3.75,
  decay_managed    = 7.23,
  decay_natural    = 10.73,
  income_per_cow   = 812,
  acre_per_cow     = 2.45,
  gau_per_acre     = 4046.86,
  fouled_gau_per_cow_year = c(
    "No beetles (low decay rate)"     = 52092,
    "Managed (low beetle abundance)"  = 31820,
    "Natural (high beetle abundance)" = 22065
  ),
  # Reference site where decay rates were measured (Central Florida, summer)
  ref_lat             = 27.130136781732656,
  ref_lon             = -81.19789888464314,
  ref_temp_warmq_C    = 27.31,   # WorldClim 2.1 BIO10 at the reference point
  ref_precip_warmq_mm = 522      # WorldClim 2.1 BIO18 at the reference point
)

#' The three dung beetle abundance scenarios
#'
#' @return Character vector of the valid `scenario` labels.
#' @export
dung_scenarios <- function() {
  names(rancher_constants$fouled_gau_per_cow_year)
}

#' Decay rate (g/day) for a scenario
#'
#' Returns the scenario's empirical pat decay rate, unless a positive
#' `decay_override` is supplied (in which case the override is used).
#'
#' @param scenario One of [dung_scenarios()].
#' @param decay_override Optional custom decay rate (g/day). Use `NA` (default)
#'   to fall back to the scenario value.
#' @return Decay rate in grams per day.
#' @export
scenario_decay_rate <- function(scenario, decay_override = NA_real_) {
  if (!is.na(decay_override) && decay_override > 0) {
    return(decay_override)
  }
  switch(
    scenario,
    "No beetles (low decay rate)"     = rancher_constants$decay_no_beetles,
    "Managed (low beetle abundance)"  = rancher_constants$decay_managed,
    "Natural (high beetle abundance)" = rancher_constants$decay_natural,
    rancher_constants$decay_managed
  )
}

#' Estimate the annual economic benefit of dung beetles to a ranch
#'
#' Estimates the annual economic value that dung beetles provide to a cattle
#' operation by reducing the area of pasture fouled by dung pats, which frees up
#' grazing area and effectively increases carrying capacity. Figures are based
#' on empirical pat-decay data from Central Florida pasture research.
#'
#' @param num_cattle Number of cattle on the operation.
#' @param scenario Dung beetle abundance scenario; one of [dung_scenarios()].
#'   Defaults to `"Managed (low beetle abundance)"`.
#' @param pat_weight_g Initial dung pat weight in grams.
#' @param decay_override Optional custom decay rate (g/day). Leave as `NA` to use
#'   the scenario default. When supplied, fouled-area is scaled from the
#'   no-beetle baseline rather than read from the empirical table.
#' @param income_per_cow Ranch-level income per cow ($/yr).
#' @param acre_per_cow Acres required per cow per year.
#' @param climate_factor Climate scaling factor for the location, as returned by
#'   [estimate_local_decay()] (`$climate_factor`). Slower decay (a factor below
#'   1, e.g. cooler/drier sites) means both the no-beetle baseline and the
#'   beetle scenarios foul pasture for proportionally longer, so the avoided
#'   fouling - and therefore the dollar benefit - scales by `1 / climate_factor`.
#'   Defaults to `1` (the Central Florida reference climate). Use this, with the
#'   empirical `scenario` path, to get a location-adjusted benefit; it composes
#'   correctly with the climate model whereas `decay_override` does not.
#'
#' @return A list with components:
#'   \describe{
#'     \item{annual_value}{Estimated annual economic benefit ($).}
#'     \item{additional_cows}{Equivalent additional cows the freed pasture supports.}
#'     \item{days_to_decay}{Time for a single pat to decay (days).}
#'     \item{decay_rate}{Decay rate used (g/day).}
#'     \item{fouled_used}{Fouled GAU per cow per year used in the calculation.}
#'     \item{avoided_gau_per_cow}{GAU per cow per year of fouling avoided vs. the no-beetle baseline (after any climate scaling).}
#'     \item{climate_factor}{The climate scaling factor applied.}
#'   }
#' @examples
#' calc_dung_beetle_benefit(num_cattle = 100)
#' calc_dung_beetle_benefit(
#'   num_cattle = 250,
#'   scenario   = "Natural (high beetle abundance)"
#' )
#' # Location-adjusted: feed in a climate factor from estimate_local_decay()
#' calc_dung_beetle_benefit(num_cattle = 200, climate_factor = 0.44)
#' @export
calc_dung_beetle_benefit <- function(
  num_cattle,
  scenario       = "Managed (low beetle abundance)",
  pat_weight_g   = rancher_constants$initial_pat_g,
  decay_override = NA_real_,
  income_per_cow = rancher_constants$income_per_cow,
  acre_per_cow   = rancher_constants$acre_per_cow,
  climate_factor = 1
) {
  if (!is.numeric(climate_factor) || length(climate_factor) != 1 ||
        is.na(climate_factor) || climate_factor <= 0) {
    stop("`climate_factor` must be a single positive number.", call. = FALSE)
  }
  decay_g_day <- scenario_decay_rate(scenario, decay_override)

  # Days for a single pat to fully decay
  days_to_decay <- if (decay_g_day > 0) pat_weight_g / decay_g_day else Inf

  fouled_tbl <- rancher_constants$fouled_gau_per_cow_year
  use_empirical <- scenario %in% names(fouled_tbl) &&
    (is.na(decay_override) || decay_override <= 0)

  if (use_empirical) {
    fouled_used <- unname(fouled_tbl[[scenario]])
  } else {
    # Scale fouled area from the no-beetle baseline by relative decay time
    paper_days_no_beetles <- rancher_constants$initial_pat_g /
      rancher_constants$decay_no_beetles
    approx_no_beetles <- unname(fouled_tbl[["No beetles (low decay rate)"]])
    scaling <- days_to_decay / paper_days_no_beetles
    fouled_used <- approx_no_beetles * scaling
  }

  baseline_fouled <- unname(fouled_tbl[["No beetles (low decay rate)"]])
  # Climate scaling: slower decay (factor < 1) fouls pasture for proportionally
  # longer for BOTH the baseline and the beetle scenario, so the avoided fouling
  # scales by 1 / climate_factor. At the reference climate (factor = 1) this is a
  # no-op and the result matches the Central Florida figures.
  avoided_gau_per_cow <- max(baseline_fouled - fouled_used, 0) / climate_factor

  gau_per_cow_year <- acre_per_cow * rancher_constants$gau_per_acre * 365
  additional_cows  <- (avoided_gau_per_cow * num_cattle) / gau_per_cow_year
  annual_value     <- additional_cows * income_per_cow

  list(
    annual_value        = annual_value,
    additional_cows     = additional_cows,
    days_to_decay       = days_to_decay,
    decay_rate          = decay_g_day,
    fouled_used         = fouled_used,
    avoided_gau_per_cow = avoided_gau_per_cow,
    climate_factor      = climate_factor
  )
}

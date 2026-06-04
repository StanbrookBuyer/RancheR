test_that("climate factor is 1 at the reference climate", {
  f <- climate_decay_factor(
    rancher_constants$ref_temp_warmq_C,
    rancher_constants$ref_precip_warmq_mm
  )
  expect_equal(f$temp_factor, 1)
  expect_equal(f$moist_factor, 1)
  expect_equal(f$climate_factor, 1)
})

test_that("Q10 doubles the temperature factor per +10 C", {
  ref_t <- rancher_constants$ref_temp_warmq_C
  expect_equal(climate_decay_factor(ref_t + 10, 522, q10 = 2)$temp_factor, 2)
  expect_equal(climate_decay_factor(ref_t - 10, 522, q10 = 2)$temp_factor, 0.5)
})

test_that("warmer/wetter increases the factor; cooler/drier decreases it", {
  ref_t <- rancher_constants$ref_temp_warmq_C
  ref_p <- rancher_constants$ref_precip_warmq_mm
  expect_gt(climate_decay_factor(ref_t + 3, ref_p + 100)$climate_factor, 1)
  expect_lt(climate_decay_factor(ref_t - 3, ref_p - 100)$climate_factor, 1)
})

test_that("moisture response saturates (diminishing returns)", {
  ref_p <- rancher_constants$ref_precip_warmq_mm
  ref_t <- rancher_constants$ref_temp_warmq_C
  step1 <- climate_decay_factor(ref_t, ref_p + 100)$moist_factor -
    climate_decay_factor(ref_t, ref_p)$moist_factor
  step2 <- climate_decay_factor(ref_t, ref_p + 200)$moist_factor -
    climate_decay_factor(ref_t, ref_p + 100)$moist_factor
  expect_gt(step1, step2)
})

test_that("estimate_local_decay reproduces measured rates at the reference", {
  est <- estimate_local_decay(
    lat = rancher_constants$ref_lat,
    lon = rancher_constants$ref_lon,
    climate = c(
      temp_warmq_C    = rancher_constants$ref_temp_warmq_C,
      precip_warmq_mm = rancher_constants$ref_precip_warmq_mm
    )
  )
  expect_equal(
    unname(est$decay_rates),
    c(rancher_constants$decay_no_beetles,
      rancher_constants$decay_managed,
      rancher_constants$decay_natural)
  )
  expect_named(est$decay_rates, dung_scenarios())
})

test_that("estimate_local_decay validates the climate argument", {
  expect_error(
    estimate_local_decay(0, 0, climate = c(temp_warmq_C = 25)),
    "named vector"
  )
})

test_that("a cooler, drier site yields lower decay than the reference", {
  est <- estimate_local_decay(
    lat = 44, lon = -89.5,
    climate = c(temp_warmq_C = 20, precip_warmq_mm = 290)
  )
  expect_lt(est$decay_rates[["Managed (low beetle abundance)"]],
            rancher_constants$decay_managed)
})

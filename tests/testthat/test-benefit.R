test_that("scenario decay rates match the paper constants", {
  expect_equal(scenario_decay_rate("No beetles (low decay rate)"), 3.75)
  expect_equal(scenario_decay_rate("Managed (low beetle abundance)"), 7.23)
  expect_equal(scenario_decay_rate("Natural (high beetle abundance)"), 10.73)
})

test_that("decay override takes precedence when positive", {
  expect_equal(scenario_decay_rate("Managed (low beetle abundance)", 5), 5)
  expect_equal(scenario_decay_rate("Managed (low beetle abundance)", NA), 7.23)
  expect_equal(scenario_decay_rate("Managed (low beetle abundance)", 0), 7.23)
})

test_that("no-beetle scenario yields zero avoided fouling and zero value", {
  res <- calc_dung_beetle_benefit(100, "No beetles (low decay rate)")
  expect_equal(res$avoided_gau_per_cow, 0)
  expect_equal(res$annual_value, 0)
})

test_that("more beetles -> more avoided fouling and higher value", {
  managed <- calc_dung_beetle_benefit(100, "Managed (low beetle abundance)")
  natural <- calc_dung_beetle_benefit(100, "Natural (high beetle abundance)")
  expect_gt(natural$avoided_gau_per_cow, managed$avoided_gau_per_cow)
  expect_gt(natural$annual_value, managed$annual_value)
})

test_that("benefit scales linearly with herd size", {
  one  <- calc_dung_beetle_benefit(100, "Natural (high beetle abundance)")
  two  <- calc_dung_beetle_benefit(200, "Natural (high beetle abundance)")
  expect_equal(two$annual_value, 2 * one$annual_value)
})

test_that("dung_scenarios returns the three labels", {
  expect_length(dung_scenarios(), 3)
})

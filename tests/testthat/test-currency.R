test_that("set_currency works", {
  # Input checks
  expect_error(set_currency(1))

  # Test set currency
  set_currency("CHF")
  expect_equal(Sys.getenv("HERE_CURRENCY"), "CHF")

  # Test unset currency
  set_currency()
  expect_equal(Sys.getenv("HERE_CURRENCY"), "")
})

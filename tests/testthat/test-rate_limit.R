test_that("set_rate_limit works", {
  # Input checks
  expect_error(set_rate_limit("not_a_boolean"))

  # Test set and unset API key
  set_rate_limit(TRUE)
  expect_equal(Sys.getenv("HERE_RPS"), "")
  set_rate_limit(FALSE)
  expect_equal(Sys.getenv("HERE_RPS"), "FALSE")
})

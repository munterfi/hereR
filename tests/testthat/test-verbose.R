test_that("set_verbose works", {
  # Input checks
  expect_error(set_verbose("not_a_boolean"))

  # Test set and unset API key
  set_verbose(TRUE)
  expect_equal(Sys.getenv("HERE_VERBOSE"), "TRUE")
  set_verbose(FALSE)
  expect_equal(Sys.getenv("HERE_VERBOSE"), "")
})

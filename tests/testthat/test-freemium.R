test_that("set_freemium works", {
  # Input checks
  expect_error(set_freemium("not_a_boolean"))

  # Test set and unset API key
  set_freemium(TRUE)
  expect_equal(Sys.getenv("HERE_FREEMIUM"), "")
  set_freemium(FALSE)
  expect_equal(Sys.getenv("HERE_FREEMIUM"), "FALSE")
})

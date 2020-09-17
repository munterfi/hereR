test_that("authentication works", {

  # Input checks
  expect_error(set_key(1))

  # Test set and unset API key
  set_key("apiKey")
  expect_equal(Sys.getenv("HERE_API_KEY"), "apiKey")
  unset_key()
  expect_equal(Sys.getenv("HERE_API_KEY"), "")
})

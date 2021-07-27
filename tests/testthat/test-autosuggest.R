test_that("autosuggest works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(autosuggest(c(1, 2, 3)), "'address' must be a 'character' vector.")
  expect_error(autosuggest(c("character", NA)), "'address' contains NAs.")
  expect_error(autosuggest(""), "'address' contains empty strings.")
  expect_error(autosuggest("  "), "'address' contains empty strings.")

  # Test with API response mock
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$autosuggest_response
    },
    suggestion <- autosuggest(address = poi$city),

    # Tests
    expect_s3_class(suggestion, "data.frame", exact = TRUE),
    expect_equal(length(unique(suggestion$id)), length(poi$city))
  )
})

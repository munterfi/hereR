test_that("autocomplete works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Input checks
  expect_error(autocomplete(c(1, 2, 3)), "'addresses' must be a 'character' vector.")
  expect_error(autocomplete(c("character", NA)), "'addresses' contains NAs.")
  expect_error(autocomplete(c("")), "'addresses' contains empty strings.")
  expect_error(autocomplete(c("  ")), "'addresses' contains empty strings.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$autocomplete_response},
    suggestions <- autocomplete(addresses = poi$city),

    # Tests
    expect_is(suggestions,  c("data.table", "data.frame")),
    expect_equal(length(unique(suggestions$id)), length(poi$city))
  )
})

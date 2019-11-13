test_that("geocode works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Input checks
  expect_error(geocode(c(1, 2, 3)), "'addresses' must be a 'character' vector.")
  expect_error(geocode(c("character", NA)), "'addresses' contains NAs.")
  expect_error(geocode(c("")), "'addresses' contains empty strings.")
  expect_error(geocode(c("  ")), "'addresses' contains empty strings.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$geocode_response},
    geocoded <- geocode(addresses = poi$city),

    # Tests
    expect_equal(any(sf::st_geometry_type(geocoded) != "POINT"), FALSE),
    expect_equal(nrow(geocoded), length(poi$city))
  )
})

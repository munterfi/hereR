test_that("geocode works", {
  # Set dummy key
  set_key("dummy_api_key")

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
    expect_s3_class(geocoded, c("sf", "data.frame"), exact = TRUE),
    expect_true(all(sf::st_geometry_type(geocoded) == "POINT")),
    expect_equal(nrow(geocoded), length(poi$city))
  )
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$geocode_response},
    geocoded <- geocode(addresses = poi$city, sf = FALSE),

    # Tests
    expect_s3_class(geocoded, "data.frame", exact = TRUE),
    expect_equal(nrow(geocoded), length(poi$city)),
    expect_type(geocoded[["lat"]], "double"),
    expect_type(geocoded[["lng"]], "double")
  )
})

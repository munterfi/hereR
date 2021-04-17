test_that("reverse_geocode works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  nrows <- 3
  (x <- sf::st_sf(
    id = 1:nrows,
    geometry = sf::st_sfc(lapply(1:nrows, function(x) sf::st_geometrycollection()))
  ))
  expect_error(reverse_geocode(poi = x), "'poi' has empty entries in the geometry column.")
  expect_error(reverse_geocode(poi = c(1, 2, 3)), "'poi' must be an sf object.")
  expect_error(reverse_geocode(poi = c("character", NA)), "'poi' must be an sf object.")
  expect_error(reverse_geocode(poi = poi, results = -100), "'results' must be in the valid range from 1 to 100.")
  expect_error(reverse_geocode(poi = poi, sf = NA), "'sf' must be a 'boolean' value.")
  expect_error(reverse_geocode(poi = poi, results = "-100"), "'results' must be of type 'numeric'.")

  # Test with API response mock: sf
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$reverse_geocode_response
    },
    reverse <- reverse_geocode(poi = poi, results = 3, sf = TRUE),

    # Tests
    expect_s3_class(reverse, c("sf", "data.frame"), exact = TRUE),
    expect_true(all(sf::st_geometry_type(reverse) == "POINT"))
  )

  # Test with API response mock: data.frame
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$reverse_geocode
    },
    reverse <- reverse_geocode(poi = poi, results = 3, sf = FALSE),

    # Tests
    expect_s3_class(reverse, "data.frame", exact = TRUE),
    expect_type(reverse[["lat_position"]], "double"),
    expect_type(reverse[["lng_position"]], "double"),
    expect_type(reverse[["lat_access"]], "double"),
    expect_type(reverse[["lng_access"]], "double")
  )
})

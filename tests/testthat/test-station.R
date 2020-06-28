test_that("station works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(station(poi = c(1, 2, 3)), "'poi' must be an sf object.")
  expect_error(station(poi = poi, results = "not_numeric"))
  expect_error(station(poi = poi, results = -1))
  expect_error(station(poi = poi, radius = "not_numeric"))
  expect_error(station(poi = poi, radius = -1))
  expect_error(weather(poi = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$station_response},
    stations <- station(poi = poi),

    # Tests
    expect_equal(any(sf::st_geometry_type(stations) != "POINT"), FALSE),
    expect_equal(length(unique(stations$id)), nrow(poi))
  )
})

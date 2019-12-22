test_that("weather alerts works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(weather(poi = c(1, 2, 3)), "Invalid input for 'poi'.")
  expect_error(weather(poi = c("character", NA)), "'addresses' contains NAs.")
  expect_error(weather(poi = poi, product = "not_a_product"), "'product' must be 'observation', 'forecast_hourly', 'forecast_astronomy', 'alerts'.")
  expect_error(weather(poi = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$weather_alerts_response},
    weather_alerts <- weather(poi = poi, product = "alerts"),

    # Tests
    expect_equal(any(sf::st_geometry_type(weather_alerts) != "POINT"), FALSE),
    expect_equal(nrow(weather_alerts), nrow(poi))
  )
})

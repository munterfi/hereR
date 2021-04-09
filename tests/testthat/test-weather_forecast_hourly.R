test_that("weather forecast_hourly works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Test with API response mock
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$weather_forecast_hourly_response
    },
    weather_forecast_hourly <- weather(poi = poi, product = "forecast_hourly"),

    # Tests
    expect_equal(any(sf::st_geometry_type(weather_forecast_hourly) != "POINT"), FALSE),
    expect_equal(nrow(weather_forecast_hourly), nrow(poi))
  )
})

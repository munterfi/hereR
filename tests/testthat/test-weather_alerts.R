test_that("weather alerts works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$weather_alerts_response},
    weather_alerts <- weather(poi = poi, product = "alerts"),

    # Tests
    expect_equal(any(sf::st_geometry_type(weather_alerts) != "POINT"), FALSE),
    expect_equal(nrow(weather_alerts), nrow(poi))
  )
})

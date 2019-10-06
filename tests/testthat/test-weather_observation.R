test_that("weather observation works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load API response mock and example
  data(example_geocode)
  data(mock_weather_observation)

  # Test with mocked API response
  with_mock(
    "hereR:::.get_content" = function(url) {mock_weather_observation},
    weather_observation <- weather(poi = example_geocode, product = "observation"),

    # Tests
    expect_equal(any(sf::st_geometry_type(weather_observation) != "POINT"), FALSE),
    expect_equal(nrow(weather_observation), nrow(example_geocode))
  )
})

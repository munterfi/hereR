test_that("weather observation works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$weather_observation_response},
    weather_observation <- weather(poi = poi, product = "observation"),

    # Tests
    expect_equal(any(sf::st_geometry_type(weather_observation) != "POINT"), FALSE),
    expect_equal(nrow(weather_observation), nrow(poi))
  )
})

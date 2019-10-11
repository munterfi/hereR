test_that("traffic incidents works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(aoi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$traffic_incidents_response},
    traffic_incidents <- traffic(aoi = aoi[aoi$code == "LI", ], product = "incidents"),

    # Tests
    expect_equal(class(traffic_incidents), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(traffic_incidents) != "POINT"), FALSE)
  )
})

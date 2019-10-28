test_that("traffic flow works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(aoi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$traffic_flow_response},
    traffic_flow <- traffic(aoi = aoi[aoi$code == "LI", ], product = "flow"),

    # Tests
    expect_equal(class(traffic_flow), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(traffic_flow) != "MULTILINESTRING"), FALSE)
  )
})

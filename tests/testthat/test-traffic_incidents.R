test_that("traffic incidents works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(aoi)

  # Input checks
  expect_error(traffic(aoi = c(1, 2, 3), product = "incidents"), "'polygon' must be an sf object.")
  expect_error(traffic(aoi = NA, product = "incidents"), "'polygon' must be an sf object.")
  expect_error(traffic(aoi = aoi, product = "not_a_product"), "'product' must be 'flow', 'incidents'.")

  # Test URL
  expect_is(traffic(aoi = aoi[aoi$code == "LI", ], product = "incidents", from = Sys.time()-60*60, to = Sys.time(), url_only = TRUE), "character")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$traffic_incidents_response},
    traffic_incidents <- traffic(aoi = aoi[aoi$code == "LI", ], product = "incidents"),

    # Tests
    expect_equal(class(traffic_incidents), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(traffic_incidents) != "POINT"), FALSE)
  )
})

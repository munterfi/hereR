test_that("traffic flow works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(aoi)

  # Input checks
  nrows <- 3
  (x <- sf::st_sf(
    id = 1:nrows,
    geometry = sf::st_sfc(lapply(1:nrows, function(x) sf::st_geometrycollection()))
  ))
  expect_error(traffic(aoi = x, product = "flow"), "'polygon' has empty entries in the geometry column.")
  expect_error(traffic(aoi = c(1, 2, 3), product = "flow"), "'polygon' must be an sf object.")
  expect_error(traffic(aoi = NA, product = "flow"), "'polygon' must be an sf object.")
  expect_error(traffic(aoi = poi, product = "flow"), "'polygon' must be an sf object with geometry type 'POLYGON' or 'MULTIPOLYGON'.")
  expect_error(traffic(aoi = aoi, product = "not_a_product"), "'product' must be 'flow', 'incidents'.")
  expect_error(traffic(aoi = aoi, product = "flow", min_jam_factor = -1), "'min_jam_factor' must be in the valid range from 0 to 10.")
  expect_error(traffic(aoi = aoi, product = "flow", min_jam_factor = "11"), "'min_jam_factor' must be of type 'numeric'.")

  # Test URL
  # Following message should appear: "Note: 'from' and 'to' have no effect on traffic flow. Traffic flow is always real-time."
  expect_is(traffic(aoi = aoi[aoi$code == "LI", ], product = "flow", from = Sys.time()-60*60, to = Sys.time(), url_only = TRUE), "character")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$traffic_flow_response},
    traffic_flow <- traffic(aoi = aoi[aoi$code == "LI", ], product = "flow"),

    # Tests
    expect_equal(class(traffic_flow), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(traffic_flow) != "MULTILINESTRING"), FALSE)
  )
})

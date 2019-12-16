test_that("traffic flow works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

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
  expect_error(traffic(aoi = aoi, product = "not_a_product"), "'product' must be 'flow', 'incidents'.")

  # Test URL
  # Following message should appear: "Note: 'from_dt' and 'to_dt' have no effect on traffic flow. Traffic flow is always real-time."
  expect_is(traffic(aoi = aoi[aoi$code == "LI", ], product = "flow", from_dt = Sys.time()-60*60, to_dt = Sys.time(), url_only = TRUE), "character")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$traffic_flow_response},
    traffic_flow <- traffic(aoi = aoi[aoi$code == "LI", ], product = "flow"),

    # Tests
    expect_equal(class(traffic_flow), c("sf", "data.table", "data.frame")),
    expect_equal(any(sf::st_geometry_type(traffic_flow) != "MULTILINESTRING"), FALSE)
  )
})

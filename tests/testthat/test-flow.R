test_that("flow works", {
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
  expect_error(flow(aoi = x), "'aoi' has empty entries in the geometry column.")
  expect_error(flow(aoi = c(1, 2, 3)), "'aoi' must be an sf object.")
  expect_error(flow(aoi = NA), "'aoi' must be an sf object.")
  expect_error(flow(aoi = poi), "'aoi' must be an sf object with geometry type 'POLYGON' or 'MULTIPOLYGON'.")
  expect_error(flow(aoi = aoi, min_jam_factor = -1), "'min_jam_factor' must be in the valid range from 0 to 10.")
  expect_error(flow(aoi = aoi, min_jam_factor = "11"), "'min_jam_factor' must be of type 'numeric'.")

  # Test URL
  expect_is(flow(aoi = aoi[aoi$code == "LI", ], url_only = TRUE), "character")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$flow_response},
    flows <- flow(aoi = aoi[aoi$code == "LI", ]),

    # Tests
    expect_equal(class(flows), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(flows) != "MULTILINESTRING"), FALSE)
  )
})

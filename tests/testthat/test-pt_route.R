test_that("pt_route works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(pt_route(start = c(1, 2, 3), destination = poi), "'points' must be an sf object.")
  expect_error(pt_route(start = c("character", NA), destination = poi), "'points' must be an sf object.")
  expect_error(pt_route(start = aoi, destination = poi), "'points' must be an sf object with geometry type 'POINT'.")
  expect_error(pt_route(start = poi, destination = poi, time = "not_POSIXct"))
  expect_error(pt_route(start = poi, destination = poi, results = "not_numeric"))
  expect_error(pt_route(start = poi, destination = poi, results = -1))
  expect_error(pt_route(start = poi, destination = poi, changes = "not_numeric"))
  expect_error(pt_route(start = poi, destination = poi, changes = -10))
  expect_error(pt_route(start = poi, destination = poi, arrival = "not_a_bool"))
  expect_error(pt_route(start = poi, destination = poi, summary = "not_a_bool"))
  expect_error(pt_route(start = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  ## Test with API response mock
  # Route segments: "summary = FALSE"
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$pt_route_response},
    routes <- pt_route(start = poi[3:4, ], destination = poi[5:6, ], summary = FALSE),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(length(unique(routes$id)), 2)
  )

  # Route summary: "summary = FALSE"
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$pt_route_response},
    routes <- pt_route(start = poi[3:4, ], destination = poi[5:6, ], summary = TRUE),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(length(unique(routes$id)), 2)
  )
})

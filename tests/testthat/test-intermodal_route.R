test_that("intermodal_route works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(intermodal_route(origin = c(1, 2, 3), destination = poi), "'origin' must be an sf object.")
  expect_error(intermodal_route(origin = c("character", NA), destination = poi), "'origin' must be an sf object.")
  expect_error(intermodal_route(origin = poi, destination = poi, datetime = "not_POSIXct"), "'datetime' must be of type 'POSIXct', 'POSIXt'.")
  expect_error(intermodal_route(origin = poi, destination = poi, results = "not_numeric"), "'results' must be of type 'numeric'.")
  expect_error(intermodal_route(origin = poi, destination = poi, results = -1), "'results' must be in the valid range from 1 to 7.")
  expect_error(intermodal_route(origin = poi, destination = poi, transfers = "not_numeric"), "'transfers' must be of type 'numeric'.")
  expect_error(intermodal_route(origin = poi, destination = poi, transfers = -10), "'transfers' must be in the valid range from -1 to 6.")
  expect_error(intermodal_route(origin = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$intermodal_route_response},
    intermodal_routes <- intermodal_route(origin = poi[1:2, ], destination = poi[3:4, ]),

    # Tests
    expect_s3_class(intermodal_routes, c("sf", "data.frame"), exact = TRUE),
    expect_true(all(sf::st_geometry_type(intermodal_routes) == "LINESTRING"))
  )
})

test_that("route works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Input checks
  expect_error(route(start = c(1, 2, 3), destination = poi), "'points' must be an sf object.")
  expect_error(route(start = c("character", NA), destination = poi), "'points' must be an sf object.")
  expect_error(route(start = poi, destination = poi, mode = "not_a_mode"))
  expect_error(route(start = poi, destination = poi, type = "not_a_type"))
  expect_error(route(start = poi, destination = poi, traffic = "not_a_bool"), "'traffic' must be a 'boolean' value.")
  expect_error(route(start = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$route_response},
    routes <- route(start = poi[1:2, ], destination = poi[3:4, ]),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(nrow(routes), nrow(poi[1:2, ]))
  )
})

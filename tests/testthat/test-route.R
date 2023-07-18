test_that("route works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(route(origin = c(1, 2, 3), destination = poi), "'origin' must be an sf or sfc object.")
  expect_error(route(origin = c("character", NA), destination = poi), "'origin' must be an sf or sfc object.")
  expect_error(route(origin = poi, destination = poi, transport_mode = "not_a_transport_mode"))
  expect_error(route(origin = poi, destination = poi, routing_mode = "not_a_routing_mode"))
  expect_error(route(origin = poi, destination = poi, traffic = "not_a_bool"), "'traffic' must be a 'boolean' value.")
  expect_error(route(origin = poi, destination = poi, vignettes = "not_a_bool"), "'vignettes' must be a 'boolean' value.")
  expect_error(route(origin = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Avoid area and features
  expect_true(all(grepl("&avoid[areas]=bbox:", route(origin = poi, destination = poi, avoid_area = aoi, url_only = TRUE), fixed = TRUE)))
  expect_true(all(grepl("&avoid[features]=tollRoad,ferry", route(origin = poi, destination = poi, avoid_feature = c("tollRoad", "ferry"), url_only = TRUE), fixed = TRUE)))

  # Request tolls
  expect_true(all(grepl(",tolls&tolls[summaries]=total", route(origin = poi, destination = poi, vignettes = TRUE, url_only = TRUE), fixed = TRUE)))
  expect_true(all(grepl(",tolls&tolls[summaries]=total&tolls[vignettes]=all", route(origin = poi, destination = poi, vignettes = FALSE, url_only = TRUE), fixed = TRUE)))
  expect_false(all(grepl(",tolls&tolls[summaries]=total", route(origin = poi, destination = poi, transport_mode = "bicycle", url_only = TRUE), fixed = TRUE)))
  expect_false(all(grepl(",tolls&tolls[summaries]=total&tolls[vignettes]=all", route(origin = poi, destination = poi, transport_mode = "bicycle", vignettes = FALSE, url_only = TRUE), fixed = TRUE)))

  # Test with API response mock
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$route_response
    },
    routes <- route(origin = poi[1:2, ], destination = poi[3:4, ]),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(nrow(routes), nrow(poi[1:2, ]))
  )
})

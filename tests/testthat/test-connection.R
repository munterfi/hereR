test_that("connection works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(connection(origin = c(1, 2, 3), destination = poi), "'origin' must be an sf object.")
  expect_error(connection(origin = c("character", NA), destination = poi), "'origin' must be an sf object.")
  expect_error(connection(origin = aoi, destination = poi), "'origin' must be an sf object with geometry type 'POINT'.")
  expect_error(connection(origin = poi[1, ], destination = poi), "'origin' must have the same number of rows as 'destination'.")
  expect_error(connection(origin = poi, destination = poi, datetime = "not_POSIXct"))
  expect_error(connection(origin = poi, destination = poi, results = "not_numeric"))
  expect_error(connection(origin = poi, destination = poi, results = -1))
  expect_error(connection(origin = poi, destination = poi, transfers = "not_numeric"))
  expect_error(connection(origin = poi, destination = poi, transfers = -10))
  expect_error(connection(origin = poi, destination = poi, arrival = "not_a_bool"))
  expect_error(connection(origin = poi, destination = poi, transport_mode = c("highSpeedTrain", "-highSpeedTrain")))
  expect_error(connection(origin = poi, destination = poi, summary = "not_a_bool"))
  expect_error(connection(origin = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  ## Test with API response mock
  # Route segments: "summary = FALSE"
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$connection_response
    },
    connections <- connection(origin = poi[3:4, ], destination = poi[5:6, ], summary = FALSE),

    # Tests
    expect_equal(any(sf::st_geometry_type(connections) != "LINESTRING"), FALSE),
    expect_equal(length(unique(connections$id)), 2)
  )

  # Route summary: "summary = FALSE"
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$connection_response
    },
    connections <- connection(origin = poi[3:4, ], destination = poi[5:6, ], summary = TRUE),

    # Tests
    expect_equal(any(sf::st_geometry_type(connections) != "MULTILINESTRING"), FALSE),
    expect_equal(length(unique(connections$id)), 2)
  )
})

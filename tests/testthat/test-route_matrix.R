test_that("route_matrix works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(route_matrix(origin = c(1, 2, 3), destination = poi), "'origin' must be an sf object.")
  expect_error(route_matrix(origin = c("character", NA), destination = poi), "'origin' must be an sf object.")
  expect_error(route_matrix(origin = poi, destination = poi, datetime = "not_POSIXct"))
  expect_error(route_matrix(origin = poi, destination = poi, transport_mode = "not_a_transport_mode"))
  expect_error(route_matrix(origin = poi, destination = poi, routing_mode = "not_a_routing_mode"))
  expect_error(route_matrix(origin = poi, destination = poi, traffic = "not_a_bool"), "'traffic' must be a 'boolean' value.")
  expect_error(route_matrix(origin = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Deprecated
  expect_warning(route_matrix(origin = poi, destination = poi, type = "fast", url_only = TRUE))
  expect_warning(route_matrix(origin = poi, destination = poi, mode = "car", url_only = TRUE))

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {
      hereR:::mock$route_matrix_response
    },
    r_mat <- route_matrix(origin = poi),

    # Tests
    expect_is(r_mat, "data.frame"),
    expect_equal(nrow(r_mat), nrow(poi)**2)
  )
})

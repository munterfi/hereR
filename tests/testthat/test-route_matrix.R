test_that("route_matrix works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(route_matrix(origin = c(1, 2, 3), destination = poi), "'points' must be an sf object.")
  expect_error(route_matrix(origin = c("character", NA), destination = poi), "'points' must be an sf object.")
  expect_error(route_matrix(origin = poi, destination = poi, mode = "not_a_mode"))
  expect_error(route_matrix(origin = poi, destination = poi, type = "not_a_type"))
  expect_error(route_matrix(origin = poi, destination = poi, attribute = "not_an_attribute"), "'attribute' must be in 'distance', 'traveltime'.")
  expect_error(route_matrix(origin = poi, destination = poi, traffic = "not_a_bool"), "'traffic' must be a 'boolean' value.")
  expect_error(route_matrix(origin = poi, destination = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$route_matrix_response},
    r_mat <- route_matrix(origin = poi),

    # Tests
    expect_is(r_mat, c("data.frame")),
    expect_equal(nrow(r_mat), nrow(poi) ** 2)
  )
})

test_that("isoline works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(isoline(poi = c(1, 2, 3)), "'points' must be an sf object.")
  expect_error(isoline(poi = c("character", NA)), "'points' must be an sf object.")
  expect_error(isoline(poi = poi, mode = "not_a_mode"))
  expect_error(isoline(poi = poi, type = "not_a_type"))
  expect_error(isoline(poi = poi, range_type = "not_a_range_type"))
  expect_error(isoline(poi = poi, traffic = "not_a_bool"), "'traffic' must be a 'boolean' value.")
  expect_error(isoline(poi = poi, arrival = "not_a_bool"), "'arrival' must be a 'boolean' value.")
  expect_error(isoline(poi = poi, aggregate = "not_a_bool"), "'aggregate' must be a 'boolean' value.")
  expect_error(isoline(poi = poi, url_only = "not_a_bool"), "'url_only' must be a 'boolean' value.")

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$isoline_response},

    # With and without aggregation
    isolines_aggr <- isoline(poi = poi, aggregate = TRUE),
    isolines_mult <- isoline(poi = poi, aggregate = FALSE),

    # Tests
    expect_equal(any(sf::st_geometry_type(isolines_aggr) != "MULTIPOLYGON"), FALSE),
    expect_equal(any(sf::st_geometry_type(isolines_mult) != "POLYGON"), FALSE)
  )
})

test_that("isoline works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

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

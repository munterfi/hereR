test_that("isoline works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load API response mock and example
  data(example_geocode)
  data(mock_isoline)

  # Test with mocked API response
  with_mock(
    "hereR:::.get_content" = function(url) {mock_isoline},

    # With and without aggregation
    isolines_aggr <- isoline(poi = example_geocode, aggregate = TRUE),
    isolines_mult <- isoline(poi = example_geocode, aggregate = FALSE),

    # Tests
    expect_equal(any(sf::st_geometry_type(isolines_aggr) != "MULTIPOLYGON"), FALSE),
    expect_equal(any(sf::st_geometry_type(isolines_mult) != "POLYGON"), FALSE)
  )
})

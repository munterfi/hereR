test_that("route works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load API response mock and example
  data(example_geocode)
  data(mock_route)

  # Test with mocked API response
  with_mock(
    "hereR:::.get_content" = function(url) {mock_route},
    routes <- route(start = example_geocode[1:2, ],
                                     destination = example_geocode[3:4, ]),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(nrow(routes), nrow(example_geocode[1:2, ]))
  )
})

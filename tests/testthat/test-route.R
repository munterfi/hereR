test_that("route works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$route_response},
    routes <- route(start = poi[1:2, ], destination = poi[3:4, ]),

    # Tests
    expect_equal(any(sf::st_geometry_type(routes) != "LINESTRING"), FALSE),
    expect_equal(nrow(routes), nrow(poi[1:2, ]))
  )
})

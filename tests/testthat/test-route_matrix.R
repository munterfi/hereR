test_that("route_matrix works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load API response mock and example
  data(example_geocode)
  data(mock_route_matrix)

  # Test with mocked API response
  with_mock(
    "hereR:::.get_content" = function(url) {mock_route_matrix},
    r_mat <- route_matrix(start = example_geocode),

    # Tests
    expect_is(r_mat, c("data.table", "data.frame")),
    expect_equal(nrow(r_mat), nrow(example_geocode) ** 2)
  )
})

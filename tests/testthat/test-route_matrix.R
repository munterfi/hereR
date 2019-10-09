test_that("route_matrix works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Test with API response mock
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$route_matrix_response},
    r_mat <- route_matrix(start = poi),

    # Tests
    expect_is(r_mat, c("data.table", "data.frame")),
    expect_equal(nrow(r_mat), nrow(poi) ** 2)
  )
})

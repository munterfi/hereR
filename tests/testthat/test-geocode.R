test_that("geocode works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load API response mock and example
  data(example_addresses)
  data(mock_geocode)

  # Test with mocked API response
  with_mock(
    "hereR:::.get_content" = function(url) {mock_geocode},
    geocoded <- geocode(addresses = example_addresses),

    # Tests
    expect_equal(any(sf::st_geometry_type(geocoded) != "POINT"), FALSE),
    expect_equal(nrow(geocoded), length(example_addresses))
  )
})

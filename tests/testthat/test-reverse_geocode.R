test_that("reverse_geocode works", {
  # Set dummy login
  set_auth(
    app_id = "dummy_app_id",
    app_code = "dummy_app_code"
  )

  # Load package example data
  data(poi)

  # Input checks
  expect_error(reverse_geocode(poi = c(1, 2, 3)), "'points' must be an sf object.")
  expect_error(reverse_geocode(poi = c("character", NA)), "'points' must be an sf object.")
  expect_error(reverse_geocode(poi = poi, results = -100), "'results' must be of in the valid range from 1 to 20.")
  expect_error(reverse_geocode(poi = poi, results = "-100"), "'results' must be of type 'numeric'.")

  # Test with API response mock: addresses
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$reverse_geocode_addresses},
    addresses <- reverse_geocode(poi = poi,  results = 3, landmarks = FALSE),

    # Tests
    expect_equal(any(sf::st_geometry_type(addresses) != "POINT"), FALSE)
  )

  # Test with API response mock: landmarks
  with_mock(
    "hereR:::.get_content" = function(url) {hereR:::mock$reverse_geocode_landmarks},
    landmarks <- reverse_geocode(poi = poi,  results = 3, landmarks = TRUE),

    # Tests
    expect_equal(any(sf::st_geometry_type(landmarks) != "POINT"), FALSE)
  )
})

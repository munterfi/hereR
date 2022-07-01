test_that("geocode works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(poi)

  # Input checks
  expect_error(geocode(c(1, 2, 3)))
  expect_error(geocode(c("character", NA)), "'address' contains NAs.")
  expect_error(geocode(""), "'address' contains empty strings.")
  expect_error(geocode("  "), "'address' contains empty strings.")
  expect_error(geocode("test", alternatives = NA), "'alternatives' must be a 'boolean' value.")
  expect_error(geocode("test", sf = NA), "'sf' must be a 'boolean' value.")
  expect_error(geocode("test", url_only = NA), "'url_only' must be a 'boolean' value.")

  # Check qualified query inputs
  qq <- list(
    list(
      country = "Germany",
      state = "",
      county = "",
      city = "Berlin",
      district = "",
      street = "Friedrichstr",
      houseNumber = "",
      postalCode = NA
    ),
    list(
      country = "Switzerland",
      city = "Zurich",
      street = "Hardstrasse"
    )
  )
  expect_error(geocode(list(), url_only = TRUE))
  expect_error(geocode(qq[[1]], url_only = TRUE))
  expect_error(geocode(list(list(nor = "a", valid = "query")), url_only = TRUE))
  expect_type(geocode(qq[1], url_only = TRUE), "character")
  expect_type(geocode(qq, url_only = TRUE), "character")


  # Test with API response mock
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$geocode_response
    },
    geocoded <- geocode(address = poi$city),

    # Tests
    expect_s3_class(geocoded, c("sf", "data.frame"), exact = TRUE),
    expect_true(all(sf::st_geometry_type(geocoded) == "POINT")),
    expect_equal(nrow(geocoded), length(poi$city))
  )
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$geocode_response
    },
    geocoded <- geocode(address = poi$city, alternatives = TRUE, sf = FALSE),

    # Tests
    expect_s3_class(geocoded, "data.frame", exact = TRUE),
    expect_gt(nrow(geocoded), length(poi$city)),
    expect_type(geocoded[["lat_position"]], "double"),
    expect_type(geocoded[["lng_position"]], "double"),
    expect_type(geocoded[["lat_access"]], "double"),
    expect_type(geocoded[["lng_access"]], "double")
  )
})

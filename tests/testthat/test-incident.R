test_that("incidents works", {
  # Set dummy key
  set_key("dummy_api_key")

  # Load package example data
  data(aoi)

  # Input checks
  expect_error(incident(aoi = c(1, 2, 3)), "'aoi' must be an sf or sfc object.")
  expect_error(incident(aoi = NA), "'aoi' must be an sf or sfc object.")

  # Test URL
  expect_is(incident(
    aoi = aoi, from = Sys.time() - 60 * 60,
    url_only = TRUE
  ), "character")

  # Test with API response mock
  with_mock(
    "hereR:::.async_request" = function(url, rps) {
      hereR:::mock$incident_response
    },
    incidents <- incident(aoi = aoi),

    # Tests
    expect_equal(class(incidents), c("sf", "data.frame")),
    expect_equal(any(sf::st_geometry_type(incidents) != "MULTILINESTRING"), FALSE)
  )
})

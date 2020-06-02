test_that("defunct works", {

  # set_auth
  expect_error(set_auth(app_id = "DE", app_code = "FUNCT"))

  # unset_auth
  expect_error(unset_auth())

  # traffic
  expect_error(traffic(aoi = aoi, product = "flow"))
  expect_error(traffic(aoi = aoi, product = "incidents"))

})

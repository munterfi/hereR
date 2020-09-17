test_that("defunct works", {

  # set_auth
  expect_error(set_auth(app_id = "DE", app_code = "FUNCT"))

  # unset_auth
  expect_error(unset_auth())

  # traffic
  expect_error(traffic(aoi = aoi, product = "flow"))
  expect_error(traffic(aoi = aoi, product = "incidents"))

  # autocomplete
  expect_error(autocomplete("Defunct"))

  # set_proxy
  expect_error(set_proxy(proxy = "DE", proxyuserpwd = "FUNCT"))

  # unset_proxy
  expect_error(unset_proxy())
})

test_that("authentication works", {

  # Defunct
  expect_error(set_auth(app_id = "character", app_code = "character"))
  expect_error(unset_auth())

  # Input checks
  expect_error(set_key(1))
  expect_error(set_proxy(proxy = 1, proxyuserpwd = "user:pwd"), "'proxy' must be of type 'character'.")
  expect_error(set_proxy(proxy = "https://your-proxy.net:port/", proxyuserpwd = "userpwd"), "'proxyuserpwd' is not in the required format: 'user:pwd'.")
  expect_error(set_proxy(proxy = "https://your-proxy.net:port/", proxyuserpwd = 1), "'proxyuserpwd' must be of type 'character'.")
  expect_error(set_proxy(proxy = "not_an_url", proxyuserpwd = "user:pwd"), "'proxy' is not in the required format: 'http://your-proxy.com:port/' or 'https://your-proxy.org:port/'.")

  # Test set and unset API key
  set_key("apiKey")
  expect_equal(Sys.getenv("HERE_API_KEY"), "apiKey")
  unset_key()
  expect_equal(Sys.getenv("HERE_API_KEY"), "")

  # Test set and unset proxy
  set_proxy(proxy = "https://your-proxy.net:port/", proxyuserpwd = "user:pwd")
  expect_equal(Sys.getenv("HERE_PROXY"), "https://your-proxy.net:port/")
  expect_equal(Sys.getenv("HERE_PROXYUSERPWD"), "user:pwd")
  unset_proxy()
  expect_equal(Sys.getenv("HERE_PROXY"), "")
  expect_equal(Sys.getenv("HERE_PROXYUSERPWD"), "")
})

test_that("async_request works", {
  set_verbose(TRUE)
  response <- hereR:::.async_request(urls = "https://jsonplaceholder.typicode.com/posts")
  expect_is(response, "list")
  expect_is(response[[1]], "character")
})

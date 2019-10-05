.add_auth <- function(url) {
  app_id = Sys.getenv("HERE_APP_ID")
  app_code = Sys.getenv("HERE_APP_CODE")
  .check_auth(app_id, app_code)
  paste0(
    url,
    "&app_id=",
    app_id,
    "&app_code=",
    app_code)
}

.add_mode <- function(url, type, mode, traffic) {
  mode_str <- sprintf(
    "%s;%s;%s",
    type,
    mode,
    if (traffic) {"traffic:enabled"} else {"traffic:disabled"})
  return(
    paste0(
      url,
      "&mode=",
      mode_str
    )
  )
}

.add_departure <- function(url, departure) {
  paste0(
    url,
    "&departure=",
    if (is.null(departure)) {
      "now"
    } else {
      .encode_datetime(departure)
    }
  )
}


.add_arrival <- function(url, arrival) {
  paste0(
    url,
    "&arrival=",
      .encode_datetime(arrival)
  )
}

.encode_datetime <- function(datetime) {
  stringr::str_replace(
    as.character(datetime), " ", "T"
  )
}

.get_content <- function(url, encoding = "UTF-8") {
  # Code: https://hydroecology.net/asynchronous-web-requests-with-curl/
  # Callback function generator - returns a callback function with ID
  results = list()
  cb_gen = function(id) {
    function(res) {
      if (res$status != 200)
        stop(sprintf("Request failed with HTTP status code %s", res$status))
      results[[id]] <<- res
    }
  }

  # Define the IDs
  ids = paste0("request_", seq_along(url))

  # Define the callback functions
  cbs = lapply(ids, cb_gen)

  # Request pool and add proxy
  pool = curl::new_pool()
  proxy <- Sys.getenv("HERE_PROXY")
  proxyuserpwd <- Sys.getenv("HERE_PROXYUSERPWD")
  lapply(seq_along(url), function(i) {
    handle <- curl::new_handle()
    curl::handle_setopt(handle,
                        proxy = proxy,
                        proxyuserpwd = proxyuserpwd)
    curl::curl_fetch_multi(utils::URLencode(url[i]), pool = pool,
                           done = cbs[[i]], fail = cbs[[i]],
                           handle = handle)
  })

  # Send requests
  out = curl::multi_run(pool = pool)

  # Process the results in the same order that the URLs were given
  lapply(results[ids], function(x) {
    rawChar <- rawToChar(x$content)
    Encoding(rawChar) <- encoding
    rawChar
  })
}



# .get_content <- function(url, proxy, proxyuserpwd) {
#   data <- list()
#
#   # Create pool and define return functions
#   pool <- curl::new_pool()
#   success <- function(res) {
#     if (res$status != 200)
#       stop(sprintf("Request failed with HTTP status code %s", res$status))
#     data <<- c(data, list(res$content))
#   }
#   failure <- function(res) {
#     stop(sprintf("Request failed with HTTP status code %s", res$status))
#   }
#
#   # Add to pool
#   for (u in url) {
#     handle <- curl::new_handle()
#     curl::handle_setopt(handle,
#                         proxy = proxy,
#                         proxyuserpwd = proxyuserpwd)
#     curl::curl_fetch_multi(url = utils::URLencode(u),
#                            done = success, fail = failure,
#                            pool = pool, handle = handle)
#   }
#
#   # Process pool
#   out <- curl::multi_run(pool = pool)
#   return(data)
# }

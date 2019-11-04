## API URLs

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

.add_datetime <- function(url, datetime, field_name) {
  if (is.null(datetime)) {
    return(url)
  } else {
    paste0(
      url,
      paste0("&", field_name, "="),
      .encode_datetime(datetime)
    )
  }
}

.encode_datetime <- function(datetime) {
  stringr::str_replace(
    as.character(datetime), " ", "T"
  )
}


## Requests

.get_content <- function(url, encoding = "UTF-8") {
  # Code: https://hydroecology.net/asynchronous-web-requests-with-curl/
  # Callback function generator - returns a callback function with ID
  results = list()
  cb_gen = function(id) {
    function(res) {
      if (is.character(res))
        stop("Connection error: Please check connection to the internet and proxy configuration.")
      if (res$status != 200) {
        message(sprintf("Request failed: HTTP status code %s.", res$status))
        ids <<- ids[ids != id]
      } else {
        results[[id]] <<- res
      }
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
  results <- lapply(results[ids], function(x) {
    rawChar <- rawToChar(x$content)
    Encoding(rawChar) <- encoding
    rawChar
  })
  results
}


## Geometries

.line_from_pointList <- function(pointList) {
  coords <- strsplit(pointList, ",")
  lng <- as.numeric(sapply(coords, function(x) x[2]))
  lat <- as.numeric(sapply(coords, function(x) x[1]))
  sf::st_linestring(cbind(lng, lat))
}

.polygon_from_pointList <- function(pointList) {
  coords <- strsplit(pointList, ",")
  lng <- as.numeric(sapply(coords, function(x) x[2]))
  lat <- as.numeric(sapply(coords, function(x) x[1]))
  sf::st_polygon(list(cbind(lng, lat)))
}

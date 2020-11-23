## API URLs

.add_key <- function(url) {
  api_key = Sys.getenv("HERE_API_KEY")
  .check_key(api_key)
  paste0(
    url,
    "apiKey=",
    api_key)
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
  dt <- format(datetime, "%Y-%m-%dT%H:%M:%S%z")
  stringr::str_replace(
    paste0(
      stringr::str_sub(dt, 1, -3), ":",
      stringr::str_sub(dt, -2, nchar(dt))
    ),
    "\\+", "%2B"
  )
}


## Requests

.get_content <- function(url, encoding = "UTF-8") {
  if (Sys.getenv("HERE_VERBOSE") != "") {
    message(
      sprintf(
        "Sending %s request(s) to: '%s?...'",
        length(url), strsplit(url, "\\?", )[[1]][1]
      )
    )
  }
  # Code: https://hydroecology.net/asynchronous-web-requests-with-curl/
  # Callback function generator - returns a callback function with ID
  results = list()
  cb_gen = function(id) {
    function(res) {
      if (is.character(res))
        stop("Connection error: Please check connection to the internet and proxy configuration.")
      if (res$status != 200) {
        warning(
          sprintf("Request 'id = %s' failed: Status %s. ",
                  strsplit(id, "_")[[1]][2], res$status)
        )
        ids <<- ids[ids != id]
      } else {
        results[[id]] <<- res
      }
    }
  }

  # Define the IDs and callback functions
  ids = paste0("request_", seq_along(url))
  cbs = lapply(ids, cb_gen)

  # Add requests to pool
  pool = curl::new_pool()
  lapply(seq_along(url), function(i) {
    handle <- curl::new_handle()
    curl::curl_fetch_multi(utils::URLencode(url[i]), pool = pool,
                           done = cbs[[i]], fail = cbs[[i]],
                           handle = curl::new_handle())
  })

  # Send requests and process the responses in the same order as the input URLs
  out = curl::multi_run(pool = pool)
  results <- lapply(results[ids], function(x) {
    rawChar <- rawToChar(x$content)
    Encoding(rawChar) <- encoding
    rawChar
  })
  if (Sys.getenv("HERE_VERBOSE") != "") {
    message(
      sprintf(
        "Received %s response(s) with total size: %s",
        length(results),
        format(utils::object.size(results), units = "auto")
      )
    )
  }
  results
}

.get_ids <- function(content) {
  as.numeric(sapply(strsplit(names(content), "_"), function(x){x[[2]]}))
}

.parse_datetime <- function(datetime, format = "%Y-%m-%dT%H:%M:%OS", tz = Sys.timezone()) {
  datetime <- as.POSIXct(datetime, format = format, tz = "UTC")
  attr(datetime, "tzone") <- tz
  datetime
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

.wkt_from_point_df <- function(df, lng_col, lat_col) {
  df <- as.data.frame(df)
  sf::st_as_text(
    sf::st_as_sfc(
      lapply(1:nrow(df), function(x) {
        if (is.numeric(df[x, lng_col]) & is.numeric(df[x, lat_col])) {
          return(
            sf::st_point(
              cbind(df[x, lng_col], df[x, lat_col])
            )
          )
        } else {
          return(sf::st_point())
        }
      }), crs = 4326
    )
  )
}

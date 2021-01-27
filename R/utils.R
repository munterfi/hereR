## API URLs

.add_key <- function(url) {
  api_key <- Sys.getenv("HERE_API_KEY")
  .check_key(api_key)
  paste0(
    url,
    "apiKey=",
    api_key
  )
}

.add_transport_mode <- function(url, transport_mode) {
  paste0(
    url,
    "&transportMode=",
    paste0(transport_mode, collapse = ",")
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

.encode_datetime <- function(datetime, url_encode = TRUE) {
  dt <- format(datetime, "%Y-%m-%dT%H:%M:%S%z")
  dt <- paste0(
    stringr::str_sub(dt, 1, -3), ":",
    stringr::str_sub(dt, -2, nchar(dt))
  )
  if (url_encode) {
    return(stringr::str_replace(dt, "\\+", "%2B"))
  } else {
    return(dt)
  }
}


## Requests
# Inspired by: https://hydroecology.net/asynchronous-web-requests-with-curl/
.get_content <- function(url, encoding = "UTF-8") {
  if (Sys.getenv("HERE_VERBOSE") != "") {
    message(
      sprintf(
        "Sending %s request(s) to: '%s?...'",
        length(url), strsplit(url[1], "\\?", )[[1]][1]
      )
    )
  }

  # Split url strings into url, headers and request body (if any)
  url <- strsplit(url, " | ", fixed = TRUE)

  # Callback function generator - returns a callback function with ID
  results <- list()
  cb_gen <- function(id) {
    function(res) {
      if (is.character(res)) {
        stop("Connection error: Please check connection to the internet and proxy configuration.")
      }
      if (res$status != 200) {
        warning(
          sprintf(
            "Request 'id = %s' failed: Status %s. ",
            strsplit(id, "_")[[1]][2], res$status
          )
        )
        ids <<- ids[ids != id]
      } else {
        results[[id]] <<- res
      }
    }
  }

  # Define the IDs and callback functions
  ids <- paste0("request_", seq_along(url))
  cbs <- lapply(ids, cb_gen)

  # Add requests to pool and check for headers and request body
  pool <- curl::new_pool()
  lapply(seq_along(url), function(i) {
    handle <- curl::new_handle()
    if (length(url[[i]]) == 3) {
      curl::handle_setheaders(handle, .list = jsonlite::fromJSON(url[[i]][2]))
      curl::handle_setopt(handle, copypostfields = url[[i]][3])
    }
    curl::curl_fetch_multi(utils::URLencode(url[[i]][1]),
      pool = pool,
      done = cbs[[i]], fail = cbs[[i]],
      handle = handle
    )
  })

  # Send requests and process the responses in the same order as the input URLs
  out <- curl::multi_run(pool = pool)
  results <- lapply(results[ids], function(x) {
    raw_char <- rawToChar(x$content)
    Encoding(raw_char) <- encoding
    raw_char
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
  as.numeric(sapply(strsplit(names(content), "_"), function(x) {
    x[[2]]
  }))
}

# Deprecated (still used in incident and weather)...
.parse_datetime <- function(datetime, format = "%Y-%m-%dT%H:%M:%OS", tz = Sys.timezone()) {
  datetime <- as.POSIXct(datetime, format = format, tz = "UTC")
  attr(datetime, "tzone") <- tz
  datetime
}

.parse_datetime_tz <- function(datetime, tz = Sys.timezone()) {
  datetime <- as.POSIXct(sub(":(..)$", "\\1", datetime), format = "%Y-%m-%dT%H:%M:%OS%z")
  attr(datetime, "tzone") <- tz
  datetime
}

## Geometries

.line_from_point_list <- function(point_list) {
  coords <- strsplit(point_list, ",")
  lng <- as.numeric(sapply(coords, function(x) x[2]))
  lat <- as.numeric(sapply(coords, function(x) x[1]))
  sf::st_linestring(cbind(lng, lat))
}

.wkt_from_point_df <- function(df, lng_col, lat_col) {
  df <- as.data.frame(df)
  sf::st_as_text(
    sf::st_as_sfc(
      lapply(seq_len(nrow(df)), function(x) {
        if (is.numeric(df[x, lng_col]) & is.numeric(df[x, lat_col])) {
          return(
            sf::st_point(
              cbind(df[x, lng_col], df[x, lat_col])
            )
          )
        } else {
          return(sf::st_point())
        }
      }),
      crs = 4326
    )
  )
}

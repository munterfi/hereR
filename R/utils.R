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

.async_request <- function(url, rps = Inf, ...) {
  .check_internet()

  # Check if rate limits are enabled
  if (!.get_freemium()) {
    rps <- Inf
  }
  .verbose_request(url, rps)

  # Split url strings into url, headers and request body (if any)
  url <- strsplit(url, " | ", fixed = TRUE)

  # Options
  opt_list <- append(
    list(
      useragent = sprintf(
        "hereR/%s R/%s (%s)",
        utils::packageVersion("hereR"),
        getRversion(),
        R.Version()$platform
      )
    ),
    list(...)
  )

  # Construct requests: GET or POST
  reqs <- lapply(url, function(u) {
    req <- crul::HttpRequest$new(
      url = u[[1]],
      headers = list(Accept = "application/json", `Accept-Charset` = "utf-8"),
      opts = opt_list
    )
    if (length(u) == 3) {
      req$post(
        headers = jsonlite::fromJSON(u[[2]]),
        body = u[[3]]
      )
    } else {
      req$get()
    }
  })

  # Process queue
  out <- crul::AsyncQueue$new(.list = reqs, bucket_size = rps, sleep = 1)
  out$request()

  # Parse result
  res_list <- lapply(seq_along(out$responses()), function(i) {
    .parse_response(i, out$responses()[[i]])
  })
  names(res_list) <- paste0("request_", seq_along(url))
  .verbose_response(res_list)

  # Filter on successful responses
  res_list <- Filter(Negate(is.null), res_list)

  return(res_list)
}

.get_verbose <- function() {
  if (Sys.getenv("HERE_VERBOSE") != "") {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

.get_freemium <- function() {
  if (Sys.getenv("HERE_FREEMIUM") != "") {
    return(FALSE)
  } else {
    return(TRUE)
  }
}

.get_currency <- function() {
  currency <- Sys.getenv("HERE_CURRENCY")
  if (currency != "") {
    return(currency)
  }
  currency <- Sys.localeconv()[["int_curr_symbol"]]
  if (currency != "") {
    return(gsub(" ", "", currency, fixed = TRUE))
  }
  return("USD")
}

.verbose_request <- function(url, rps) {
  if (.get_verbose()) {
    message(
      sprintf(
        "Sending %s request(s) with %s RPS to: '%s?...'",
        length(url), ifelse(is.infinite(rps), "unlimited", rps),
        strsplit(url, "\\?", )[[1]][1]
      )
    )
  }
}

.verbose_response <- function(res_list) {
  if (.get_verbose()) {
    message(
      sprintf(
        "Received %s response(s) with total size: %s",
        length(res_list),
        format(utils::object.size(res_list), units = "auto")
      )
    )
  }
}

.parse_response <- function(i, res) {
  if (res$status_code != 200) {
    warning(
      sprintf(
        "%s: Request 'id = %s' failed. \n  Status %s.",
        strsplit(res$url, "\\?", )[[1]][1], i,
        paste(as.character(res$status_http()), collapse = "; ")
      )
    )
    return(NULL)
  } else {
    return(res$parse("UTF-8"))
  }
}

.get_ids <- function(content) {
  as.numeric(vapply(strsplit(names(content), "_"), function(x) {
    x[[2]]
  }, character(1)))
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
  lng <- as.numeric(vapply(coords, function(x) x[2], character(1)))
  lat <- as.numeric(vapply(coords, function(x) x[1], character(1)))
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

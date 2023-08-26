#' HERE Destination Weather API: Observations, Forecasts, Astronomy and Alerts
#'
#' Weather forecasts, reports on current weather conditions,
#' astronomical information and alerts at a specific location (coordinates or
#' location name) based on the HERE 'Destination Weather' API.
#' The information comes from the nearest available weather station and is not interpolated.
#'
#' @references
#' \href{https://developer.here.com/documentation/destination-weather/api-reference-v3.html}{HERE Destination Weather API}
#'
#' @param poi \code{sf} object or character, Points of Interest (POIs) of geometry type \code{POINT} or location names (e.g. cities or regions).
#' @param product character, weather product of the 'Destination Weather API'. Supported products: \code{"observation"}, \code{"forecastHourly"}, \code{"forecastAstronomy"} and \code{"alerts"}.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested weather information at the nearest weather station.
#' The point geometry in the \code{sf} object is the location of the weather station.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Observation
#' observation <- weather(poi = poi, product = "observation", url_only = TRUE)
#'
#' # Forecast
#' forecast <- weather(poi = poi, product = "forecastHourly", url_only = TRUE)
#'
#' # Astronomy
#' astronomy <- weather(poi = poi, product = "forecastAstronomy", url_only = TRUE)
#'
#' # Alerts
#' alerts <- weather(poi = poi, product = "alerts", url_only = TRUE)
weather <- function(poi, product = "observation", url_only = FALSE) {
  UseMethod("weather", poi)
}

#' @export
weather.character <- function(poi, product = "observation", url_only = FALSE) {
  .check_character(poi)
  query <- paste0(
    "&q=",
    curl::curl_escape(poi)
  )
  .weather.default(query, product, url_only)
}

#' @export
weather.sf <- function(poi, product = "observation", url_only = FALSE) {
  weather.sfc(sf::st_geometry(poi), product, url_only)
}

#' @export
weather.sfc <- function(poi, product = "observation", url_only = FALSE) {
  .check_points(poi)
  poi <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  location <- paste0(
    "&location=", poi[, 2], ",", poi[, 1]
  )
  .weather.default(location, product, url_only)
}

.weather.default <- function(poi, product = "observation", url_only = FALSE) {
  # Checks
  .check_weather_product(product)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://weather.hereapi.com/v3/report?"
  )

  # Add formatted location or query parameter
  url <- paste0(
    url,
    poi
  )

  # Add product
  url <- paste0(
    url,
    "&products=",
    product
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .async_request(
    url = url,
    rps = 3
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  weather_data <- switch(product,
    "observation" = .extract_weather_observation(data),
    "forecastHourly" = .extract_weather_forecast_hourly(data),
    "forecastAstronomy" = .extract_weather_forecast_astronomy(data),
    "alerts" = .extract_weather_alerts(data)
  )

  # Create sf, data.table, data.frame
  rownames(weather_data) <- NULL
  return(
    sf::st_set_crs(
      sf::st_as_sf(
        as.data.frame(weather_data),
        coords = c("lng", "lat")
      ), 4326
    )
  )
}

.extract_weather_observation <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  observation <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      df <- jsonlite::fromJSON(con)
      station <- data.table::data.table(
        id = ids[count],
        station = df$observations$location$city[1],
        lng = df$observations$location$longitude[1],
        lat = df$observations$location$latitude[1],
        distance = df$observations$location$distance[1] * 1000,
        timestamp = .parse_datetime(df$observations$location$observation[[1]]$utcTime),
        state = df$observations$location$state[1],
        country = df$observations$location$country[1]
      )
      obs <- df$observations$location$observation[[1]]
      obs <- obs[, !names(obs) %in% c(
        "skyDescription", "airDescription", "precipitationDesc",
        "temperatureDesc", "iconName", "iconLink", "windDesc", "icon",
        "country", "state", "city", "latitude", "longitude", "distance",
        "utcTime", "elevation"
      ), ]
      obs[, c(4:9)] <- vapply(obs[, c(4:9)], as.numeric, numeric(1))
      return(
        cbind(station, obs)
      )
    })
  )
  return(observation)
}

.extract_weather_forecast_hourly <- function(data) {
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    country_code = character(),
    country = character(),
    state = character(),
    city = character(),
    lng = numeric(),
    lat = numeric()
  )
  ids <- .get_ids(data)
  count <- 0
  forecasts <- list()
  forecast <- data.table::rbindlist(
    append(list(template), lapply(data, function(con) {
    count <<- count + 1
    rank_id <- 0
    df <- jsonlite::fromJSON(con)
    data.table::rbindlist(lapply(df$places$hourlyForecast, function(result) {
        rank_id <<- rank_id + 1
        forecasts <<- append(forecasts, result$forecasts)
        data.table::data.table(
          id = ids[count],
          rank = rank_id,
          country_code = result$place$address$countryCode,
          country = result$place$address$countryName,
          state = result$place$address$state,
          city = result$place$address$city,
          lng = result$place$location$lng,
          lat = result$place$location$lat
        )
    }), fill = TRUE)
  })), fill = TRUE)
  forecast <- cbind(forecast, forecasts)
  return(forecast)
}

.extract_weather_forecast_astronomy <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  dfs <- lapply(data, function(con) {
    jsonlite::fromJSON(con)
  })
  astronomy <- data.table::rbindlist(
    lapply(dfs, function(df) {
      count <<- count + 1
      station <- data.table::data.table(
        id = ids[count],
        station = df$astronomy$city[1],
        lng = df$astronomy$longitude[1],
        lat = df$astronomy$latitude[1],
        tz = df$astronomy$timezone[1],
        state = df$astronomy$state[1],
        country = df$astronomy$country[1]
      )
    })
  )
  astronomy$astronomy <- lapply(dfs, function(df) {
    ast <- df$astronomy$astronomy
    ast$date <- as.Date(.parse_datetime(ast$utcTime))
    ast$utcTime <- NULL
    ast
  })
  return(astronomy)
}

.extract_weather_alerts <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  dfs <- lapply(data, function(con) {
    jsonlite::fromJSON(con)
  })
  alerts <- data.table::rbindlist(
    lapply(dfs, function(df) {
      count <<- count + 1
      station <- data.table::data.table(
        id = ids[count],
        station = df$alerts$city[1],
        lng = df$alerts$longitude[1],
        lat = df$alerts$latitude[1],
        state = df$alerts$state[1],
        country = df$alerts$country[1]
      )
    })
  )
  alerts$alerts <- lapply(dfs, function(df) {
    df$alerts$alerts
  })
  return(alerts)
}

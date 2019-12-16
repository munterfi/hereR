#' HERE Destination Weather API: Observations, Forecast, Astronomy and Alerts
#'
#' Weather forecasts, reports on current weather conditions,
#' astronomical information and alerts at a specific location (coordinates or
#' location name) based on the 'Destination Weather' API.
#' The information comes from the nearest available weather station and is not interpolated.
#'
#' @references
#' \href{https://developer.here.com/documentation/weather/topics/example-weather-observation.html}{HERE Destination Weather API: Observation}
#'
#' @param poi \code{sf} object or character, Points of Interest (POIs) of geometry type \code{POINT} or location names (e.g. cities or regions).
#' @param product character, weather product of the 'Destination Weather API'. Supported products: \code{"observation"}, \code{"forecast_hourly"}, \code{"forecast_astronomy"} and \code{"alerts"}.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested weather information at the nearest weather station.
#' The point geometry in the \code{sf} object is the location of the weather station.
#' @export
#'
#' @examples
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' # Observation
#' observation <- weather(poi = poi, product = "observation", url_only = TRUE)
#'
#' # Forecast
#' forecast <- weather(poi = poi, product = "forecast_hourly", url_only = TRUE)
#'
#' # Astronomy
#' astronomy <- weather(poi = poi, product = "forecast_astronomy", url_only = TRUE)
#'
#' # Alerts
#' alerts <- weather(poi = poi, product = "alerts", url_only = TRUE)
weather <- function(poi, product = "observation", url_only = FALSE) {

  # Checks
  .check_weather_product(product)
  .check_boolean(url_only)

  # Add authentication
  url <- .add_auth(
    url = "https://weather.api.here.com/weather/1.0/report.json?"
  )

  # Add product
  url = paste0(
    url,
    "&product=",
    product
  )

  # Check and preprocess location
  # Character location
  if (is.character(poi)) {
    .check_addresses(poi)
    poi[poi == ""] = NA
    url = paste0(
      url,
      "&name=",
      poi
    )
  # sf POINTs
  } else if ("sf" %in% class(poi)) {
    .check_points(poi)
    poi <- sf::st_coordinates(
      sf::st_transform(poi, 4326)
    )
    poi <- paste0(
      "&longitude=", poi[, 1], "&latitude=", poi[, 2]
    )
    url = paste0(
      url,
      poi
    )
  # Not valid
  } else {
    stop("Invalid input for 'poi'.")
  }

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  if (product == "observation") {
    weather <- .extract_weather_observation(data)
  } else if (product == "forecast_hourly") {
    weather <- .extract_weather_forecast_hourly(data)
  } else if (product == "forecast_astronomy") {
    weather <- .extract_weather_forecast_astronomy(data)
  } else if (product == "alerts") {
    weather <- .extract_weather_alerts(data)
  }

  # Create sf, data.table, data.frame
  rownames(weather) <- NULL
  return(
    sf::st_set_crs(
      sf::st_as_sf(weather, coords = c("lng", "lat")),
    4326)
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
        timestamp = as.POSIXct(
          df$observations$location$observation[[1]]$utcTime,
          format = "%Y-%m-%dT%H:%M:%OS"),
        state = df$observations$location$state[1],
        country = df$observations$location$country[1])
      obs <- df$observations$location$observation[[1]]
      obs <- obs[, !names(obs) %in% c(
        "skyDescription", "airDescription", "precipitationDesc",
        "temperatureDesc", "iconName", "iconLink", "windDesc", "icon",
        "country", "state", "city", "latitude", "longitude", "distance",
        "utcTime", "elevation"), ]
      obs[, c(4:9, 16, 17, 19, 23, 24)] <-
        sapply(obs[, c(4:9, 16, 17, 19, 23, 24)], as.numeric)
      return(
        cbind(station, obs)
      )
    })
  )
  return(observation)
}

.extract_weather_forecast_hourly <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  dfs <- lapply(data, function(con) {jsonlite::fromJSON(con)})
  forecast <- data.table::rbindlist(
    lapply(dfs, function(df) {
      count <<- count + 1
      station <- data.table::data.table(
        id = ids[count],
        station = df$hourlyForecasts$forecastLocation$city[1],
        lng = df$hourlyForecasts$forecastLocation$longitude[1],
        lat = df$hourlyForecasts$forecastLocation$latitude[1],
        distance = df$hourlyForecasts$forecastLocation$distance[1] * 1000,
        state = df$hourlyForecasts$forecastLocation$state[1],
        country = df$hourlyForecasts$forecastLocation$country[1]
      )
    })
  )
  forecast$forecast <- lapply(dfs, function(df)
    {df$hourlyForecasts$forecastLocation$forecast})
  return(forecast)
}

.extract_weather_forecast_astronomy <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  dfs <- lapply(data, function(con) {jsonlite::fromJSON(con)})
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
    ast$date <- as.Date(as.POSIXct(ast$utcTime, tz = "UTC"))
    ast$utcTime <- NULL
    ast
    }
  )
  return(astronomy)
}

.extract_weather_alerts <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  dfs <- lapply(data, function(con) {jsonlite::fromJSON(con)})
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
  alerts$alerts <- lapply(dfs, function(df)
    {df$alerts$alerts})
  return(alerts)
}

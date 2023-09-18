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
#' forecast <- weather(poi = poi, product = "forecast_hourly", url_only = TRUE)
#'
#' # Astronomy
#' astronomy <- weather(poi = poi, product = "forecast_astronomy", url_only = TRUE)
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
  product <- .check_weather_product(product)
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
  count <- 0
  observations <- data.table::rbindlist(
    lapply(data, function(res) {
      count <<- count + 1
      df <- jsonlite::fromJSON(res)
      data.table::rbindlist(
        lapply(df$places$observations, function(result) {
          res <- .parse_weather_results(result)
          cbind(.parse_locations(result, count, nrow(res)), res)
        }),
        fill = TRUE
      )
    }),
    fill = TRUE
  )
  return(observations)
}

.extract_weather_forecast_hourly <- function(data) {
  count <- 0
  forecasts <- list()
  forecast <- data.table::rbindlist(
    lapply(data, function(res) {
      count <<- count + 1
      df <- jsonlite::fromJSON(res)
      data.table::rbindlist(lapply(df$places$hourlyForecast, function(result) {
        forecasts <<- append(forecasts, lapply(result$forecasts, .parse_weather_results))
        .parse_locations(result, count, 1)
      }), fill = TRUE)
    }),
    fill = TRUE
  )
  forecast <- cbind(forecast, forecasts)
  return(forecast)
}

.extract_weather_forecast_astronomy <- function(data) {
  count <- 0
  forecasts <- list()
  forecast <- data.table::rbindlist(
    lapply(data, function(res) {
      count <<- count + 1
      df <- jsonlite::fromJSON(res)
      data.table::rbindlist(lapply(df$places$astronomyForecasts, function(result) {
        forecasts <<- append(forecasts, lapply(result$forecasts, .parse_astronomy_results))
        .parse_locations(result, count, 1)
      }), fill = TRUE)
    }),
    fill = TRUE
  )
  forecast <- cbind(forecast, forecasts)
  return(forecast)
}

.extract_weather_alerts <- function(data) {
  count <- 0
  alerts <- list()
  locations <- data.table::rbindlist(
    lapply(data, function(res) {
      count <<- count + 1
      df <- jsonlite::fromJSON(res)
      data.table::rbindlist(lapply(df$places$alerts, function(result) {
        alerts <<- append(alerts, list(.parse_alert_results(result)))
        .parse_locations(result, count, 1)
      }), fill = TRUE)
    }),
    fill = TRUE
  )
  return(cbind(locations, alerts))
}

.parse_locations <- function(df, req_id, max_rank_id) {
  return(data.table::data.table(
    id = req_id,
    rank = seq_len(max_rank_id),
    country_code = df$place$address$countryCode,
    country = df$place$address$countryName,
    state = df$place$address$state,
    city = df$place$address$city,
    distance = df$place$distance,
    lng = df$place$location$lng,
    lat = df$place$location$lat
  ))
}

.parse_weather_results <- function(df) {
  return(
    data.table::data.table(
      time = .parse_datetime_tz(df$time),
      daylight = df$daylight,
      description = df$description,
      sky_info = df$skyInfo,
      sky_desc = df$skyDesc,
      temperature = df$temperature,
      temperature_desc = df$temperatureDesc,
      comfort = df$comfort,
      high_temperature = .format_na_values(df$highTemperature),
      low_temperature = .format_na_values(df$lowTemperature),
      humidity = .format_na_values(df$humidity),
      dew_point = df$dewPoint,
      precipitation_probability = df$precipitationProbability,
      rain_fall = df$rainFall,
      wind_speed = df$windSpeed,
      wind_direction = df$windDirection,
      wind_descr = df$windDesc,
      wind_descr_short = df$windDescShort,
      uv_index = df$uvIndex,
      uv_descr = df$uvDesc,
      barometer_pressure = df$barometerPressure,
      barometer_trend = df$barometerTrend,
      age_minutes = df$ageMinutes,
      active_alerts = df$activeAlerts
    )
  )
}

.parse_astronomy_results <- function(df) {
  return(
    data.table::data.table(
      time = .parse_datetime_tz(df$time),
      sun_rise = df$sunRise,
      sun_set = df$sunSet,
      moon_rise = df$moonRise,
      moon_set = df$moonSet,
      moon_phase = df$moonPhase,
      moon_phase_description = df$moonPhaseDescription
    )
  )
}

.parse_alert_results <- function(df) {
  template <- data.table::data.table(
    time_segments = list(),
    type = numeric(),
    descriction = character()
  )
  return(
    rbind(
      template,
      data.table::data.table(
        time_segments = df$timeSegments,
        type = ifelse(is.null(df$type), NA, df$type),
        descriction = ifelse(is.null(df$description), NA, df$description)
      )
    )
  )
}

.format_na_values <- function(col) {
  if (is.null(col)) {
    return(NULL)
  }
  as.numeric(gsub("\\*", "", col))
}

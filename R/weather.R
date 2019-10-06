#' HERE Destination Weather API: Observation, Forecast or Astronomy
#'
#' Current weather conditions at Points of Interest (location or address).
#'
#' @references
#' \href{https://developer.here.com/documentation/weather/topics/example-weather-observation.html}{HERE Destination Weather API: Observation }
#'
#' @param poi
#' @param product
#'
#' @return
#' An sf object, containing the coordinates of the geocoded addresses.
#' @export
#'
#' @examples
weather <- function(poi, product = "observation", url_only = FALSE) {

  # Add authentification
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
    stop("Invalid input for 'poi'")
  }

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )

  # Extract information
  weather <- data.table::rbindlist(
    lapply(data, function(con) {
      df <- jsonlite::fromJSON(con)
      station <- data.table::data.table(
        station = df$observations$location$city[1],
        lng = df$observations$location$longitude[1],
        lat = df$observations$location$latitude[1],
        distance = df$observations$location$distance[1] * 1000,
        timestamp = df$observations$location$observation[[1]]$utcTime,
        state = df$observations$location$state[1],
        country = df$observations$location$country[1])
      obs <- df$observations$location$observation[[1]]
      obs <- obs[, !names(obs) %in% c(
        "skyDescription", "airDescription", "precipitationDesc",
        "temperatureDesc", "iconName", "iconLink", "windDesc", "icon",
        "country", "state", "city", "latitude", "longitude", "distance",
        "utcTime", "elevation"), ]
      return(
        cbind(station, obs)
      )
    })
  )

  # Create sf, data.table, data.frame
  return(
    sf::st_set_crs(
      sf::st_as_sf(weather, coords = c("lng", "lat")),
    4326)
  )
}

#' HERE Public Transit API: Find Stations Nearby
#'
#' Retrieve stations with the corresponding line information around given locations using the HERE 'Public Transit' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/public-transit/dev_guide/station-search/index.html}{HERE Public Transit API: Station Search}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param radius numeric, the search radius in meters (\code{default = 500}).
#' @param results numeric, maximum number of suggested public transport stations (Valid range: 1 and 50, \code{default = 50}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested stations with the corresponding line information.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Stations
#' stations <- station(poi = poi, url_only = TRUE)
station <- function(poi, radius = 500, results = 50, url_only = FALSE) {
  # Checks
  .check_points(poi)
  .check_numeric_range(radius, 1, Inf)
  .check_numeric_range(results, 1, 50)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://transit.hereapi.com/v8/stations?"
  )

  # CRS transformation and formatting
  center <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  url <- paste0(
    url,
    "&in=",
    center[, 2], ",", center[, 1], ";r=", radius
  )

  # Number of results
  url <- paste0(
    url,
    "&maxPlaces=",
    results
  )

  # Add station attributes
  url <- paste0(
    url,
    "&return=transport"
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .async_request(
    url = url,
    rps = 10
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  stations <- .extract_stations(data)

  # Checks success
  if (is.null(stations)) {
    message("No public transport stations found.")
    return(NULL)
  }

  # Create sf, data.frame
  rownames(stations) <- NULL
  return(
    sf::st_set_crs(
      sf::st_as_sf(
        as.data.frame(stations),
        coords = c("lng", "lat")
      ), 4326
    )
  )
}

.extract_stations <- function(data) {
  ids <- .get_ids(data)
  count <- 0

  # Stations
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    station = character(),
    modes = list(),
    lines = list(),
    lng = numeric(),
    lat = numeric()
  )
  stations <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(res) {
        count <<- count + 1
        df <- jsonlite::fromJSON(res)
        if (length(df$stations) < 1) {
          return(NULL)
        }
        data.table::data.table(
          id = ids[count],
          rank = seq(1, nrow(df$stations)),
          station = df$stations$place$name,
          modes = lapply(
            df$stations$transports,
            function(x) unique(as.character(x$mode))
          ),
          lines = lapply(
            df$stations$transports,
            function(x) unique(as.character(x$name))
          ),
          lng = df$station$place$location$lng,
          lat = df$station$place$location$lat
        )
      })
    ),
    fill = TRUE
  )

  # Check success, postprocess and return
  if (nrow(stations) < 1) {
    return(NULL)
  }
  modes <- lines <- NULL
  stations[, c("modes", "lines") := list(
    vapply(modes, paste, collapse = ", ", character(1)),
    vapply(lines, paste, collapse = ", ", character(1))
  )]
  return(stations)
}

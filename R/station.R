#' HERE Public Transit API: Find Stations Nearby
#'
#' Retrieve stations with the corresponding line information around given locations using the HERE 'Public Transit' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/examples/rest/public_transit/station-search-proximity}{HERE Public Transit API: Find Stations Nearby}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param radius numeric, the search radius in meters (\code{default = 500}).
#' @param results numeric, maximum number of suggested public transport stations (Valid range: 1 and 50, \code{default = 5}).
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
station <- function(poi, radius = 500, results = 5, url_only = FALSE) {

  # Checks
  .check_points(poi)
  .check_numeric_range(radius, 1, Inf)
  .check_numeric_range(results, 1, 50)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://transit.ls.hereapi.com/v3/stations/by_geocoord.json?"
  )

  # CRS transformation and formatting
  center <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  url <- paste0(
    url,
    "&center=",
    center[, 2], ",", center[, 1]
  )

  # Add radius
  url <- paste0(
    url,
    "&radius=",
    radius
  )

  # Number of results
  url <- paste0(
    url,
    "&max=",
    results
  )

  # Add station attributes
  url = paste0(
    url,
    "&details=1"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  ids <- .get_ids(data)
  count <- 0
  stations <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      rank <- 0
      df <- jsonlite::fromJSON(con)
      if (is.null(df$Res$Stations$Stn)) {return(NULL)}
      data.table::data.table(
        id = ids[count],
        rank = seq(1, nrow(df$Res$Stations$Stn)),
        station = df$Res$Stations$Stn$name,
        distance = df$Res$Stations$Stn$distance,
        lines = lapply(df$Res$Stations$Stn$Transports$Transport, function(x)
          unique(as.character(x$name))),
        lng = df$Res$Stations$Stn$x,
        lat = df$Res$Stations$Stn$y
      )
    }),
  fill = TRUE)

  # Check success
  if (nrow(stations) < 1) {
    message("No public transport stations found.")
    return(NULL)
  }

  # Create sf, data.table, data.frame
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


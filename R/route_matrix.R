#' HERE Routing API: Calculate Matrix
#'
#' Calculates a matrix of M:N, M:1 or 1:N route summaries between given points of interest (POIs) using the HERE 'Routing' API.
#' Various transport modes and traffic information at a provided timestamp are supported.
#' The requested matrix is split into (sub-)matrices of dimension 15x100 to use the
#' maximum matrix size per request and thereby minimize the number of overall needed requests.
#' The result is one route summary matrix, that fits the order of the provided POIs: \code{origIndex}, \code{destIndex}.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-matrix.html}{HERE Routing API: Calculate Matrix}
#'
#' @param origin \code{sf} object, the origin locations (M) of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations (N) of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure.
#' @param type character, set the routing type: \code{"fastest"}, \code{"shortest"} or \code{"balanced"}.
#' @param mode character, set the transport mode: \code{"car"}, \code{"pedestrian"}, \code{"carHOV"} or \code{"truck"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = FALSE})? If no \code{datetime} is set, the current timestamp at the moment of the request is used for \code{datetime}.
#' @param search_range numeric, value in meters to limit the search radius in the route generation (\code{default = 99999999}).
#' @param attribute character, attributes to be calculated on the routes: \code{"distance"} or \code{"traveltime"} (\code{default = c("distance", "traveltime")}.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' A \code{data.frame}, which is an edge list containing the requested M:N route combinations.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Create routes summaries between all POIs
#' mat <- route_matrix(
#'   origin = poi,
#'   traffic = TRUE,
#'   url_only = TRUE
#' )
route_matrix <- function(origin, destination = origin, datetime = Sys.time(),
                         type = "fastest", mode = "car", traffic = FALSE,
                         search_range = 99999999, attribute = c("distance", "traveltime"),
                         url_only = FALSE) {
  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_datetime(datetime)
  .check_attributes(attribute)
  .check_type(type = type, request = "calculatematrix")
  .check_mode(mode = mode, request = "calculatematrix")
  .check_boolean(traffic)
  .check_boolean(url_only)

  # CRS transformation and formatting
  origin <- sf::st_coordinates(
    sf::st_transform(origin, 4326)
  )
  origin <- paste0(
    "geo!", origin[, 2], ",", origin[, 1]
  )
  destination <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  destination <- paste0(
    "geo!", destination[, 2], ",", destination[, 1]
  )

  # Add API key
  url <- .add_key(
    url = "https://matrix.route.ls.hereapi.com/routing/7.2/calculatematrix.json?"
  )

  # Switch coordinates to use max request size of 15x100
  if (length(origin) > length(destination)) {
    switch <- TRUE
    origin_tmp <- origin
    origin <- destination
    destination <- origin_tmp
  } else {
    switch <- FALSE
  }

  # Create batches, indices and format coordinates
  batch_size_origin <- 15
  batch_size_dest <- 100
  orig_div <- seq(0, length(origin) - 1, batch_size_origin)
  dest_div <- seq(0, length(destination) - 1, batch_size_dest)
  orig_idx <- list()
  dest_idx <- list()
  coords <- as.character(sapply(X = orig_div, FUN = function(i) {
    origin_batch <- origin[(i + 1):(i + batch_size_origin)]
    origin_batch <- origin_batch[!is.na(origin_batch)]
    sapply(X = dest_div, FUN = function(j) {
      dest_batch <- destination[(j + 1):(j + batch_size_dest)]
      dest_batch <- dest_batch[!is.na(dest_batch)]
      orig_idx <<- append(orig_idx, list(seq(0 + i, length(origin_batch) - 1 + i, 1)))
      dest_idx <<- append(dest_idx, list(seq(0 + j, length(dest_batch) - 1 + j, 1)))
      return(paste0("&",
                    paste0("start",
                           seq(0, length(origin_batch) - 1, 1), "=",
                           origin_batch,
                           collapse = "&"), "&",
                    paste0("destination",
                           seq(0, length(dest_batch) - 1, 1), "=",
                           dest_batch,
                           collapse = "&")
      ))
    })
  }))

  # Add origin coords
  url = paste0(
    url,
    coords
  )

  # Add mode
  url = .add_mode(
    url = url,
    type = type,
    mode = mode,
    traffic = traffic
  )

  # Add search range
  url = paste0(
    url,
    "&searchRange=",
    search_range
  )

  # Add departure time
  url <- .add_datetime(
    url,
    datetime,
    "departure"
  )

  # Add summaryAttributes
  url = paste0(
    url,
    "&summaryAttributes=",
    paste0(attribute, collapse = ",")
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  count <- 1
  routes <- data.table::rbindlist(
    lapply(data, function(con) {
      df <- jsonlite::fromJSON(con)$response$matrixEntry
      # Retrieve original indices
      df$origIndex <- orig_idx[[count]][df$startIndex + 1] + 1
      df$destIndex <- dest_idx[[count]][df$destinationIndex + 1] + 1
      count <<- count + 1
      # Flatten columns
      cbind(df[, c("origIndex", "destIndex")], df$summary)
    })
  )

  # Switch back indices
  if (switch) {
    tmp <- routes$origIndex
    routes$origIndex <- routes$destIndex
    routes$destIndex <- tmp
  }

  # Add departure and arrival
  routes$departure <- datetime
  routes$arrival <- datetime + routes$travelTime
  routes <- routes[, c("origIndex", "destIndex", "departure", "arrival",
                       "distance", "travelTime", "costFactor")]

  # Reorder
  routes <- routes[order(routes$origIndex,
                         routes$destIndex), ]
  rownames(routes) <- NULL
  return(as.data.frame(routes))
}

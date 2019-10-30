#' HERE Routing API: Route Matrix
#'
#' Calculates a matrix of route summaries between given points of interest (POIs).
#' Various transport modes and traffic information at a provided timestamp are supported.
#' The requested matrix is split into (sub-)matrices of dimension 15x100 to use the
#' maximum matrix size per request and thereby minimize the number of overall needed requests.
#' The result is one route summary matrix, that fits the order of the provided POIs: \code{startIndex}, \code{destinationIndex}.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-matrix.html}{HERE Routing API: Calculate Matrix}
#'
#' @param start \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the start locations.
#' @param destination \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the destination locations.
#' @param type character, set the routing type: \code{"fastest"}, \code{"shortest"} or \code{"balanced"}.
#' @param mode character, set the transport mode: \code{"car"}, \code{"pedestrian"}, \code{"carHOV"} or \code{"truck"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = FALSE})? If no \code{departure} date and time is set, the current timestamp at the moment of the request is used for \code{departure}.
#' @param searchRange numeric, value in meters to limit the search radius in the route generation (\code{default = 99999999}).
#' @param attribute character, attributes to be calculated on the routes: \code{"distance"} or \code{"traveltime"} (\code{default = c("distance", "traveltime")}.
#' @param departure datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the departure.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' A \code{data.table} containing the requested route matrix data.
#' @export
#'
#' @examples
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' # Create routes summaries between all POIs
#' mat <- route_matrix(
#'   start = poi,
#'   departure = as.POSIXct("2019-10-10 15:45:00"),
#'   traffic = TRUE,
#'   url_only = TRUE
#' )
route_matrix <- function(start, destination = start, type = "fastest", mode = "car",
                         traffic = FALSE, searchRange = 99999999,
                         attribute = c("distance", "traveltime"),
                         departure = NULL, url_only = FALSE) {
  # Checks
  .check_points(start)
  .check_points(destination)
  .check_datetime(departure)
  .check_attributes(attribute)
  .check_type(type = type, request = "calculatematrix")
  .check_mode(mode = mode, request = "calculatematrix")

  # CRS transformation and formatting
  start <- sf::st_coordinates(
    sf::st_transform(start, 4326)
  )
  start <- paste0(
    "geo!", start[, 2], ",", start[, 1]
  )
  destination <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  destination <- paste0(
    "geo!", destination[, 2], ",", destination[, 1]
  )

  # Add authentification
  url <- .add_auth(
    url = "https://matrix.route.api.here.com/routing/7.2/calculatematrix.json?"
  )

  # Switch coordinates to use max request size of 15x100
  if (length(start) > length(destination)) {
    switch <- TRUE
    start_tmp <- start
    start <- destination
    destination <- start_tmp
  } else {
    switch <- FALSE
  }

  # Create batches, indices and format coordinates
  batch_size_start <- 15
  batch_size_dest <- 100
  start_div <- seq(0, length(start), batch_size_start)
  dest_div <- seq(0, length(destination), batch_size_dest)
  start_idx <- list()
  dest_idx <- list()

  coords <- sapply(X = start_div, FUN = function(i) {
    start_batch <- start[(i + 1):(i + batch_size_start)]
    start_batch <- start_batch[!is.na(start_batch)]
    for (j in dest_div) {
      dest_batch <- destination[(j + 1):(j + batch_size_dest)]
      dest_batch <- dest_batch[!is.na(dest_batch)]
      start_idx <<- append(start_idx, list(seq(0 + i, length(start_batch) - 1 + i, 1)))
      dest_idx <<- append(dest_idx, list(seq(0 + j, length(dest_batch) - 1 + j, 1)))
      return(paste0("&",
             paste0("start",
                    seq(0, length(start_batch) - 1, 1), "=",
                    start_batch,
                    collapse = "&"), "&",
             paste0("destination",
                    seq(0, length(dest_batch) - 1, 1), "=",
                    dest_batch,
                    collapse = "&")
      ))
    }
  })

  # Add start coords
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

  # Add searchRange
  url = paste0(
    url,
    "&searchRange=",
    searchRange
  )

  # Add departure time
  url <- .add_datetime(
    url,
    departure,
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
      df$startIndex <- start_idx[[count]][df$startIndex + 1] + 1
      df$destinationIndex <- dest_idx[[count]][df$destinationIndex + 1] + 1
      count <<- count + 1
      # Flatten columns
      cbind(df[, 1:2], df$summary)
    })
  )

  # Switch back indices
  if (switch) {
    tmp <- routes$startIndex
    routes$startIndex <- routes$destinationIndex
    routes$destinationIndex <- tmp
  }

  # Reorder
  routes <- routes[order(routes$startIndex,
                         routes$destinationIndex), ]
  return(routes)
}

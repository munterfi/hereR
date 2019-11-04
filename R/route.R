#' HERE Routing API: Route
#'
#' Calculates route geometries (\code{LINESTRING}) between given pairs of points using the 'Routing' API.
#' Routes can be created for various transport modes, as for example 'car' or 'public transport',
#' incorporating current traffic information, if available.
#' For routes using the transport mode \code{"car"} a vehicle type can be specified,
#' to obtain an estimate of the consumption.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-route.html}{HERE Routing API: Calculate Route}
#'
#' @param start \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the start locations.
#' @param destination \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the destination locations.
#' @param type character, set the routing type: \code{"fastest"}, \code{"shortest"} or \code{"balanced"}.
#' @param mode character, set the transport mode: \code{"car"}, \code{"pedestrian"}, \code{"carHOV"}, \code{"publicTransport"}, \code{"publicTransportTimeTable"}, \code{"truck"} or \code{"bicycle"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = FALSE})? If no \code{departure} or \code{arrival} date and time is set, the current timestamp at the moment of the request is used for \code{departure}.
#' @param vehicle_type character, specify the motor type of the vehicle: \code{"diesel"}, \code{"gasoline"} or \code{"electric"}. And set the consumption per 100km im liters (\code{default = "diesel,5.5"}).
#' @param departure datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the departure.
#' @param arrival datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the arrival. Only specify a departure or an arrival.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested routes.
#' @export
#'
#' @examples
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' # Get all from - to combinations from POIs
#' library(sf)
#' to <- poi[rep(seq_len(nrow(poi)), nrow(poi)), ]
#' from <- poi[rep(seq_len(nrow(poi)), each = nrow(poi)),]
#' idx <- apply(to != from, any, MARGIN = 1)
#' to <- to[idx, ]
#' from <- from[idx, ]
#'
#' # Routing
#' routes <- route(
#'   start = from, destination = to,
#'   mode = "car", type = "fastest", traffic = TRUE,
#'   vehicle_type = "diesel,5.5",
#'   url_only = TRUE
#' )
route <- function(start, destination,
                  type = "fastest", mode = "car", traffic = FALSE,
                  vehicle_type = "diesel,5.5",
                  departure = NULL, arrival = NULL,
                  url_only = FALSE) {
  # Checks
  .check_points(start)
  .check_points(destination)
  .check_datetime(departure)
  .check_datetime(arrival)
  .check_type(type, request = "calculateroute")
  .check_mode(mode, request = "calculateroute")
  .check_vehicle_type(vehicle_type)

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
    url = "https://route.api.here.com/routing/7.2/calculateroute.json?"
  )

  # Add waypoints
  url = paste0(
    url,
    "&waypoint0=",
    start,
    "&waypoint1=",
    destination
  )

  # Add mode
  url = .add_mode(
    url = url,
    type = type,
    mode = mode,
    traffic = traffic
  )

  # Add departure or arrival time
  if (is.null(arrival)) {
    url <- .add_datetime(
      url,
      departure,
      "departure"
    )
  } else {
    url <- .add_datetime(
      url,
      arrival,
      "arrival"
    )
  }

  # Add vehicle type
  url = paste0(
    url,
    "&vehicleType=",
    vehicle_type
  )

  # Add consumption model
  url = paste0(
    url,
    "&consumptionmodel=default"
  )

  # Add route attributes
  url = paste0(
    url,
    "&routeAttributes=routeId,summary,shape,lines,tickets"
  )

  # Add alternatives
  url = paste0(
    url,
    "&alternatives=0"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  routes <- sf::st_as_sf(
    data.table::rbindlist(
      lapply(data, function(con) {
        df <- jsonlite::fromJSON(con)
        # Get summary
        summary <- df$response$route$summary
        summary <- summary[, !names(summary) %in% c("flags", "text", "_type"),
                           drop = FALSE]
        # Build sf object
        sf::st_as_sf(
          data.table::data.table(
            cbind(
              fromLabel = utils::head(df$response$route$waypoint, 1)[[1]]$label[1],
              toLabel = utils::tail(df$response$route$waypoint, 1)[[1]]$label[2],
              mode = paste(Reduce(c, df$response$route$mode$transportModes),
                           collapse = ", "),
              traffic = df$response$route$mode$trafficMode,
              summary
            )
          ),
          geometry = sf::st_sfc(
            .line_from_pointList(
              Reduce(c, df$response$route$shape)
            ), crs = 4326
          )
        )
      })
    )
  )
  return(routes)
}

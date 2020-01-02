#' HERE Routing API: Calculate Route
#'
#' Calculates route geometries (\code{LINESTRING}) between given pairs of points using the HERE 'Routing' API.
#' Routes can be created for various transport modes, as for example 'car' or 'public transport',
#' incorporating current traffic information, if available.
#' For routes using the transport mode \code{"car"} a vehicle type can be specified,
#' to obtain an estimate of the consumption.
#'
#' @note The public transport routes (\code{mode = "publicTransport"}) provided by \code{\link{route}}
#' are not considering the time tables of the public transport providers.
#' Use \code{\link{connection}} for public transport routes that consider time tables.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-route.html}{HERE Routing API: Calculate Route}
#'
#' @param origin \code{sf} object, the origin locations of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, calculate routes for arrival at the defined time (\code{default = FALSE})?
#' @param type character, set the routing type: \code{"fastest"}, \code{"shortest"} or \code{"balanced"}.
#' @param mode character, set the transport mode: \code{"car"}, \code{"pedestrian"}, \code{"carHOV"}, \code{"publicTransport"}, \code{"truck"} or \code{"bicycle"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = FALSE})? If no \code{datetime} is set, the current timestamp at the moment of the request is used for \code{datetime}.
#' @param vehicle_type character, specify the motor type of the vehicle: \code{"diesel"}, \code{"gasoline"} or \code{"electric"}. And set the consumption per 100km im liters (\code{default = "diesel,5.5"}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested routes.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Get all from - to combinations from POIs
#' to <- poi[rep(seq_len(nrow(poi)), nrow(poi)), ]
#' from <- poi[rep(seq_len(nrow(poi)), each = nrow(poi)),]
#' idx <- apply(to != from, any, MARGIN = 1)
#' to <- to[idx, ]
#' from <- from[idx, ]
#'
#' # Routing
#' routes <- route(
#'   origin = from, destination = to,
#'   mode = "car", type = "fastest", traffic = TRUE,
#'   vehicle_type = "diesel,5.5",
#'   url_only = TRUE
#' )
route <- function(origin, destination, datetime = Sys.time(), arrival = FALSE,
                  type = "fastest", mode = "car", traffic = FALSE,
                  vehicle_type = "diesel,5.5", url_only = FALSE) {
  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_datetime(datetime)
  .check_boolean(arrival)
  .check_type(type, request = "calculateroute")
  .check_mode(mode, request = "calculateroute")
  .check_vehicle_type(vehicle_type)
  .check_boolean(traffic)
  .check_boolean(url_only)

  # Note: Link to 'connection()'
  if (mode == "publicTransport")
    message("Note: Use 'connection()' for public transport routes that consider time tables.")

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
    url = "https://route.ls.hereapi.com/routing/7.2/calculateroute.json?"
  )

  # Add waypoints
  url = paste0(
    url,
    "&waypoint0=",
    origin,
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
  if (arrival) {
    url <- .add_datetime(
      url,
      datetime,
      "arrival"
    )
  } else {
    url <- .add_datetime(
      url,
      datetime,
      "departure"
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
  ids <- .get_ids(data)
  count <- 0
  routes <- sf::st_as_sf(
    as.data.frame(data.table::rbindlist(
      lapply(data, function(con) {
        count <<- count + 1
        df <- jsonlite::fromJSON(con)

        # Get summary
        summary <- df$response$route$summary
        summary <- summary[, !names(summary) %in% c("flags", "text", "_type"),
                           drop = FALSE]

        # Build sf object
        sf::st_as_sf(
          data.table::data.table(
            cbind(
              id = ids[count],
              departure = if(arrival) (datetime - summary$travelTime) else datetime,
              origin = utils::head(df$response$route$waypoint, 1)[[1]]$label[1],
              arrival = if(arrival) (datetime) else (datetime + summary$travelTime),
              destination = utils::tail(df$response$route$waypoint, 1)[[1]]$label[2],
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
    ))
  )
  rownames(routes) <- NULL
  return(routes)
}

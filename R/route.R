#' HERE Routing API: Route
#'
#' Calcualtes a route between two points.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-route.html}{HERE Routing API: Calculate Route}
#'
#' @param start
#' @param destination
#' @param type
#' @param mode
#' @param traffic
#' @param vehicle_type
#' @param departure
#' @param arrival
#'
#' @return
#' @export
#'
#' @examples
route <- function(start, destination,
                  type = "fastest", mode = "car", traffic = FALSE,
                  vehicle_type = "diesel,5.5", departure = NULL, arrival = NULL) {
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
    url <- .add_departure(
      url,
      departure
    )
  } else {
    url <- .add_arrival(
      url,
      arrival
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

  # Request and get content
  data <- .get_content(
    url = url
  )

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
              fromLabel = head(df$response$route$waypoint, 1)[[1]]$label[1],
              toLabel = tail(df$response$route$waypoint, 1)[[1]]$label[2],
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

.line_from_pointList <- function(pointList) {
  coords <- strsplit(pointList, ",")
  lng <- as.numeric(sapply(coords, function(x) x[2]))
  lat <- as.numeric(sapply(coords, function(x) x[1]))
  sf::st_linestring(cbind(lng, lat))
}

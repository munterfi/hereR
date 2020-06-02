#' HERE Intermodal Routing API: Calculate Route
#'
#' Calculates route geometries (\code{LINESTRING}) between given pairs of points using the HERE 'Intermodal Routing' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/intermodal-routing/dev_guide/index.html}{HERE Intermodal Routing API: Routes}
#'
#' @param origin \code{sf} object, the origin locations of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure (\code{default = Sys.time()}).
#' @param results numeric, maximum number of suggested route alternatives (Valid range: 1 and 7, \code{default = 1}).
#' @param transfers numeric, maximum number of transfers allowed per route (Valid range: -1 and 6, \code{default = -1}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested intermodal routes.
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
#' routes <- intermodal_route(
#'   origin = from, destination = to,
#'   url_only = TRUE
#' )
intermodal_route <- function(origin, destination, datetime = Sys.time(),
                             results = 1, transfers = -1, url_only = FALSE) {
  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_datetime(datetime)
  .check_numeric_range(results, 1, 7)
  .check_numeric_range(transfers, -1, 6)
  .check_boolean(url_only)

  # CRS transformation and formatting
  origin <- sf::st_coordinates(
    sf::st_transform(origin, 4326)
  )
  origin <- paste0(
    origin[, 2], ",", origin[, 1]
  )
  destination <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  destination <- paste0(
    destination[, 2], ",", destination[, 1]
  )

  # Add API key
  url <- .add_key(
    url = "https://intermodal.router.hereapi.com/v8/routes?"
  )

  # Add origin and destination
  url = paste0(
    url,
    "&origin=",
    origin,
    "&destination=",
    destination
  )

  # # Add mode
  # url = .add_mode(
  #   url = url,
  #   type = type,
  #   mode = mode,
  #   traffic = traffic
  # )

  # Add departure time (arrival time is not supported)
  url <- .add_datetime(
    url,
    datetime,
    "departureTime"
  )

  # Add alternatives (results minus 1)
  url = paste0(
    url,
    "&alternatives=",
    results - 1
  )

  # Number of transfers
  if (transfers > -1) {
    url <- paste0(
      url,
      "&changes=",
      transfers
    )
  }

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # STOP AS NOT YET ADJUSTED ...
  return(NULL)

  # # Extract information
  # ids <- .get_ids(data)
  # count <- 0
  # routes <- sf::st_as_sf(
  #   as.data.frame(data.table::rbindlist(
  #     lapply(data, function(con) {
  #       count <<- count + 1
  #       df <- jsonlite::fromJSON(con)
  #
  #       # Get summary
  #       summary <- df$response$route$summary
  #       summary <- summary[, !names(summary) %in% c("flags", "text", "_type"),
  #                          drop = FALSE]
  #
  #       # Build sf object
  #       sf::st_as_sf(
  #         data.table::data.table(
  #           cbind(
  #             id = ids[count],
  #             departure = if(arrival) (datetime - summary$travelTime) else datetime,
  #             origin = utils::head(df$response$route$waypoint, 1)[[1]]$label[1],
  #             arrival = if(arrival) (datetime) else (datetime + summary$travelTime),
  #             destination = utils::tail(df$response$route$waypoint, 1)[[1]]$label[2],
  #             mode = paste(Reduce(c, df$response$route$mode$transportModes),
  #                          collapse = ", "),
  #             traffic = df$response$route$mode$trafficMode,
  #             summary
  #           )
  #         ),
  #         geometry = sf::st_sfc(
  #           .line_from_pointList(
  #             Reduce(c, df$response$route$shape)
  #           ), crs = 4326
  #         )
  #       )
  #     })
  #   ))
  # )
  # rownames(routes) <- NULL
  # return(routes)
}

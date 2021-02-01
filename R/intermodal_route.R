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
#' @param results numeric, maximum number of suggested route alternatives (Valid range: 1 and 7, \code{default = 3}).
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
#' # Intermodal routing
#' routes <- intermodal_route(
#'   origin = poi[1:3, ],
#'   destination = poi[4:6, ],
#'   url_only = TRUE
#' )
intermodal_route <- function(origin, destination, datetime = Sys.time(),
                             results = 3, transfers = -1, url_only = FALSE) {
  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_input_rows(origin, destination)
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
  url <- paste0(
    url,
    "&origin=",
    origin,
    "&destination=",
    destination
  )

  # Add departure time (arrival time is not supported)
  url <- .add_datetime(
    url,
    datetime,
    "departureTime"
  )

  # Add alternatives (results minus 1)
  url <- paste0(
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

  # Request polyline and summary
  url <- paste0(
    url,
    "&return=",
    "polyline,travelSummary"
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  routes <- .extract_intermodal_routes(data)

  # Checks success
  if (is.null(routes)) {
    message("No intermodal routes found.")
    return(NULL)
  }

  # Postprocess
  routes <- routes[routes$rank <= results, ]
  routes$departure <- .parse_datetime_tz(routes$departure, tz = attr(datetime, "tzone"))
  routes$arrival <- .parse_datetime_tz(routes$arrival, tz = attr(datetime, "tzone"))
  rownames(routes) <- NULL

  # Bug of data.table and sf combination? Drops sfc class, when only one row...
  routes <- as.data.frame(routes)
  routes$geometry <- sf::st_sfc(routes$geometry, crs = 4326)

  # Create sf object
  return(
    sf::st_as_sf(
      routes,
      sf_column_name = "geometry",
      crs = 4326
    )
  )
}

.extract_intermodal_routes <- function(data) {
  ids <- .get_ids(data)
  count <- 0

  # Routes
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    section = numeric(),
    departure = character(),
    origin = character(),
    arrival = character(),
    destination = character(),
    type = character(),
    mode = character(),
    vehicle = character(),
    provider = character(),
    direction = character(),
    distance = integer(),
    duration = integer(),
    geometry = character()
  )
  routes <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(con) {
        count <<- count + 1

        # Parse JSON
        df <- jsonlite::fromJSON(con)
        if (is.null(df$routes$sections)) {
          return(NULL)
        }

        # Connections
        rank <- 0
        routes <- data.table::data.table(
          id = ids[count],

          # Segments
          data.table::rbindlist(
            lapply(df$routes$sections, function(sec) {
              rank <<- rank + 1
              data.table::data.table(
                rank = rank,
                section = seq_len(nrow(sec)),
                departure = sec$departure$time,
                origin = c("ORIG", sec$departure$place$name[2:length(sec$departure$place$name)]),
                arrival = sec$arrival$time,
                destination = c(sec$arrival$place$name[1:(length(sec$arrival$place$name) - 1)], "DEST"),
                type = sec$type,
                mode = sec$transport$mode,
                vehicle = if (is.null(sec$transport$name)) {
                  NA
                } else {
                  sec$transport$name
                },
                provider = if (is.null(sec$agency$name)) {
                  NA
                } else {
                  sec$agency$name
                },
                direction = if (is.null(sec$transport$headsign)) {
                  NA
                } else {
                  sec$transport$headsign
                },
                distance = sec$travelSummary$length,
                duration = sec$travelSummary$duration,
                geometry = sec$polyline
              )
            }),
            fill = TRUE
          )
        )
      })
    ),
    fill = TRUE
  )

  # Check success
  if (nrow(routes) < 1) {
    return(NULL)
  }

  # Decode flexible polyline encoding to LINESTRING
  routes$geometry <- sf::st_geometry(
    flexpolyline::decode_sf(
      routes$geometry, 4326
    )
  )

  return(routes)
}

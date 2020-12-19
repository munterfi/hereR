#' HERE Public Transit API: Transit Route
#'
#' Route public transport connections with geometries (\code{LINESTRING}) between pairs of points using the HERE 'Public Transit' API.
#' Two modes are provided:
#' \itemize{
#'   \item\code{summary = FALSE}: The public transport connections are returned as mulitple sections with the same vehicle and transport mode. Each section has a detailed route geometry.
#'   \item\code{summary = TRUE}: A summary of the connections is retrieved, where each connection is represented as one row with a unified and simplified geometry.
#' }
#'
#' @references
#' \href{https://developer.here.com/documentation/public-transit/dev_guide/routing/index.html}{HERE Public Transit API: Transit Route}
#'
#' @param origin \code{sf} object, the origin locations of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, calculate connections for arrival at the defined time (\code{default = FALSE})?
#' @param results numeric, maximum number of suggested public transport routes (Valid range: 1 and 6).
#' @param transfers numeric, maximum number of transfers allowed per route (Valid range: -1 and 6, whereby the \code{default = -1} allows for unlimited transfers).
#' @param summary boolean, return a summary of the public transport connections instead of the sections of the routes (\code{default = FALSE})?
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
#' # Connection sections
#' sections <- connection(
#'   origin = poi[3:4, ], destination = poi[5:6, ],
#'   summary = FALSE, url_only = TRUE
#' )
#'
#' # Connection summary
#' summary <- connection(
#'   origin = poi[3:4, ], destination = poi[5:6, ],
#'   summary = TRUE, url_only = TRUE
#' )
connection <- function(origin, destination, datetime = Sys.time(),
                       arrival = FALSE, results = 3, transfers = -1,
                       summary = FALSE, url_only = FALSE) {
  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_input_rows(origin, destination)
  .check_numeric_range(results, 1, 6)
  .check_numeric_range(transfers, -1, 6)
  .check_datetime(datetime)
  .check_boolean(arrival)
  .check_boolean(summary)
  .check_boolean(url_only)

  # CRS transformation and formatting
  coords_orig <- sf::st_coordinates(
    sf::st_transform(origin, 4326)
  )
  coords_orig <- paste0(
    coords_orig[, 2], ",", coords_orig[, 1]
  )
  coords_dest <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  coords_dest <- paste0(
    coords_dest[, 2], ",", coords_dest[, 1]
  )

  # Add API key
  url <- .add_key(
    url = "https://transit.router.hereapi.com/v8/routes?"
  )

  # Add departure and arrival
  url = paste0(
    url,
    "&origin=",
    coords_orig,
    "&destination=",
    coords_dest
  )

  # Add departure time
  url <- .add_datetime(
    url,
    datetime,
    if (arrival) "arrivalTime" else "departureTime"
  )

  # Number of results
  url <- paste0(
    url,
    "&alternatives=",
    results
  )

  # Number of transfers (unlimited if -1)
  if (transfers > -1) {
    url <- paste0(
      url,
      "&changes=",
      transfers
    )
  }

  # Add route attributes
  url = paste0(
    url,
    "&return=polyline,travelSummary"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  routes <- .extract_connection_sections(data)

  # Checks success
  if (is.null(routes)) {
    message("No public transport routes found.")
    return(NULL)
  }

  # Postprocess
  routes <- routes[routes$rank <= results, ]
  routes$departure <- .parse_datetime_tz(routes$departure, tz = attr(datetime, "tzone"))
  routes$arrival <- .parse_datetime_tz(routes$arrival, tz = attr(datetime, "tzone"))
  rownames(routes) <- NULL

  # Summarize connections
  if (summary) {
    routes <- .connection_summary(routes)
  }

  # Create sf object
  return(
    sf::st_as_sf(
      as.data.frame(routes),
      sf_column_name = "geometry",
      crs = 4326
    )
  )
}

.extract_connection_sections <- function(data) {
  ids <- .get_ids(data)
  count <- 0

  # Routes
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    departure = character(),
    origin = character(),
    arrival = character(),
    destination = character(),
    mode = character(),
    category = character(),
    vehicle = character(),
    provider = character(),
    direction = character(),
    distance = integer(),
    duration = integer(),
    geometry = character()
  )
  routes <- data.table::rbindlist(
    append(list(template),
      lapply(data, function(con) {
        count <<- count + 1

        # Parse JSON
        df <- jsonlite::fromJSON(con)
        if (is.null(df$routes$sections)) {return(NULL)}

        # Connections
        rank <- 0
        connections <- data.table::data.table(
          id = ids[count],

          # Segments
          data.table::rbindlist(
            lapply(df$routes$sections, function(sec) {
              rank <<- rank + 1
              data.table::data.table(
                rank = rank,
                departure = sec$departure$time,
                origin = vapply(sec$departure$place$name,
                                function(x) if (is.na(x)) "ORIG" else x,
                                character(1)),
                arrival = sec$arrival$time,
                destination = vapply(sec$arrival$place$name,
                                     function(x) if (is.na(x)) "DEST" else x,
                                     character(1)),
                mode = sec$transport$mode,
                category = sec$transport$category,
                vehicle = sec$transport$name,
                provider = sec$agency$name,
                direction = sec$transport$headsign,
                distance = sec$travelSummary$length,
                duration = sec$travelSummary$duration,
                geometry = sec$polyline
              )
            }), fill = TRUE)
        )
      })), fill = TRUE
    )

  # Check success
  if (nrow(routes) < 1) {return(NULL)}

  # Decode flexible polyline encoding to LINESTRING
  routes$geometry <- sf::st_geometry(
    flexpolyline::decode_sf(
      routes$geometry, 4326
    )
  )
  return(routes)
}

.connection_summary <- function(routes) {
  arrival <- category <- departure <- destination <- distance <- NULL
  duration <- geometry <- id <- origin <- provider <- vehicle <- NULL
  summary <- routes[, list(
    departure = min(departure),
    origin = origin[2],
    arrival = max(arrival),
    destination = destination[length(destination)-1],
    transfers = length(stats::na.exclude(vehicle)) - 1,
    modes = paste(stats::na.exclude(mode), collapse = ", "),
    categories = paste(stats::na.exclude(category), collapse = ", "),
    vehicles = paste(stats::na.exclude(vehicle), collapse = ", "),
    providers = paste(stats::na.exclude(provider), collapse = ", "),
    distance = sum(distance),
    duration = sum(duration),
    geometry = sf::st_union(geometry)
  ), by = list(id, rank)]
  return(summary)
}


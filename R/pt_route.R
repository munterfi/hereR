#' HERE Public Transit API: Route
#'
#' Calculates public transit connections with geometries (\code{LINESTRING}) between pairs of points using the 'Public Transit' API.
#' Two modes are provided:
#' \itemize{
#'   \item\code{summary = FALSE}: The public transit connections are returned as mulitple sections with the same vehicle and transport mode. Each section has a detailed route geometry.
#'   \item\code{summary = TRUE}: A summary of the connections is retrieved, where each connection is represented as one row with a unified and simplified geometry.
#' }
#'
#' @references
#' \href{https://developer.here.com/documentation/transit/dev_guide/topics/quick-start-routing-1.html}{HERE Public Transit API: Transit Route}
#'
#' @param start \code{sf} object, the start locations of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations of geometry type \code{POINT}.
#' @param results numeric, maximum number of suggested public transit routes (Valid range: 1 and 6).
#' @param changes numeric, maximum number of changes allowed per route (Valid range: -1 and 6, \code{default = -1}).
#' @param time datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, calculate routes for arrival at the defined time (\code{default = FALSE})?
#' @param summary boolean, return a summary of the public transit connections instead of the sections of the routes (\code{default = FALSE})?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested routes.
#' @export
#'
#' @note
#' As it is not possible to match the "maneuvers" to the "connections-sections" in the API response using the section id (\code{sec_id}),
#' the returned geometries of walking sections are straight lines between the station (or start and destination) points instead of routed lines on the pedestrian network.
#' The walking segments can be routed in hindsight using the \link[hereR]{route} function with mode set to \code{"pedestrian"}.
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Connection segments
#' routes <- pt_route(
#'   start = poi[3:4, ], destination = poi[5:6, ],
#'   summary = FALSE, url_only = TRUE
#' )
#'
#' # Connection summary
#' routes <- pt_route(
#'   start = poi[3:4, ], destination = poi[5:6, ],
#'   summary = TRUE, url_only = TRUE
#' )
pt_route <- function(start, destination, results = 3, changes = -1, time = Sys.time(),
                     arrival = FALSE, summary = FALSE, url_only = FALSE) {
  # Checks
  .check_points(start)
  .check_points(destination)
  .check_numeric_range(results, 1, 6)
  .check_numeric_range(changes, -1, 6)
  .check_datetime(time)
  .check_boolean(arrival)
  .check_boolean(summary)
  .check_boolean(url_only)

  # CRS transformation and formatting
  start <- sf::st_coordinates(
    sf::st_transform(start, 4326)
  )
  start <- paste0(
    start[, 2], ",", start[, 1]
  )
  destination <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  destination <- paste0(
    destination[, 2], ",", destination[, 1]
  )

  # Add API key
  url <- .add_key(
    url = "https://transit.ls.hereapi.com/v3/route.json?"
  )

  # Add departure and arrival
  url = paste0(
    url,
    "&dep=",
    start,
    "&arr=",
    destination
  )

  # Add time
  url <- .add_datetime(
    url,
    time,
    "time"
  )

  # Determine arrival or departure time
  url <- paste0(
    url,
    "&arrival=",
    as.numeric(arrival)
  )

  # Number of results
  url <- paste0(
    url,
    "&max=",
    results
  )

  # Number of changes
  url <- paste0(
    url,
    "&changes=",
    changes
  )

  # Add route attributes
  url = paste0(
    url,
    "&routing=tt&graph=1&maneuvers=0"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  if (summary) {
    routes <- .extract_pt_route_summary(data, start, destination)
  } else {
    routes <- .extract_pt_route(data, start, destination)
  }

  # Checks success
  if (is.null(routes)) {
    message("No public transit routes found.")
    return(NULL)
  }

  # Postprocess
  routes <- routes[routes$rank <= results, ]
  routes$arr_time <- .parse_datetime(routes$arr_time)
  routes$dep_time <- .parse_datetime(routes$dep_time)
  rownames(routes) <- NULL

  # Create sf object
  return(
    sf::st_as_sf(
      routes, sf_column_name = "geometry",
      crs = 4326
    )
  )
}

.extract_pt_route <- function(data, start, destination) {
  ids <- .get_ids(data)
  count <- 0

  # Routes
  routes <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1

      # O-D
      orig <- rev(as.numeric(strsplit(start[[count]], ",")[[1]]))
      dest <- rev(as.numeric(strsplit(destination[[count]], ",")[[1]]))

      # Parse JSON
      df <- jsonlite::fromJSON(con)
      if (is.null(df$Res$Connections$Connection$Sections$Sec)) {return(NULL)}

      # Connections
      rank <- 0
      connections <- data.table::data.table(
        id = ids[count],

        # Segments
        data.table::rbindlist(
          lapply(df$Res$Connections$Connection$Sections$Sec, function(sec) {
            rank <<- rank + 1
            data.table::data.table(
              rank = rank,
              dep_time = sec$Dep$time,
              dep_station = c("START", sec$Dep$Stn$name[2:length(sec$Dep$Stn$name)]),
              arr_time = sec$Arr$time,
              arr_station = c(sec$Arr$Stn$name[1:(length(sec$Arr$Stn$name)-1)], "DEST"),
              mode = sec$Dep$Transport$At$category,
              vehicle = sec$Dep$Transport$name,
              direction = sec$Dep$Transport$dir,
              distance = sec$Journey$distance,
              dep_lng = c(orig[1], sec$Dep$Stn$x[2:length(sec$Dep$Stn$x)]),
              dep_lat = c(orig[2], sec$Dep$Stn$y[2:length(sec$Dep$Stn$y)]),
              arr_lng = c(sec$Arr$Stn$x[1:(length(sec$Arr$Stn$x)-1)], dest[1]),
              arr_lat = c(sec$Arr$Stn$y[1:(length(sec$Arr$Stn$y)-1)], dest[2]),
              graph = sec$graph
            )
          }), fill = TRUE)
      )
    }), fill = TRUE)

  # Check success
  if (nrow(routes) < 1) {return(NULL)}

  # Point list to LINESTRINGs
  routes$geometry <- sf::st_sfc(lapply(1:nrow(routes), function(i) {
    if (is.na(routes[i, ]$graph)) {
      NULL
      sf::st_linestring(
        rbind(
          cbind(routes[i, ]$dep_lng, routes[i, ]$dep_lat),
          cbind(routes[i, ]$arr_lng, routes[i, ]$arr_lat)
        )
      )
    } else {
      .line_from_pointList(strsplit(routes[i, ]$graph, " ")[[1]])
    }
  }), crs = 4326)

  # Postprocess
  routes[, c("dep_lng", "dep_lat",
             "arr_lng", "arr_lat",
             "graph")] <- NULL
  routes[is.na(routes$mode), ]$mode <- "Walk"

  return(routes)
}

.extract_pt_route_summary <- function(data, start, destination) {
  ids <- .get_ids(data)
  count <- 0
  geoms <- list()

  # Routes
  routes <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1

      # O-D
      orig <- rev(as.numeric(strsplit(start[[count]], ",")[[1]]))
      dest <- rev(as.numeric(strsplit(destination[[count]], ",")[[1]]))

      # Parse JSON
      df <- jsonlite::fromJSON(con)
      if (is.null(df$Res$Connections$Connection$Sections$Sec)) {return(NULL)}

      # Connections
      rank <- 0
      connections <- data.table::rbindlist(
        lapply(df$Res$Connections$Connection$Sections$Sec, function(sec) {
          rank <<- rank + 1

          # Create LINESTRINGS
          geoms <<- append(geoms, list(sf::st_linestring(
            rbind(orig, stats::na.exclude(cbind(sec$Dep$Stn$x, sec$Dep$Stn$y)), dest)
          )))

          # Summaries
          data.table::data.table(
            id = ids[count],
            rank = rank,
            dep_time = df$Res$Connections$Connection$Dep$time[rank],
            dep_station = sec$Dep$Stn$name[2],
            arr_time = df$Res$Connections$Connection$Arr$time[rank],
            arr_station = sec$Arr$Stn$name[length(sec$Arr$Stn$name)-1],
            changes = df$Res$Connections$Connection$transfers[rank],
            modes = paste(stats::na.exclude(sec$Dep$Transport$At$category), collapse = ", "),
            vehicles = paste(stats::na.exclude(sec$Dep$Transport$name), collapse = ", "),
            distance = sum(sec$Journey$distance)
          )
        }), fill = TRUE
      )
    }), fill = TRUE
  )

  # Check success
  if (nrow(routes) < 1) {return(NULL)}

  # Add geometries
  routes$geometry <- geoms
  return(routes)
}

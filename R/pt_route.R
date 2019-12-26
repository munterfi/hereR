#' HERE Public Transit API: Route
#'
#' Calculates public transit route geometries (\code{LINESTRING}) between given pairs of points using the 'Public Transit' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/transit/dev_guide/topics/quick-start-routing-1.html}{HERE Public Transit API: Transit Route}
#'
#' @param start \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the start locations.
#' @param destination \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT} for the destination locations.
#' @param results numeric, maximum number of suggested public transit routes (Valid range: 1 and 6).
#' @param changes numeric, maximum number of changes allowed per route (Valid range: -1 and 6, \code{default = -1}).
#' @param time datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, calculate routes for arrival at the defined time (\code{default = FALSE})?
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
#' # Routing
#' routes <- pt_route(
#'   start = poi[3:4, ], destination = poi[5:6, ],
#'   url_only = TRUE
#' )
pt_route <- function(start, destination, results = 3, changes = -1,
                     time = Sys.time(), arrival = FALSE, url_only = FALSE) {
  # Checks
  .check_points(start)
  .check_points(destination)
  .check_numeric_range(results, 1, 6)
  .check_numeric_range(changes, -1, 6)
  .check_datetime(time)
  .check_boolean(arrival)
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
  ids <- .get_ids(data)
  count <- 0
  routes <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      # O-D
      orig <- as.numeric(strsplit(start[[count]], ",")[[1]])
      orig <- cbind(orig[2], orig[1])
      dest <- as.numeric(strsplit(destination[[count]], ",")[[1]])
      dest <- cbind(dest[2], dest[1])
      # Results
      rank <- 0
      df <- jsonlite::fromJSON(con)
      if (is.null(df$Res$Connections$Connection$Sections$Sec)) {return(NULL)}
      # Connections
      connections <- data.table::data.table(
        id = ids[count],
        data.table::rbindlist(
          lapply(df$Res$Connections$Connection$Sections$Sec, function(sec) {
            rank <<- rank + 1
            # geom_orig <- sf::st_as_sf(
            #   data.frame(rbind(orig, na.exclude(cbind(sec$Dep$Stn$x,sec$Dep$Stn$y)))),
            #   coords = c("X1", "X2"), crs = 4236
            # )$geometry
            # geom_dest <- sf::st_as_sf(
            #   data.frame(rbind(na.exclude(cbind(sec$Arr$Stn$x,sec$Arr$Stn$y)), dest)),
            #   coords = c("X1", "X2"), crs = 4236
            # )$geometry
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
              # duration = .parse_duration(sec$Journey$duration),
              # arr_geom = geom_orig,
              # dep_geom = geom_dest,
              graph = sec$graph
            )
          }), fill = TRUE)
        )
  }), fill = TRUE)

  # Check success
  if (nrow(routes) < 1) {
    message("No public transit routes found.")
    return(NULL)
  }

  # Point list to LINESTRINGs
  routes$geometry <- sf::st_sfc(lapply(1:nrow(routes), function(i) {
    if (is.na(routes[i, ]$graph)) {
      NULL
    } else {
      .line_from_pointList(strsplit(routes[i, ]$graph, " ")[[1]])
    }
  }), crs = 4326)

  # Postprocess
  routes <- routes[routes$rank <= results, ]
  routes$graph <- NULL
  routes$arr_time <- as.POSIXct(routes$arr_time, format = "%Y-%m-%dT%H:%M:%OS")
  routes$dep_time <- as.POSIXct(routes$dep_time, format = "%Y-%m-%dT%H:%M:%OS")
  routes[is.na(routes$mode), ]$mode <- "Walk"
  rownames(routes) <- NULL

  # Create sf object
  return(
    sf::st_as_sf(
      routes, sf_column_name = "geometry"
    )
  )
}

#' HERE Isoline Routing API: Calculate Isoline
#'
#' Calcuates isolines (\code{POLYGON} or \code{MULTIPOLYGON}) using the HERE 'Isoline Routing' API
#' that connect the end points of all routes leaving from defined centers (POIs) with either
#' a specified length, a specified travel time or consumption (only the default E-car available).
#'
#' @references
#' \href{https://developer.here.com/documentation/isoline-routing-api/dev_guide/index.html}{HERE Isoline Routing API}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, are the provided Points of Interest (POIs) the origin or destination locations (\code{default = FALSE})?
#' @param range numeric, a vector of type \code{integer} containing the breaks for the generation of the isolines: (1) time in seconds; (2) distance in meters; (3) consumption in Wh.
#' @param range_type character, unit of the isolines: \code{"distance"}, \code{"time"} or \code{"consumption"}.
#' @param routing_mode character, set the routing mode: \code{"fast"} or \code{"short"}.
#' @param transport_mode character, set the transport mode: \code{"car"}, \code{"pedestrian"} or \code{"truck"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = TRUE})? If no traffic is selected, the \code{datetime} is set to \code{"any"} and the request is processed independently from time.
#' @param optimize, character, specifies how isoline calculation is optimized: \code{"balanced"}, \code{"quality"} or \code{"performance"} (\code{default = "balanced"}).
#' @param consumption_model character, specify the consumption model of the vehicle, see \href{https://developer.here.com/documentation/routing-api/dev_guide/topics/use-cases/consumption-model.html}{consumption model} for more information (\code{default = NULL} a average electric car is set).
#' @param aggregate boolean, aggregate (with function \code{min}) and intersect the isolines from geometry type \code{POLYGON} to geometry type \code{MULTIPOLYGON} (\code{default = TRUE})?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested isolines.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Isochrone for 5, 10, 15, 20, 25 and 30 minutes driving time
#' isolines <- isoline(
#'   poi = poi,
#'   range = seq(5, 30, 5) * 60,
#'   url_only = TRUE
#' )
isoline <- function(poi, datetime = Sys.time(), arrival = FALSE,
                    range = seq(5, 30, 5) * 60, range_type = "time",
                    routing_mode = "fast", transport_mode = "car",
                    traffic = TRUE, optimize = "balanced",
                    consumption_model = NULL, aggregate = TRUE,
                    url_only = FALSE) {

  # Checks
  .check_points(poi)
  .check_datetime(datetime)
  .check_range_type(range_type)
  .check_routing_mode(routing_mode)
  .check_transport_mode(transport_mode, request = "isoline")
  .check_optimize(optimize)
  .check_boolean(traffic)
  .check_boolean(arrival)
  .check_boolean(aggregate)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://isoline.router.hereapi.com/v8/isolines?"
  )

  # Add point coordinates
  coords <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  coords <- paste0(
    coords[, 2], ",", coords[, 1]
  )
  url <- paste0(
    url,
    if (arrival) {
      "&destination="
    } else {
      "&origin="
    },
    coords
  )

  # Add departure or arrival time depending on traffic option
  if (traffic) {
    url <- .add_datetime(
      url,
      datetime,
      if (arrival) "arrivalTime" else "departureTime"
    )
  } else {
    url <- paste0(
      url,
      "&arrivalTime=any",
      "&departureTime=any"
    )
  }

  # Add transport mode
  url <- .add_transport_mode(url, transport_mode)

  # Add range and range type
  url <- paste0(
    url,
    "&range[values]=",
    paste0(range, collapse = ","),
    "&range[type]=",
    range_type
  )

  # Add optimization method
  url <- paste0(
    url,
    "&optimizeFor=",
    optimize
  )

  # Add consumption model if specified, otherwise set to default electric vehicle
  if (is.null(consumption_model)) {
    url <- paste0(
      url,
      "&ev[freeFlowSpeedTable]=0,0.239,27,0.239,45,0.259,60,0.196,75,0.207,90,0.238,100,0.26,110,0.296,120,0.337,130,0.351,250,0.351",
      "&ev[trafficSpeedTable]=0,0.349,27,0.319,45,0.329,60,0.266,75,0.287,90,0.318,100,0.33,110,0.335,120,0.35,130,0.36,250,0.36",
      "&ev[ascent]=9",
      "&ev[descent]=4.3",
      "&ev[auxiliaryConsumption]=1.8"
    )
  } else {
    url <- paste0(
      url,
      consumption_model
    )
  }

  # Add departure time
  url <- .add_datetime(
    url,
    datetime,
    if (arrival) "arrival" else "departure"
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .async_request(
    url = url,
    rps = 1
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  isolines <- .extract_isolines(data, arrival)

  # Checks success
  if (is.null(isolines)) {
    message("No isolines received.")
    return(NULL)
  }

  # Parse datetimes
  departure <- NULL
  isolines[, c("departure", "arrival") := list(
    .parse_datetime_tz(departure, tz = attr(datetime, "tzone")),
    .parse_datetime_tz(arrival, tz = attr(datetime, "tzone"))
  )]
  if (range_type == "time") {
    if (arrival) {
      isolines[, departure := arrival - range]
    } else {
      isolines[, arrival := departure + range]
    }
  }
  rownames(isolines) <- NULL

  # Bug of data.table and sf combination? Drops sfc class, when only one row...
  isolines <- as.data.frame(isolines)
  isolines$geometry <- sf::st_sfc(isolines$geometry, crs = 4326)

  # Create sf data.frame
  isolines <- sf::st_as_sf(
    isolines,
    sf_column_name = "geometry",
    crs = 4326
  )

  # Spatially aggregate
  if (aggregate) {
    isolines <- .aggregate_isolines(isolines)
  }

  # Create sf object
  return(isolines)
}

.extract_isolines <- function(data, arrival) {
  ids <- .get_ids(data)
  count <- 0

  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    departure = character(),
    arrival = character(),
    range = integer(),
    geometry = character()
  )
  isolines <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(con) {
        count <<- count + 1
        df <- jsonlite::fromJSON(con)
        if (is.null(df$isolines)) {
          return(NULL)
        }
        data.table::data.table(
          id = ids[count],
          rank = seq_len(nrow(df$isolines)),
          departure = if (arrival) NA else df$departure$time,
          arrival = if (arrival) df$arrival$time else NA,
          range = df$isolines$range$value,
          geometry = lapply(df$isolines$polygons, function(x) {
            # Decode flexible polyline encoding to ...
            if (length(x$outer) > 1) {
              # MULTIPOLYGON
              sf::st_multipolygon(
                sf::st_geometry(flexpolyline::decode_sf(x$outer, 4326))
              )
            } else {
              # POLYGON
              sf::st_geometry(flexpolyline::decode_sf(x$outer, 4326))[[1]]
            }
          })
        )
      })
    ),
    fill = TRUE
  )

  # Check success
  if (nrow(isolines) < 1) {
    return(NULL)
  }

  return(isolines)
}

.aggregate_isolines <- function(isolines) {
  tz <- attr(isolines$departure, "tzone")
  isolines <- sf::st_set_precision(isolines, 1e5)
  isolines <- sf::st_make_valid(isolines)
  isolines <- stats::aggregate(isolines,
    by = list(isolines$range),
    FUN = min, do_union = TRUE, simplify = TRUE,
    join = sf::st_intersects
  )
  isolines <- sf::st_make_valid(isolines)
  suppressMessages(
    isolines <- sf::st_difference(isolines)
  )
  isolines$Group.1 <- NULL
  isolines$id <- NA
  attr(isolines$departure, "tzone") <- tz
  attr(isolines$arrival, "tzone") <- tz

  # Fix geometry collections
  suppressWarnings(
    isolines <- sf::st_collection_extract(
      isolines,
      type = "POLYGON"
    )
  )
  return(isolines)
}

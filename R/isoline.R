#' HERE Routing API: Isoline
#'
#' Calcuates isolines (\code{POLYGON} or \code{MULTIPOLYGON}) that connect the end points of all routes
#' leaving from defined centers (POIs) with either a specified length, a
#' specified travel time or consumption.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-isoline.html}{HERE Routing API: Calculate Isoline}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param range numeric, a vector of type \code{integer} containing the breaks for the generation of the isolines: (1) time in seconds; (2) distance in meters; (3) consumption in costfactor.
#' @param rangetype character, unit of the isolines: \code{"distance"}, \code{"time"} or \code{"consumption"}.
#' @param type character, set the routing type: \code{"fastest"} or \code{"shortest"}.
#' @param mode character, set the transport mode: \code{"car"}, \code{"pedestrian"} or \code{"truck"}.
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = FALSE})? If no \code{departure} date and time is set, the current timestamp at the moment of the request is used for \code{departure}.
#' @param departure datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the departure.
#' @param start boolean, are the provided Points of Interest (POIs) the start or destination (\code{default = TRUE})?
#' @param aggregate boolean, aggregate (with function \code{min}) and intersect the isolines from geometry type \code{POLYGON} to geometry type \code{MULTIPOLYGON} (\code{default = TRUE})?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested isolines.
#' @export
#'
#' @examples
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' # Isochrone for 5, 10, 15, 20, 25 and 30 minutes driving time
#' isolines <- isoline(
#'   poi = poi,
#'   range = seq(5, 30, 5) * 60,
#'   url_only = TRUE
#' )
isoline <- function(poi, range = seq(5, 30, 5) * 60, rangetype = "time",
                    type = "fastest", mode = "car", traffic = FALSE,
                    departure = NULL, start = TRUE, aggregate = TRUE,
                    url_only = FALSE) {

  # Checks
  .check_points(poi)
  .check_datetime(departure)
  .check_rangetype(rangetype)
  .check_type(type = type, request = "calculateisoline")
  .check_mode(mode = mode, request = "calculateisoline")
  .check_boolean(traffic)
  .check_boolean(start)
  .check_boolean(aggregate)
  .check_boolean(url_only)

  # Add authentication
  url <- .add_auth(
    url = "https://isoline.route.api.here.com/routing/7.2/calculateisoline.json?"
  )

  # Add point coords
  poi <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  poi <- paste0(
    "geo!", poi[, 2], ",", poi[, 1]
  )
  url = paste0(
    url,
    if (start) {"&start="} else {"&destination="},
    poi
  )

  # Add range and rangetype
  url = paste0(
    url,
    "&range=",
    paste0(range, collapse = ","),
    "&rangetype=",
    rangetype
  )

  # Add consumption details
  if (rangetype == "consumption") {
    url <- paste0(
      url,
      "&consumptionmodel=",
      "standard",
      "&customconsumptiondetails=",
      "speed,0,1.7,10,1.4,30,1.1,50,1.0,70,1.1,100,1.2,120,1.4,140,1.8;ascent,30.0;descent,10.0"
    )
  }
  # Add mode
  url <- .add_mode(
    url = url,
    type = type,
    mode = mode,
    traffic = traffic
  )

  # Add departure time
  url <- .add_datetime(
    url,
    departure,
    "departure"
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
  isolines <-  sf::st_as_sf(
    data.table::rbindlist(
      lapply(data, function(con) {
        count <<- count + 1
        df <- jsonlite::fromJSON(con)
        geometry <- lapply(df$response$isoline$component, function(iso){
          .polygon_from_pointList(iso$shape[[1]])
        })
        sf::st_as_sf(
          data.table::data.table(
            id = ids[count],
            timestamp = as.POSIXct(df$response$metaInfo$timestamp,
                                   tz = "UTC",
                                   format = "%Y-%m-%dT%H:%M:%SZ"),
            range = df$response$isoline$range,
            lng = df$response$center$longitude,
            lat = df$response$center$latitude
          ),
          geometry = sf::st_as_sfc(geometry, crs = 4326)
        )
      })
    )
  )

  # Aggregate
  if (aggregate) {
    isolines <- sf::st_set_precision(isolines, 1e4)
    isolines <- lwgeom::st_make_valid(isolines)
    isolines <- stats::aggregate(isolines, by = list(isolines$range),
                                 FUN = min, do_union = TRUE, simplify = TRUE,
                                 join = sf::st_intersects)
    isolines <- lwgeom::st_make_valid(isolines)
    isolines <- sf::st_difference(isolines)
    isolines$Group.1 <- NULL
    isolines$id <- NA

    # Fix geometry collections
    suppressWarnings(
      isolines <- sf::st_collection_extract(
        isolines, type = c("POLYGON")
      )
    )
  }
  rownames(isolines) <- NULL
  return(isolines)
}

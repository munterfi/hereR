#' HERE Routing API: Isoline
#'
#' Calcuates a isoline (POLYGON) that connects the end points of all routes
#' leaving from one defined center with either a specified length or a
#' specified travel time.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing/topics/resource-calculate-isoline.html}{HERE Routing API: Calculate Isoline}
#'
#' @param points
#' @param range
#' @param rangetype
#' @param type
#' @param mode
#' @param traffic
#' @param departure
#' @param start
#' @param aggregate
#'
#' @return
#' @export
#'
#' @examples
isoline <- function(points, range = seq(100, 1000, 100), rangetype = "distance",
                    type = "fastest", mode = "car", traffic = FALSE,
                    departure = NULL, start = TRUE, aggregate = TRUE,
                    url_only = FALSE) {

  # Checks
  .check_points(points)
  .check_datetime(departure)
  .check_rangetype(rangetype)
  .check_type(type = type, request = "calculateisoline")
  .check_mode(mode = mode, request = "calculateisoline")

  # Add authentification
  url <- .add_auth(
    url = "https://isoline.route.api.here.com/routing/7.2/calculateisoline.json?"
  )

  # Add point coords
  points <- sf::st_coordinates(
    sf::st_transform(points, 4326)
  )
  points <- paste0(
    "geo!", points[, 2], ",", points[, 1]
  )
  url = paste0(
    url,
    if (start) {"&start="} else {"&destination="},
    points
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
  url <- .add_departure(
    url,
    departure
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )

  # Extract information
  isolines <-  sf::st_as_sf(
    data.table::rbindlist(
      lapply(data, function(con) {
        df <- jsonlite::fromJSON(con)
        geometry <- lapply(df$response$isoline$component, function(iso){
          .polygon_from_pointList(iso$shape[[1]])
        })
        sf::st_as_sf(
          data.table::data.table(
            timestamp = df$response$metaInfo$timestamp,
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
    isolines <- stats::aggregate(isolines, by = list(isolines$range),
                                 FUN = min, do_union = TRUE, simplify = TRUE,
                                 join = sf::st_intersects)
    isolines <- sf::st_difference(isolines)
    isolines$Group.1 <- NULL

    # Fix geometry collections
    suppressWarnings(
      isolines <- sf::st_collection_extract(
        isolines, type = c("POLYGON")
      )
    )
  }

  return(isolines)
}

.polygon_from_pointList <- function(pointList) {
  coords <- strsplit(pointList, ",")
  lng <- as.numeric(sapply(coords, function(x) x[2]))
  lat <- as.numeric(sapply(coords, function(x) x[1]))
  sf::st_polygon(list(cbind(lng, lat)))
}


#' HERE Traffic API: Flow
#'
#' Real-time traffic flow from the HERE 'Traffic' API in areas of interest (AOIs).
#' The traffic flow data contains speed and congestion information, which
#' corresponds to the status of the traffic at the time of the query.
#'
#' @references
#' \href{https://developer.here.com/documentation/traffic-api/api-reference.html}{HERE Traffic API: Flow}
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param min_jam_factor numeric, only retrieve flow information with a jam factor greater than the value provided (\code{default = 0}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested traffic flow information.
#' @export
#'
#' @note
#' The maximum width and height of the bounding box of the input AOIs is 1 degree.
#' This means that each polygon (= one row) in the AOI \code{sf} object should fit in a 1 x 1 degree bbox.
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Real-time traffic flow
#' flow_data <- flow(
#'   aoi = aoi,
#'   url_only = TRUE
#' )
flow <- function(aoi, min_jam_factor = 0, url_only = FALSE) {
  # Checks
  .check_polygon(aoi)
  .check_min_jam_factor(min_jam_factor)
  .check_boolean(url_only)

  # Ensure EPSG: 4326
  aoi <- sf::st_transform(aoi, 4326)

  # Add API key
  url <- .add_key(
    url = "https://data.traffic.hereapi.com/v7/flow?"
  )

  # Add bbox
  url <- .add_bbox(
    url = url,
    aoi = aoi
  )

  # Shape information
  url <- paste0(
    url,
    "&locationReferencing=shape"
  )

  # Add min jam factor
  url <- paste0(
    url,
    "&minJamFactor=",
    min_jam_factor
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .async_request(
    url = url,
    rps = 10
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  flow_data <- .extract_traffic_flow(data, min_jam_factor)

  # Check for empty response
  if (is.null(flow_data)) {
    message("No traffic flow found in area of interest.")
    return(NULL)
  }

  # Spatially intersect flow
  flow_data <- flow_data[sf::st_intersects(
    sf::st_union(sf::st_geometry(aoi)), flow_data,
    sparse = FALSE
  ), ]

  rownames(flow_data) <- NULL
  return(flow_data)
}

.extract_traffic_flow <- function(data, min_jam_factor) {
  ids <- .get_ids(data)
  count <- 0
  geoms <- list()
  flow_data <- data.table::rbindlist(lapply(data, function(res) {
    count <<- count + 1
    df <- jsonlite::fromJSON(res)
    # parse geometries
    geoms <<- append(
      geoms,
      lapply(df$results$location$shape$links, function(link) {
        sf::st_multilinestring(
          lapply(link$points, function(pts) {
            sf::st_linestring(cbind(pts$lng, pts$lat))
          })
        )
      })
    )
    # parse data
    data.table::data.table(
      id = ids[count],
      speed = df$results$currentFlow$speed,
      speed_uncapped = df$results$currentFlow$speedUncapped,
      free_flow = df$results$currentFlow$freeFlow,
      jam_factor = df$results$currentFlow$jamFactor,
      confidence = df$results$currentFlow$confidence,
      traversability = df$results$currentFlow$traversability
    )
  }), fill = TRUE)
  flow_data$geometry <- geoms
  if (nrow(flow_data) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(
          as.data.frame(flow_data)
        ), 4326
      )
    )
  } else {
    return(NULL)
  }
}

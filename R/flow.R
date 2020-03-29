#' HERE Traffic API: Flow
#'
#' Real-time traffic flow from the HERE 'Traffic' API in areas of interest (AOIs).
#' The traffic flow data contains speed (\code{"SP"}) and congestion (jam factor: \code{"JF"}) information,
#' which corresponds to the status of the traffic at the time of the query.
#'
#' @references
#' \itemize{
#'   \item\href{https://developer.here.com/documentation/traffic/dev_guide/topics_v6.1/resource-parameters-flow.html}{HERE Traffic API: Flow}
#'   \item\href{https://stackoverflow.com/questions/28476762/reading-traffic-flow-data-from-here-maps-rest-api}{Flow explanation, stackoverflow}
#' }
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
#' The maximum width and height of the bounding box of the input AOIs is 10 degrees.
#' This means that each polygon (= one row) in the AOI \code{sf} object should fit in a 10 x 10 degree bbox.
#'
#' Explanation of the traffic flow variables:
#' \itemize{
#'   \item\code{"PC"}: Point TMC location code.
#'   \item\code{"DE"}: Text description of the road.
#'   \item\code{"QD"}: Queuing direction. '+' or '-'. Note this is the opposite of the travel direction in the fully qualified ID, For example for location 107+03021 the QD would be ‚-‚.
#'   \item\code{"LE"}: Length of the stretch of road.
#'   \item\code{"TY"}: Type information for the given Location Referencing container. This may be a freely defined string.
#'   \item\code{"SP"}: Speed (based on UNITS) capped by speed limit.
#'   \item\code{"FF"}: The free flow speed on this stretch of the road.
#'   \item\code{"JF"}: The number between 0.0 and 10.0 indicating the expected quality of travel. When there is a road closure, the Jam Factor will be 10. As the number approaches 10.0 the quality of travel is getting worse. -1.0 indicates that a Jam Factor could not be calculated.
#'   \item\code{"CN"}: Confidence, an indication of how the speed was determined. -1.0 road closed. 1.0=100\%.
#' }
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Real-time traffic flow
#' flow <- flow(
#'   aoi = aoi[aoi$code == "LI", ],
#'   url_only = TRUE
#' )
flow <- function(aoi, min_jam_factor = 0, url_only = FALSE) {

  # Checks
  .check_polygon(aoi)
  .check_min_jam_factor(min_jam_factor)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://traffic.ls.hereapi.com/traffic/6.2/flow.json?"
  )

  # Add bbox
  aoi <- sf::st_transform(aoi, 4326)
  bbox <- sapply(sf::st_geometry(aoi), sf::st_bbox)
  .check_bbox(bbox)
  url <- paste0(
    url,
    "&bbox=",
    bbox[4, ], ",", bbox[1, ], ";",
    bbox[2, ], ",", bbox[3, ]
  )

  # Response attributes
  url <- paste0(
    url,
    "&responseattributes=shape"
  )

  # Add min jam factor
    url <- paste0(
    url,
    "&minjamfactor=",
    min_jam_factor
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  flow <- .extract_traffic_flow(data, min_jam_factor)

  # Check for empty response
  if (is.null(flow)) {return(NULL)}

  # Spatial contains
  flow <-
    flow[Reduce(c, suppressMessages(sf::st_contains(aoi, flow))), ]
  rownames(flow) <- NULL
  return(flow)
}

.extract_traffic_flow <- function(data, min_jam_factor) {
  ids <- .get_ids(data)
  count <- 0
  geoms <- list()
  flow <- suppressWarnings(data.table::rbindlist(lapply(data, function(con) {
    count <<- count + 1
    df <- jsonlite::fromJSON(con)
    if (is.null(df$RWS$RW)) {return(NULL)}
    data.table::rbindlist(lapply(df$RWS$RW, function(rw) {
      data.table::rbindlist(lapply(rw$FIS, function(fis) {
        data.table::rbindlist(lapply(fis$FI, function(fi) {
          dat <- data.table::data.table(
            id = ids[count],
            cbind(
              fi$TM[, c("PC", "DE", "QD", "LE")],
              data.table::rbindlist(
                fi$CF, fill = TRUE
              )[, c("TY", "SP", "FF", "JF","CN")]
            )
          )
          geoms <<- append(geoms,
            geometry <- lapply(fi$SHP, function(shp) {
              lines <- lapply(shp$value, function(pointList) {
                .line_from_pointList(strsplit(pointList, " ")[[1]])
              })
              sf::st_multilinestring(lines)
            })
          )
          return(dat)
          }), fill = TRUE)
        }), fill = TRUE)
      }), fill = TRUE)
    }), fill = TRUE))
  flow$geometry <- geoms
  flow <- flow[flow$JF >= min_jam_factor, ]
  if (nrow(flow) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(
          as.data.frame(flow)
        ), 4326
      )
    )
  } else {
    return(NULL)
  }
}

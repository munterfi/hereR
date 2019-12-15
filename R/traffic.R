#' HERE Traffic API: Flow and Incidents
#'
#' Real-time traffic flow and incident information based on the 'Traffic' API.
#' The traffic flow data contains speed (\code{"SP"}) and congestion (jam factor: \code{"JF"}) information.
#' Traffic incidents contain information about location, time, duration, severity, description and other details.
#'
#' @references
#' \itemize{
#'   \item\href{https://developer.here.com/api-explorer/rest/traffic}{HERE Traffic API}
#'   \item\href{https://stackoverflow.com/questions/28476762/reading-traffic-flow-data-from-here-maps-rest-api}{Flow explanation, stackoverflow}
#' }
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param product character, traffic product of the 'Traffic API'. Supported products: \code{"flow"} and \code{"incidents"}.
#' @param from_dt datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the earliest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param to_dt datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the latest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param local_time boolean, should time values in the response for traffic incidents be in the local time of the incident or in UTC (\code{default = FALSE})?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested traffic information.
#' @export
#'
#' @note
#' Explanation of the returned traffic flow variables:
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
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' # Real-time traffic flow
#' flow <- traffic(
#'   aoi = aoi[aoi$code == "LI", ],
#'   product = "flow",
#'   url_only = TRUE
#' )
#'
#' # All traffic incidents from 2018 till end of 2019
#' incidents <- traffic(
#'   aoi = aoi[aoi$code == "LI", ],
#'   product = "incidents",
#'   from_dt = as.POSIXct("2018-01-01 00:00:00"),
#'   to_dt = as.POSIXct("2019-12-31 23:59:59"),
#'   url_only = TRUE
#' )
traffic <- function(aoi, product = "flow", from_dt = NULL, to_dt = NULL,
                    local_time = FALSE, url_only = FALSE) {

  # Checks
  .check_polygon(aoi)
  .check_datetime(from_dt)
  .check_datetime(to_dt)
  if (!(is.null(from_dt) | is.null(to_dt)))
    .check_datetime_range(from_dt, to_dt)
  .check_traffic_product(product)
  if ((!is.null(from_dt) | !is.null(to_dt)) & product == "flow") {
    from_dt <- to_dt <- NULL
    message("Note: 'from_dt' and 'to_dt' have no effect on traffic flow. Traffic flow is always real-time.")
  }
  .check_boolean(local_time)
  .check_boolean(url_only)

  # Add authentication
  url <- .add_auth(
    url = sprintf("https://traffic.api.here.com/traffic/6.2/%s.json?",
                  product)
  )

  # Add bbox
  aoi <- sf::st_transform(aoi, 4326)
  bbox <- sapply(sf::st_geometry(aoi), sf::st_bbox)
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

  # Add datetime range
  url <- .add_datetime(
    url = url,
    datetime = from_dt,
    field_name = "startTime"
  )
  url <- .add_datetime(
    url = url,
    datetime = to_dt,
    field_name = "endTime"
  )

  # Add time zone
  url <- paste0(
    url,
    "&localtime=",
    local_time
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  if (product == "flow") {
    traffic <- .extract_traffic_flow(data)
  } else if (product == "incidents") {
    traffic <- .extract_traffic_incidents(data)
  }

  # Check for empty response
  if (is.null(traffic)) {return(NULL)}

  # Spatial contains
  traffic <-
    traffic[Reduce(c, suppressMessages(sf::st_contains(aoi, traffic))), ]
  rownames(traffic) <- NULL
  return(traffic)
}

.extract_traffic_flow <- function(data) {
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
  if (nrow(flow) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(flow), 4326
      )
    )
  } else {
    return(NULL)
  }
}

.extract_traffic_incidents <- function(data) {
  #geoms_line <- list()
  ids <- .get_ids(data)
  count <- 0
  incidents <- data.table::rbindlist(lapply(data, function(con) {
    count <<- count + 1
    df <- jsonlite::fromJSON(con)
    if (is.null(df$TRAFFIC_ITEMS)) {return(NULL)}
    info <- data.table::data.table(
      id = ids[count],
      incident_id = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_ID,
      entry_dt = as.POSIXct(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$ENTRY_TIME, format="%m/%d/%Y %H:%M:%S"),
      from_dt = as.POSIXct(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$START_TIME, format="%m/%d/%Y %H:%M:%S"),
      to_dt = as.POSIXct(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$END_TIME, format="%m/%d/%Y %H:%M:%S"),
      status = tolower(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_STATUS_SHORT_DESC),
      type = tolower(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_TYPE_DESC),
      verified = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$VERIFIED,
      criticality = as.numeric(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$CRITICALITY$ID),
      road_closed = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_DETAIL$ROAD_CLOSED,
      location_name = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$LOCATION$POLITICAL_BOUNDARY$COUNTY,
      lng = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$LOCATION$GEOLOC$ORIGIN$LONGITUDE,
      lat = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$LOCATION$GEOLOC$ORIGIN$LATITUDE,
      description = sapply(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_DESCRIPTION, function(x) x$value[2])
    )
    # geometry_line <- lapply(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$LOCATION$GEOLOC$GEOMETRY$SHAPES$SHP, function(shp) {
    #   lines <- lapply(shp$value, function(pointList) {
    #     .line_from_pointList(strsplit(pointList, " ")[[1]])
    #   })
    #   if (length(lines) > 1) {sf::st_multilinestring(lines)}
    # })
    # geoms_line <<- append(geoms_line, geometry_line)
    # return(info)
  }), fill = TRUE)
  #incidents$geometry_line <- geoms_line

  # Create sf, data.frame
  if (nrow(incidents) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(incidents, coords = c("lng", "lat")), 4326
      )
    )
  } else {
    return(NULL)
  }
}

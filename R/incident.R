#' HERE Traffic API: Incidents
#'
#' Traffic incident information from the HERE 'Traffic' API in areas of interest (AOIs).
#' The incidents contain information about location, duration, severity, type, description and further details.
#'
#' @references
#' \href{https://developer.here.com/documentation/traffic/dev_guide/topics/resource-parameters-incidents.html}{HERE Traffic API: Incidents}
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param from \code{POSIXct} object, datetime of the earliest traffic incidents (\code{default = FALSE}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the traffic incidents.
#' @export
#'
#' @note
#' The maximum width and height of the bounding box of the input AOIs is 10 degrees.
#' This means that each polygon (= one row) in the AOI \code{sf} object should fit in a 10 x 10 degree bbox.
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # All traffic incidents from the beginning of 2018
#' incidents <- incident(
#'   aoi = aoi,
#'   from = as.POSIXct("2018-01-01 00:00:00"),
#'   url_only = TRUE
#' )
incident <- function(aoi, from = Sys.time() - 60*60*24*7, url_only = FALSE) {

  # Checks
  .check_polygon(aoi)
  .check_datetime(from)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://traffic.ls.hereapi.com/traffic/6.2/incidents.json?"
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
  # url <- paste0(
  #   url,
  #   "&responseattributes=shape"
  # )

  # Add datetime range
  url <- .add_datetime(
    url = url,
    datetime = from,
    field_name = "startTime"
  )
  # url <- .add_datetime(
  #   url = url,
  #   datetime = to,
  #   field_name = "endTime"
  # )

  # Add utc time zone
  url <- paste0(
    url,
    "&localtime=false"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  incident <- .extract_traffic_incidents(data)

  # Check for empty response
  if (is.null(incident)) {return(NULL)}

  # Spatial contains
  incident <-
    incident[Reduce(c, suppressMessages(sf::st_contains(aoi, incident))), ]
  rownames(incident) <- NULL
  return(sf::st_as_sf(as.data.frame(incident)))
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
      incidentId = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_ID,
      entryTime = .parse_datetime(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$ENTRY_TIME, format = "%m/%d/%Y %H:%M:%OS"),
      fromTime = .parse_datetime(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$START_TIME, format = "%m/%d/%Y %H:%M:%OS"),
      toTime = .parse_datetime(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$END_TIME, format = "%m/%d/%Y %H:%M:%OS"),
      status = tolower(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_STATUS_SHORT_DESC),
      type = tolower(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_TYPE_DESC),
      verified = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$VERIFIED,
      criticality = as.numeric(df$TRAFFIC_ITEMS$TRAFFIC_ITEM$CRITICALITY$ID),
      roadClosed = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$TRAFFIC_ITEM_DETAIL$ROAD_CLOSED,
      locationName = df$TRAFFIC_ITEMS$TRAFFIC_ITEM$LOCATION$POLITICAL_BOUNDARY$COUNTY,
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
        sf::st_as_sf(
          as.data.frame(incidents),
          coords = c("lng", "lat")), 4326
      )
    )
  } else {
    return(NULL)
  }
}

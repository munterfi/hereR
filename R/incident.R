#' HERE Traffic API: Incidents
#'
#' Traffic incident information from the HERE 'Traffic' API in areas of
#' interest (AOIs). The incidents contain information about location, duration,
#' severity, type, description and further details.
#'
#' @references
#' \href{https://developer.here.com/documentation/traffic-api/api-reference.html}{HERE Traffic API: Incidents}
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param from \code{POSIXct} object, start time of the earliest traffic incidents (\code{default = NULL}).
#' @param to \code{POSIXct} object, end time of the latest traffic incidents (\code{default = NULL}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the traffic incidents.
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
#' # Traffic incidents
#' incidents <- incident(
#'   aoi = aoi,
#'   url_only = TRUE
#' )
incident <- function(aoi, from = NULL, to = NULL, url_only = FALSE) {
  # Checks
  .check_polygon(aoi)
  .check_datetime(from)
  .check_datetime(to)
  .check_boolean(url_only)

  # Ensure EPSG: 4326
  aoi <- sf::st_transform(aoi, 4326)

  # Add API key
  url <- .add_key(
    url = "https://data.traffic.hereapi.com/v7/incidents?"
  )

  # Add bbox
  url <- .add_bbox(
    url = url,
    aoi = aoi
  )

  # Add earliest start time of range
  url <- .add_datetime(
    url = url,
    datetime = from,
    field_name = "earliestStartTime"
  )

  # Add latest end time of range
  url <- .add_datetime(
    url = url,
    datetime = to,
    field_name = "latestEndTime"
  )

  # Shape information
  url <- paste0(
    url,
    "&locationReferencing=shape"
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
  incident_data <- .extract_traffic_incidents(data)

  # Check for empty response
  if (is.null(incident_data)) {
    message("No traffic incidents found in area of interest.")
    return(NULL)
  }

  # Spatially intersect flow
  incident_data <- incident_data[sf::st_intersects(
    sf::st_union(sf::st_geometry(aoi)), incident_data,
    sparse = FALSE
  ), ]

  rownames(incident_data) <- NULL
  return(incident_data)
}

.extract_traffic_incidents <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  geoms <- list()
  incident_data <- data.table::rbindlist(lapply(data, function(res) {
    count <<- count + 1
    df <- jsonlite::fromJSON(res)
    if (length(df$results) == 0) {
      return(NULL)
    }
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
      incident_id = df$results$incidentDetails$id,
      hrn = df$results$incidentDetails$hrn,
      original_id = df$results$incidentDetails$originalId,
      original_hrn = df$results$incidentDetails$originalHrn,
      start_time = .parse_datetime(df$results$incidentDetails$startTime),
      end_time = .parse_datetime(df$results$incidentDetails$endTime),
      entry_time = .parse_datetime(df$results$incidentDetails$entryTime),
      road_closed = df$results$incidentDetails$roadClosed,
      criticality = df$results$incidentDetails$criticality,
      type = df$results$incidentDetails$type,
      codes = vapply(df$results$incidentDetails$codes, paste, collapse = ",", character(1)),
      description = df$results$incidentDetails$description$value,
      summary = df$results$incidentDetails$summary$value,
      vehicle_restrictions = ifelse(
        is.null(df$results$incidentDetails$vehicleRestrictions),
        NA,
        vapply(df$results$incidentDetails$vehicleRestrictions, function(x) {
          paste(x$vehicleType, collapse = ",")
        }, character(1))
      ),
      junction_traversability = df$results$incidentDetails$junctionTraversability
    )
  }), fill = TRUE)
  incident_data$geometry <- geoms
  if (nrow(incident_data) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(
          as.data.frame(incident_data)
        ), 4326
      )
    )
  } else {
    return(NULL)
  }
}

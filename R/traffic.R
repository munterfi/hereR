#' HERE Traffic API: Flow and Incidents
#'
#' Traffic flow and incident information based on the 'Traffic API'.
#' The traffic flow data contains speed (\code{"SP"}) and congestion (jam factor: \code{"JF"}) information.
#' Traffic incidents contain information about location, time, duration, severity, description and other details.
#'
#' @references
#' \href{https://developer.here.com/api-explorer/rest/traffic}{HERE Traffic API}
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param product character, traffic product of the 'Traffic API'. Supported products: \code{"flow"} and \code{"incidents"}.
#' @param from_dt datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the earliest traffic information.
#' @param to_dt datetime, timestamp of type \code{POSIXct}, \code{POSIXt} for the latest traffic information.
#' @param local_time boolean, should time values in the response for traffic incidents be in the local time of the incident or in UTC (\code{default = FALSE})?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested traffic information.
#' @export
#'
#' @examples
#' \donttest{
#' traffic(aoi = aoi[aoi$code == "LI", ], product = "flow")
#' }
traffic <- function(aoi, product = "flow", from_dt = NULL, to_dt = NULL,
                    local_time = FALSE, url_only = FALSE) {

  # Checks
  .check_polygon(aoi)
  .check_datetime(from_dt)
  .check_datetime(to_dt)
  if (!(is.null(from_dt) | is.null(to_dt)))
    .check_datetime_range(from_dt, to_dt)
  .check_traffic_product(product)

  # Add authentification
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

  # Check product combinations
  # if (product == "flow" & any(!c(is.null(from_dt), is.null(to_dt))))
  #   message("Datetime not supported by product 'flow': 'from_dt' and 'to_dt' will be ignored.")

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

  # Extract information
  if (product == "flow") {
    traffic <- .extract_traffic_flow(data)
  } else if (product == "flow") {
    traffic <- .extract_traffic_incidents(data)
  }

  # Spatial
  traffic <- suppressMessages(
    sf::st_join(traffic, aoi, left = FALSE)
  )
  return(traffic)
}

.extract_traffic_flow <- function(data) {
  geoms <- list()
  flow <- data.table::rbindlist(lapply(data, function(con) {
    df <- jsonlite::fromJSON(con)
    data.table::rbindlist(lapply(df$RWS$RW, function(rw) {
      data.table::rbindlist(lapply(rw$FIS, function(fis) {
        data.table::rbindlist(lapply(fis$FI, function(fi) {
          dat <- data.table::data.table(
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
    }), fill = TRUE)
  flow$geometry <- geoms
  return(
    sf::st_set_crs(
      sf::st_as_sf(flow), 4326
    )
  )
}

.extract_traffic_incidents <- function(data) {
  geoms <- list()
  flow <- data.table::rbindlist(lapply(data, function(con) {
    df <- jsonlite::fromJSON(con)
    data.table::rbindlist(lapply(df$RWS$RW, function(rw) {
      data.table::rbindlist(lapply(rw$FIS, function(fis) {
        data.table::rbindlist(lapply(fis$FI, function(fi) {
          dat <- data.table::data.table(
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
  }), fill = TRUE)
  flow$geometry <- geoms
  return(
    sf::st_set_crs(
      sf::st_as_sf(flow), 4326
    )
  )
}

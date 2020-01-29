#' @title Deprecated functions in package \pkg{hereR}.
#' @description The functions listed below are deprecated and will be defunct in
#'   the near future. When possible, alternative functions with similar
#'   functionality are also mentioned. Help pages for deprecated functions are
#'   available at \code{help("-deprecated")}.
#' @name hereR-deprecated
#' @keywords internal
NULL

#' HERE Traffic API: Flow and Incidents
#'
#' Real-time traffic flow and incident information based on the HERE 'Traffic' API in areas of interest (AOIs).
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
#' @param from \code{POSIXct} object, datetime of the earliest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param to \code{POSIXct} object, datetime of the latest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param min_jam_factor numeric, only retrieve flow information with a jam factor greater than the value provided (Note: Only takes effect if \code{product} is set to \code{"flow"}, \code{default = 0}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested traffic information.
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
#' @name traffic-deprecated
#' @usage
#' traffic(
#'   aoi,
#'   product = "flow",
#'   from = NULL,
#'   to = NULL,
#'   min_jam_factor = 0,
#'   url_only = FALSE
#' )
#' @seealso \code{\link{hereR-deprecated}}
#' @keywords internal
NULL

#' @rdname hereR-deprecated
#' @section \code{traffic}:
#' For \code{traffic}, use \code{\link{flow}} or \code{\link{incident}}.
#'
#' @export
traffic <- function(aoi, product = "flow", from = NULL, to = NULL,
                    min_jam_factor = 0, url_only = FALSE) {

  # Checks
  .check_polygon(aoi)
  .check_datetime(from)
  .check_datetime(to)
  if (!(is.null(from) | is.null(to)))
    .check_datetime_range(from, to)
  .check_traffic_product(product)
  if ((!is.null(from) | !is.null(to)) & product == "flow") {
    from <- to <- NULL
    message("Note: 'from' and 'to' have no effect on traffic flow. Traffic flow is always real-time.")
  }
  .check_min_jam_factor(min_jam_factor)
  .check_boolean(url_only)

  # Deprecate function
  if (product == "flow") {
    .Deprecated(old = "traffic", new = "flow", package = "hereR")
  } else if (product == "incidents") {
    .Deprecated(old = "traffic", new = "incident", package = "hereR")
  }

  # Add API key
  url <- .add_key(
    url = sprintf("https://traffic.ls.hereapi.com/traffic/6.2/%s.json?",
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
    datetime = from,
    field_name = "startTime"
  )
  url <- .add_datetime(
    url = url,
    datetime = to,
    field_name = "endTime"
  )

  # Add time zone
  url <- paste0(
    url,
    "&localtime=false"
  )

  # Add min jam factor
  if (product == "flow") {
    url <- paste0(
      url,
      "&minjamfactor=",
      min_jam_factor
    )
  }

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  if (product == "flow") {
    traffic <- .extract_traffic_flow(data, min_jam_factor)
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

.check_traffic_product <- function(product) {
  traffic_product_types <- c("flow", "incidents")
  if (!product %in% traffic_product_types)
    stop(sprintf("'product' must be '%s'.", paste(traffic_product_types, collapse = "', '")))
}

.check_datetime_range <- function(from, to) {
  if (from > to)
    stop("Invalid datetime range: 'from' must be smaller than 'to'.")
}

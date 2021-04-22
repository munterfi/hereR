#' HERE Matrix Routing API: Calculate Matrix
#'
#' Calculates a matrix of M:N, M:1 or 1:N route summaries between given points of interest (POIs) using the HERE 'Matrix Routing' API.
#' Various transport modes and traffic information at a provided timestamp are supported.
#' The requested matrix is split into (sub-)matrices of dimension 15x100 to use the
#' maximum matrix size per request and thereby minimize the number of overall needed requests.
#' The result is one route summary matrix, that fits the order of the provided POIs: \code{orig_id}, \code{dest_id}.
#'
#' @references
#' \href{https://developer.here.com/documentation/matrix-routing-api/8.3.0/dev_guide/index.html}{HERE Matrix Routing API}
#'
#' @param origin \code{sf} object, the origin locations (M) of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations (N) of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure.
#' @param routing_mode character, set the routing type: \code{"fast"} or \code{"short"} (\code{default = "fast"}).
#' @param transport_mode character, set the transport mode: \code{"car"}, \code{"truck"}, \code{"pedestrian"} or \code{"bicycle"} (\code{default = "car"}).
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = TRUE})? If no traffic is selected, the \code{datetime} is set to \code{"any"} and the request is processed independently from time.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' A \code{data.frame}, which is an edge list containing the requested M:N route combinations.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Create routes summaries between all POIs
#' mat <- route_matrix(
#'   origin = poi,
#'   url_only = TRUE
#' )
route_matrix <- function(origin, destination = origin, datetime = Sys.time(),
                         routing_mode = "fast", transport_mode = "car",
                         traffic = TRUE, url_only = FALSE) {

  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_datetime(datetime)
  .check_routing_mode(routing_mode)
  .check_transport_mode(transport_mode, request = "matrix")
  .check_boolean(traffic)
  .check_boolean(url_only)

  # CRS transformation and formatting
  orig_coords <- sf::st_coordinates(
    sf::st_transform(origin, 4326)
  )
  dest_coords <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )

  # Add API key
  base_url <- .add_key(
    url = "https://matrix.router.hereapi.com/v8/matrix?"
  )

  # Add option for synchronous requests
  base_url <- paste0(
    base_url,
    "&async=false"
  )

  # Setup request headers
  request_headers <- .create_request_headers()

  # Create URLs for batches, store original ids and format coordinates
  batch_size_orig <- 15
  batch_size_dest <- 100
  orig_div <- seq(0, nrow(orig_coords) - 1, batch_size_orig)
  dest_div <- seq(0, nrow(dest_coords) - 1, batch_size_dest)
  orig_idx <- list()
  dest_idx <- list()
  url <- as.character(sapply(orig_div, function(i) {
    orig_batch <- orig_coords[
      (i + 1):(if (i + batch_size_orig > nrow(orig_coords)) nrow(orig_coords) else i + batch_size_orig), ,
      drop = FALSE
    ]
    sapply(dest_div, function(j) {
      dest_batch <- dest_coords[
        (j + 1):(if (j + batch_size_dest > nrow(dest_coords)) nrow(dest_coords) else j + batch_size_dest), ,
        drop = FALSE
      ]
      orig_idx <<- append(orig_idx, list(seq(0 + i, nrow(orig_batch) - 1 + i, 1)))
      dest_idx <<- append(dest_idx, list(seq(0 + j, nrow(dest_batch) - 1 + j, 1)))
      request_body <- .create_request_body(
        orig_batch, dest_batch, datetime, routing_mode, transport_mode, traffic
      )
      return(
        paste(
          base_url,
          request_headers,
          request_body,
          sep = " | "
        )
      )
    })
  }))

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
  route_mat <- .extract_route_matrix(data, orig_idx, dest_idx)

  # Checks success
  if (is.null(route_mat)) {
    message("No route matrix received.")
    return(NULL)
  }

  # Postprocess
  arrival <- departure <- error_code <- duration <- NULL
  route_mat[, c("departure", "arrival", "type", "mode", "error_code") := list(
    as.POSIXct(departure),
    as.POSIXct(arrival),
    routing_mode,
    transport_mode,
    data.table::fifelse(is.na(error_code), 0, error_code)
  )]
  if (traffic) {
    route_mat[, c("departure", "arrival") := list(
      datetime,
      datetime + duration
    )]
  }

  # Reorder
  route_mat <- route_mat[order(
    route_mat$orig_id,
    route_mat$dest_id
  ), ]
  rownames(route_mat) <- NULL
  return(as.data.frame(route_mat))
}

.create_request_headers <- function() {
  request_headers <- list(
    "accept" = "application/json",
    "Content-Type" = "application/json",
    "charset" = "UTF-8"
  )
  return(jsonlite::toJSON(request_headers, auto_unbox = TRUE, pretty = FALSE))
}

.create_request_body <- function(orig_coords, dest_coords,
                                 datetime, routing_mode,
                                 transport_mode, traffic) {
  request_body <- list(
    origins = lapply(seq_len(nrow(orig_coords)), function(x) {
      list(lat = orig_coords[x, 2], lng = orig_coords[x, 1])
    }),
    destinations = lapply(seq_len(nrow(dest_coords)), function(x) {
      list(lat = dest_coords[x, 2], lng = dest_coords[x, 1])
    }),
    regionDefinition = list(
      type = "world"
    ),
    departureTime = if (traffic) .encode_datetime(datetime, url_encode = FALSE) else "any",
    routingMode = routing_mode,
    transportMode = transport_mode,
    matrixAttributes = c("travelTimes", "distances")
  )
  return(jsonlite::toJSON(request_body, auto_unbox = TRUE, pretty = FALSE))
}

.extract_route_matrix <- function(data, orig_idx, dest_idx) {
  ids <- .get_ids(data)
  count <- 0

  template <- data.table::data.table(
    orig_id = integer(),
    dest_id = integer(),
    request_id = integer(),
    departure = character(),
    arrival = character(),
    type = character(),
    mode = character(),
    distance = integer(),
    duration = integer(),
    error_code = integer()
  )

  # Route_matrix
  route_mat <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(con) {
        count <<- count + 1

        # Parse JSON
        df <- jsonlite::fromJSON(con)
        if (is.null(df$matrix)) {
          return(NULL)
        }

        # Matrix
        routes <- data.table::data.table(
          data.table::CJ(
            orig_id = orig_idx[[count]][1:df$matrix$numOrigins] + 1,
            dest_id = dest_idx[[count]][1:df$matrix$numDestinations] + 1
          ),
          request_id = ids[count],
          departure = NA,
          arrival = NA,
          type = NA,
          mode = NA,
          distance = df$matrix$distances,
          duration = df$matrix$travelTimes,
          error_code = df$matrix$errorCodes
        )
      })
    ),
    fill = TRUE
  )

  return(route_mat)
}

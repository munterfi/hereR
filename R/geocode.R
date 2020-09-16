#' HERE Geocoder API: Geocode
#'
#' Geocodes addresses using the HERE 'Geocoder' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoding-search-api/dev_guide/topics/endpoint-geocode-brief.html}{HERE Geocoder API: Geocode}
#'
#' @param address character, addresses to geocode.
#' @param sf boolean, return an \code{sf} object (\code{default = TRUE}) or a
#'   \code{data.frame}?
#' @param url_only boolean, only return the generated URLs (\code{default =
#'   FALSE})?
#' @param addresses character, addresses to geocode (deprecated).
#'
#' @return
#' If \code{sf = TRUE}, an \code{sf} object, containing the position coordinates
#' geocoded addresses as geometry list column and the access coordinates as
#' well-known text (WKT).
#' If \code{sf = FALSE}, a \code{data.frame} containing the coordinates of the
#' geocoded addresses as \code{lng}, \code{lat} columns.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' locs <- geocode(address = poi$city, url_only = TRUE)
geocode <- function(address, sf = TRUE, url_only = FALSE, addresses) {

  if (!missing("addresses")) {
    warning("'addresses' is deprecated, use 'address' instead.")
    address <- addresses
  }

  # Input checks
  .check_addresses(address)
  .check_boolean(sf)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://geocode.search.hereapi.com/v1/geocode?"
  )

  # Add addresses
  url = paste0(
    url,
    "&q=",
    address
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  geocoded <- .extract_geocoded(data, address)

  # Create sf object
  if (nrow(geocoded) > 0) {
    rownames(geocoded) <- NULL
    # Return sf object if chosen
    if (sf) {
      # Parse access coordinates to WKT
      geocoded$access <- .wkt_from_point_df(geocoded, "lng_access", "lat_access")
      geocoded[, c("lng_access", "lat_access") := NULL]
      # Parse position coordinates and set as default geometry
      return(
        sf::st_set_crs(
          sf::st_as_sf(
            as.data.frame(geocoded),
            coords = c("lng_position", "lat_position"),
            sf_column_name = "geometry"
          ), value = 4326
        )
      )
    } else {
      return(as.data.frame(geocoded))
    }
  } else {
    return(NULL)
  }
}

.extract_geocoded <- function(data, address) {
  template <- data.table::data.table(
    id = numeric(),
    address = character(),
    type = character(),
    street = character(),
    house_number = character(),
    postal_code = character(),
    district = character(),
    city = character(),
    county = character(),
    state = character(),
    country = character(),
    lng_access = numeric(),
    lat_access = numeric(),
    lng_position = numeric(),
    lat_position = numeric()
  )
  ids <- .get_ids(data)
  count <- 0
  geocode_failed <- character(0)
  geocoded <- data.table::rbindlist(
    append(list(template),
           lapply(data, function(con) {
             count <<- count + 1
             df <- jsonlite::fromJSON(con)
             if (length(df$items) == 0) {
               geocode_failed <<- c(geocode_failed, address[count])
               return(NULL)
             }
             result <- data.table::data.table(
               id = ids[count],
               address = df$items$address$label,
               type = df$items$resultType,
               street = df$items$address$street,
               house_number = df$items$address$houseNumber,
               postal_code = df$items$address$postalCode,
               district = df$items$address$district,
               city = df$items$address$city,
               county = df$items$address$county,
               state = df$items$address$state,
               country = df$items$address$countryName,
               lng_access = if (is.null(df$items$access[[1]]$lng)) NA else df$items$access[[1]]$lng,
               lat_access = if (is.null(df$items$access[[1]]$lat)) NA else df$items$access[[1]]$lat,
               lng_position = df$items$position$lng,
               lat_position = df$items$position$lat
             )
             result[1, ]
           })
    ), fill = TRUE
  )
  if (length(geocode_failed) > 0) {
    message(
      sprintf(
        "Address(es) '%s' not found.",
        paste(geocode_failed, collapse = "', '")
      )
    )
  }
  return(geocoded)
}

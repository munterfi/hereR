#' HERE Geocoding & Search API: Reverse Geocode
#'
#' Get addresses from locations using the HERE 'Geocoder' API.
#' The return value is an \code{sf} object, containing point geometries
#' with suggestions for addresses near the provided POIs.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoding-search-api/dev_guide/topics/endpoint-reverse-geocode-brief.html}{HERE Geocoder API: Reverse Geocode}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param results numeric, maximum number of results (Valid range: 1 and 100).
#' @param sf boolean, return an \code{sf} object (\code{default = TRUE}) or a
#'   \code{data.frame}?
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' If \code{sf = TRUE}, an \code{sf} object, containing the position coordinates
#' of the reverse geocoded POIs as geometry list column and the access
#' coordinates as well-known text (WKT).
#' If \code{sf = FALSE}, a \code{data.frame} containing the
#' coordinates of the reverse geocoded POIs as \code{lng}, \code{lat} columns.
#' @export
#'
#' @note If no addresses are found near a POI, \code{NULL} for this POI is returned.
#' In this case the rows corresponding to this particular POI are missing and merging the POIs by row is not possible.
#' However, in the returned \code{sf} object, the column \code{"id"} matches the rows of the input POIs.
#' The \code{"id"} column can be used to join the original POIs.
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Get addresses
#' addresses <- reverse_geocode(poi = poi, results = 3, url_only = TRUE)
reverse_geocode <- function(poi, results = 1, sf = TRUE, url_only = FALSE) {
  # Input checks
  .check_points(poi)
  .check_numeric_range(results, 1, 100)
  .check_boolean(sf)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://revgeocode.search.hereapi.com/v1/revgeocode?"
  )

  # Add point coords
  coords <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  url <- paste0(
    url,
    "&at=", coords[, 2], ",", coords[, 1]
  )

  # Add language
  url <- paste0(
    url,
    "&lang=en-US"
  )

  # Add max results
  url <- paste0(
    url,
    "&limit=",
    results
  )

  # Return urls if chosen
  if (url_only) {
    return(url)
  }

  # Request and get content
  data <- .async_request(
    url = url,
    rps = 5
  )
  if (length(data) == 0) {
    return(NULL)
  }

  # Extract information
  reverse <- .extract_addresses(data)

  # Create sf object
  if (nrow(reverse) > 0) {
    rownames(reverse) <- NULL
    # Return sf object if chosen
    if (sf) {
      # Parse access coordinates to WKT
      reverse$access <- .wkt_from_point_df(reverse, "lng_access", "lat_access")
      reverse[, c("lng_access", "lat_access") := NULL]
      # Parse position coordinates and set as default geometry
      return(
        sf::st_set_crs(
          sf::st_as_sf(
            as.data.frame(reverse),
            coords = c("lng_position", "lat_position"),
            sf_column_name = "geometry"
          ),
          value = 4326
        )
      )
    } else {
      return(as.data.frame(reverse))
    }
  } else {
    return(NULL)
  }
}

.extract_addresses <- function(data) {
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
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
    distance = numeric(),
    lng_access = numeric(),
    lat_access = numeric(),
    lng_position = numeric(),
    lat_position = numeric()
  )
  ids <- .get_ids(data)
  count <- 0
  result <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(res) {
        count <<- count + 1
        df <- jsonlite::fromJSON(res)
        if (length(nrow(df$items)) == 0) {
          return(NULL)
        }
        data.table::data.table(
          id = ids[count],
          rank = seq(1, nrow(df$items)),
          address = df$items$title,
          type = df$items$resultType,
          street = df$items$address$street,
          house_number = df$items$address$houseNumber,
          postal_code = df$items$address$postalCode,
          district = df$items$address$district,
          city = df$items$address$city,
          county = df$items$address$county,
          state = df$items$address$state,
          country = df$items$address$countryName,
          distance = df$items$distance,
          lng_access = if (is.null(df$items$access[[1]]$lng)) NA else df$items$access[[1]]$lng,
          lat_access = if (is.null(df$items$access[[1]]$lat)) NA else df$items$access[[1]]$lat,
          lng_position = df$items$position$lng,
          lat_position = df$items$position$lat
        )
      })
    ),
    fill = TRUE
  )
  result
}

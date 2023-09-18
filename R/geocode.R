#' HERE Geocoding & Search API: Geocode
#'
#' Geocodes addresses using the HERE 'Geocoding & Search API' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoding-search-api/dev_guide/index.html}{HERE Geocoding & Search API: Geocode}
#'
#' @param address character, addresses to geocode or a list containing qualified queries with the keys "country", "state", "county", "city", "district", "street", "houseNumber" or "postalCode".
#' @param alternatives boolean, return also alternative results (\code{default = FALSE})?
#' @param sf boolean, return an \code{sf} object (\code{default = TRUE}) or a
#'   \code{data.frame}?
#' @param url_only boolean, only return the generated URLs (\code{default =
#'   FALSE})?
#'
#' @return
#' If \code{sf = TRUE}, an \code{sf} object, containing the position coordinates
#' geocoded addresses as geometry list column and the access coordinates as
#' well-known text (WKT).
#' If \code{sf = FALSE}, a \code{data.frame} containing the coordinates of the
#' geocoded addresses as \code{lng}, \code{lat} columns.
#'
#' According to the
#' \href{https://developer.here.com/documentation/geocoding-search-api/api-reference-swagger.html}{Geocoding
#' and Search API Reference}, the access coordinates are "[c]oordinates of the
#' place you are navigating to (for example, driving or walking). This is a
#' point on a road or in a parking lot." The position coordinates are "[t]he
#' coordinates (latitude, longitude) of a pin on a map corresponding to the
#' searched place."
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' locs <- geocode(address = poi$city, url_only = TRUE)
geocode <- function(address, alternatives = FALSE, sf = TRUE, url_only = FALSE) {
  UseMethod("geocode", address)
}

#' @export
geocode.list <- function(address, alternatives = FALSE, sf = TRUE, url_only = FALSE) {
  .check_qualified_query_list(address)
  address <- vapply(address, function(x) {
    .check_qualified_query(x)
    x <- x[!(x == "" | is.na(x))]
    x <- paste(names(x), x, sep = "=", collapse = ";")
  }, character(1))
  .geocode.default(
    address,
    alternatives = alternatives, sf = sf, url_only = url_only, qq = TRUE
  )
}

#' @export
geocode.character <- function(address, alternatives = FALSE, sf = TRUE, url_only = FALSE) {
  .check_character(address)
  .geocode.default(
    address,
    alternatives = alternatives, sf = sf, url_only = url_only, qq = FALSE
  )
}

.geocode.default <- function(address, alternatives = FALSE, sf = TRUE, url_only = FALSE, qq = FALSE) {
  # Input checks
  .check_boolean(alternatives)
  .check_boolean(sf)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://geocode.search.hereapi.com/v1/geocode?"
  )

  # Add addresses and remove pipe
  url <- paste0(
    url,
    ifelse(qq, "&qq=", "&q="),
    curl::curl_escape(address)
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
  geocoded <- .extract_geocoded(data, address, alternatives)

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
          ),
          value = 4326
        )
      )
    } else {
      return(as.data.frame(geocoded))
    }
  } else {
    return(NULL)
  }
}

.extract_geocoded <- function(data, address, alternatives) {
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    address = character(),
    type = character(),
    street = character(),
    house_number = character(),
    postal_code = character(),
    state_code = character(),
    country_code = character(),
    district = character(),
    city = character(),
    county = character(),
    state = character(),
    country = character(),
    score = numeric(),
    lng_access = numeric(),
    lat_access = numeric(),
    lng_position = numeric(),
    lat_position = numeric()
  )
  ids <- .get_ids(data)
  count <- 0
  geocode_failed <- character(0)
  geocoded <- data.table::rbindlist(
    append(
      list(template),
      lapply(data, function(res) {
        count <<- count + 1
        df <- jsonlite::fromJSON(res)
        if (length(df$items) == 0) {
          geocode_failed <<- c(geocode_failed, address[count])
          return(NULL)
        }
        result <- data.table::data.table(
          id = ids[count],
          rank = seq_len(nrow(df$items)),
          address = df$items$address$label,
          type = df$items$resultType,
          street = df$items$address$street,
          house_number = df$items$address$houseNumber,
          postal_code = df$items$address$postalCode,
          state_code = df$items$address$stateCode,
          country_code = df$items$address$countryCode,
          district = df$items$address$district,
          city = df$items$address$city,
          county = df$items$address$county,
          state = df$items$address$state,
          country = df$items$address$countryName,
          score = df$items$scoring$queryScore,
          lng_access = if (is.null(df$items$access[[1]]$lng)) NA else df$items$access[[1]]$lng,
          lat_access = if (is.null(df$items$access[[1]]$lat)) NA else df$items$access[[1]]$lat,
          lng_position = df$items$position$lng,
          lat_position = df$items$position$lat
        )
        if (alternatives) {
          return(result)
        } else {
          return(result[1, ])
        }
      })
    ),
    fill = TRUE
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

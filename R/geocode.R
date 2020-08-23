#' HERE Geocoder API: Geocode
#'
#' Geocodes addresses using the HERE 'Geocoder' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoding-search-api/dev_guide/topics/endpoint-geocode-brief.html}{HERE Geocoder API: Geocode}
#'
#' @param addresses character, addresses to geocode.
#' @param autocomplete boolean, use the 'Geocoder Autocomplete' API to
#'   autocomplete addresses? Note: This options doubles the amount of requests
#'   (\code{default = FALSE}).
#' @param sf boolean, return an \code{sf} object (\code{default = TRUE}) or a
#'   \code{data.frame}?
#' @param url_only boolean, only return the generated URLs (\code{default =
#'   FALSE})?
#'
#' @return
#' If \code{sf = TRUE}, an \code{sf} object, containing the position and the
#' access coordinates of the geocoded addresses as geometry list columns, where
#' the position coordinates are set as default geometry column.
#' If \code{sf = FALSE}, a \code{data.frame} containing the coordinates of the
#' geocoded addresses as \code{lng}, \code{lat} columns.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' locs <- geocode(addresses = poi$city, url_only = TRUE)
geocode <- function(addresses, autocomplete = FALSE, sf = TRUE, url_only = FALSE) {

  # Input checks
  .check_addresses(addresses)
  .check_boolean(autocomplete)
  .check_boolean(sf)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://geocode.search.hereapi.com/v1/geocode?"
  )

  # Autocomplete addresses
  if (autocomplete) {
    suggestions <- autocomplete(
      addresses = addresses,
      results = 1
    )
    if (!is.null(suggestions)) {
      addresses[suggestions$id] <- suggestions$label
    }
  }

  # Add addresses
  url = paste0(
    url,
    "&q=",
    addresses
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  ids <- .get_ids(data)
  count <- 0
  geocode_failed <- character(0)
  geocoded <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      df <- jsonlite::fromJSON(con)
      if (length(df$items) == 0) {
        geocode_failed <<- c(geocode_failed, addresses[count])
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
        lng_access = sapply(df$items$access, function(x) x$lng)[1],
        lat_access = sapply(df$items$access, function(x) x$lat)[1],
        lng_position = df$items$position$lng,
        lat_position = df$items$position$lat
      )
      result[1, ]
    }), fill = TRUE
  )

  # Failed to geocode
  if (length(geocode_failed) > 0) {
    message(
      sprintf(
        "Address(es) '%s' not found.",
        paste(geocode_failed, collapse = "', '")
      )
    )
  }

  # Create sf object
  if (nrow(geocoded) > 0) {
    rownames(geocoded) <- NULL
    # Return sf object if chosen
    if (sf) {
      # Parse access coordinates to additional geometry list-column
      geocoded$access <- sf::st_as_sfc(
        lapply(1:nrow(geocoded), function(x) {
          if (is.numeric(geocoded[x, ]$lng_access[[1]]) &
              is.numeric(geocoded[x, ]$lat_access[[1]])) {
            return(
              sf::st_point(
                cbind(
                  geocoded[x, ]$lng_access[[1]],
                  geocoded[x, ]$lat_access[[1]]
                )
              )
            )
          } else {
            return(sf::st_point())
          }
        }), crs = 4326
      )

      # Parse position coordinates and set as default geometry
      return(
        sf::st_set_crs(
          sf::st_as_sf(
            as.data.frame(
              geocoded[!colnames(geocoded) %in% c("lng_access", "lat_access")]
            ),
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

#' HERE Geocoder API: Geocode
#'
#' Geocodes addresses using the HERE Geocoder API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoder/topics/resource-geocode.html}{HERE Geocoder API: Geocode}
#'
#' @param addresses character, addresses to geocode.
#' @param url_only boolean, only return the generated URLs (default = FALSE)?
#'
#' @return
#' An sf object, containing the coordinates of the geocoded addresses.
#' @export
#'
#' @examples
geocode <- function(addresses, url_only = FALSE) {

  # Check and preprocess addresses
  .check_addresses(addresses)
  addresses[addresses == ""] = NA

  # Add authentification
  url <- .add_auth(
    url = "https://geocoder.api.here.com/6.2/geocode.json?"
  )

  # Add addresses
  url = paste0(
    url,
    "&searchtext=",
    addresses
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )

  # Extract information
  geocoded <- data.table::rbindlist(
    lapply(data, function(con) {
      df <- jsonlite::fromJSON(con)
      result <- data.table::data.table(
        address = df$Response$View$Result[[1]]$Location$Address$Label,
        street = df$Response$View$Result[[1]]$Location$Address$Street,
        houseNumber = df$Response$View$Result[[1]]$Location$Address$HouseNumber,
        postalCode = df$Response$View$Result[[1]]$Location$Address$PostalCode,
        district = df$Response$View$Result[[1]]$Location$Address$District,
        city = df$Response$View$Result[[1]]$Location$Address$City,
        county = df$Response$View$Result[[1]]$Location$Address$County,
        state = df$Response$View$Result[[1]]$Location$Address$State,
        country = df$Response$View$Result[[1]]$Location$Address$Country,
        type = df$Response$View$Result[[1]]$Location$LocationType,
        lng = df$Response$View$Result[[1]]$Location$NavigationPosition[[1]]$Longitude,
        lat = df$Response$View$Result[[1]]$Location$NavigationPosition[[1]]$Latitude
      )
      result[1, ]
    }), fill = TRUE
  )

  # Create sf, data.table, data.frame
  return(
    sf::st_set_crs(
      sf::st_as_sf(geocoded, coords = c("lng", "lat")),
    4326)
  )
}

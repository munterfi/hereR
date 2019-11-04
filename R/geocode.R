#' HERE Geocoder API: Geocode
#'
#' Geocodes addresses using the 'Geocoder' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoder/topics/resource-geocode.html}{HERE Geocoder API: Geocode}
#'
#' @param addresses character, addresses to geocode.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object, containing the coordinates of the geocoded addresses.
#' @export
#'
#' @examples
#' # Authentication
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
#'
#' locs <- geocode(addresses = poi$city, url_only = TRUE)
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
  if (length(data) == 0) return(NULL)

  # Extract information
  count <- 0
  geocoded <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      df <- jsonlite::fromJSON(con)
      if (length(df$Response$View) == 0) {
        message(sprintf("Address '%s' not found.", addresses[count]))
        return(NULL)
      }
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
  if (nrow(geocoded) > 0) {
    return(
      sf::st_set_crs(
        sf::st_as_sf(geocoded, coords = c("lng", "lat")),
        4326)
    )
  } else {
    return(NULL)
  }
}

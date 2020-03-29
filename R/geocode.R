#' HERE Geocoder API: Geocode
#'
#' Geocodes addresses using the HERE 'Geocoder' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoder/topics/resource-geocode.html}{HERE Geocoder API: Geocode}
#'
#' @param addresses character, addresses to geocode.
#' @param autocomplete boolean, use the 'Geocoder Autocomplete' API to autocomplete addresses? Note: This options doubles the amount of requests (\code{default = FALSE}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object, containing the coordinates of the geocoded addresses.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' locs <- geocode(addresses = poi$city, url_only = TRUE)
geocode <- function(addresses, autocomplete = FALSE, url_only = FALSE) {

  # Input checks
  .check_addresses(addresses)
  .check_boolean(autocomplete)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://geocoder.ls.hereapi.com/6.2/geocode.json?"
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
  ids <- .get_ids(data)
  count <- 0
  geocode_failed <- character(0)
  geocoded <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      df <- jsonlite::fromJSON(con)
      if (length(df$Response$View) == 0) {
        geocode_failed <<- c(geocode_failed, addresses[count])
        return(NULL)
      }
      result <- data.table::data.table(
        id = ids[count],
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

  # Failed to geocode
  if (length(geocode_failed) > 0) {
    message(sprintf("Address(es) '%s' not found.",
                    paste(geocode_failed, collapse = "', '")))
  }

  # Create sf object
  if (nrow(geocoded) > 0) {
    rownames(geocoded) <- NULL
    return(
      sf::st_set_crs(
        sf::st_as_sf(
          as.data.frame(geocoded),
          coords = c("lng", "lat")
        ), 4326
      )
    )
  } else {
    return(NULL)
  }
}

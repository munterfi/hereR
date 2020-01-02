#' HERE Geocoder API: Reverse Geocode
#'
#' Get addresses or landmarks from locations using the HERE 'Geocoder' API.
#' The return value is an \code{sf} object, containing point geometries
#' with suggestions for addresses or landmarks near the provided POIs.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoder/topics/resource-geocode.html}{HERE Geocoder API: Geocode}
#'
#' @param poi \code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.
#' @param results numeric, maximum number of results (Valid range: 1 and 20).
#' @param landmarks boolean, retrieve landmarks instead of addresses (\code{default = FALSE})?.
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object, containing the suggested addresses or landmark names of the reverse geocoded POIs.
#' @export
#'
#' @note If no addresses or landmarks are found near a POI, \code{NULL} for this POI is returned.
#' In this case the rows corresponding to this particular POI are missing and merging the POIs by row is not possible.
#' However, in the returned \code{sf} object, the column \code{"id"} matches the rows of the input POIs.
#' The \code{"id"} column can be used to join the original POIs.
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Get addresses
#' addresses <- reverse_geocode(poi = poi, results = 3, landmarks = FALSE, url_only = TRUE)
#'
#' # Get landmarks
#' landmarks <- reverse_geocode(poi = poi, results = 3, landmarks = TRUE, url_only = TRUE)
reverse_geocode <- function(poi, results = 1, landmarks = FALSE, url_only = FALSE) {

  # Input checks
  .check_points(poi)
  .check_numeric_range(results, 1, 20)
  .check_boolean(landmarks)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://reverse.geocoder.ls.hereapi.com/6.2/reversegeocode.json?"
  )

  # Add point coords
  poi <- sf::st_coordinates(
    sf::st_transform(poi, 4326)
  )
  url = paste0(
    url,
    "&prox=", poi[, 2], ",", poi[, 1]
  )

  # Add RevGeo mode
  url = paste0(
    url,
    "&mode=",
    if (landmarks) {"retrieveLandmarks"} else {"retrieveAddresses"}
  )

  # Add max results
  url = paste0(
    url,
    "&maxresults=",
    results
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  if (landmarks) {
    reverse <- .extract_landmarks(data)
  } else {
    reverse <- .extract_addresses(data)
  }

  # Create sf, data.table, data.frame
  if (nrow(reverse) > 0) {
    rownames(reverse) <- NULL
    return(
      sf::st_set_crs(
        sf::st_as_sf(
          as.data.frame(reverse),
          coords = c("lng", "lat")),
        4326)
    )
  } else {
    return(NULL)
  }
}

.extract_addresses <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  result <- data.table::rbindlist(lapply(data, function(con) {
    count <<- count + 1
    df <- jsonlite::fromJSON(con)
    if (length(df$Response$View$Result) == 0) return(NULL)
    data.table::data.table(
      id = ids[count],
      rank = seq(1, nrow(df$Response$View$Result[[1]])),
      distance = df$Response$View$Result[[1]]$Distance,
      level = df$Response$View$Result[[1]]$MatchLevel,
      lng = df$Response$View$Result[[1]]$Location$DisplayPosition$Longitude,
      lat = df$Response$View$Result[[1]]$Location$DisplayPosition$Latitude,
      label = df$Response$View$Result[[1]]$Location$Address$Label,
      country = df$Response$View$Result[[1]]$Location$Address$Country,
      state = df$Response$View$Result[[1]]$Location$Address$State,
      county = df$Response$View$Result[[1]]$Location$Address$County,
      city = df$Response$View$Result[[1]]$Location$Address$City,
      district = df$Response$View$Result[[1]]$Location$Address$District,
      street = df$Response$View$Result[[1]]$Location$Address$Street,
      houseNumber = df$Response$View$Result[[1]]$Location$Address$HouseNumber,
      postalCode = df$Response$View$Result[[1]]$Location$Address$PostalCode
    )
  }), fill = TRUE)
  result
}

.extract_landmarks <- function(data) {
  ids <- .get_ids(data)
  count <- 0
  result <- data.table::rbindlist(lapply(data, function(con) {
    count <<- count + 1
    df <- jsonlite::fromJSON(con)
    if (length(df$Response$View$Result) == 0) return(NULL)
    data.table::data.table(
      id = ids[count],
      rank = seq(1, nrow(df$Response$View$Result[[1]])),
      distance = df$Response$View$Result[[1]]$Distance,
      level = df$Response$View$Result[[1]]$MatchLevel,
      lng = df$Response$View$Result[[1]]$Location$DisplayPosition$Longitude,
      lat = df$Response$View$Result[[1]]$Location$DisplayPosition$Latitude,
      name = df$Response$View$Result[[1]]$Location$Name,
      label = df$Response$View$Result[[1]]$Location$Address$Label,
      country = df$Response$View$Result[[1]]$Location$Address$Country,
      state = df$Response$View$Result[[1]]$Location$Address$State
    )
  }), fill = TRUE)
  result
}

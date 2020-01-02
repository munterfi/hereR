#' HERE Geocoder API: Autocomplete
#'
#' Completes addresses using the HERE 'Geocoder Autocomplete' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoder-autocomplete/dev_guide/topics/resource-suggest.html}{HERE Geocoder API: Autocomplete}
#'
#' @param addresses character, addresses to autocomplete.
#' @param results numeric, maximum number of suggestions (Valid range: 1 and 20).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' A \code{data.table} object, containing the autocomplete suggestions for the addresses.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' suggestions <- autocomplete(addresses = poi$city, url_only = TRUE)
autocomplete <- function(addresses, results = 5, url_only = FALSE) {

  # Check addresses
  .check_addresses(addresses)
  .check_numeric_range(results, 1, 20)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://autocomplete.geocoder.ls.hereapi.com/6.2/suggest.json?"
  )

  # Add addresses
  url = paste0(
    url,
    "&query=",
    addresses
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

  # Autocomplete suggestions
  ids <- .get_ids(data)
  count <- 0
  suggestion <- data.table::rbindlist(
    lapply(data, function(con) {
      count <<- count + 1
      df <- jsonlite::fromJSON(con)
      if (length(df$suggestions) == 0) return(NULL)
      df <- data.table::data.table(df$suggestions)
      addr <- data.table::data.table(
        id = rep(ids[count], nrow(df)),
        order = seq(1, nrow(df))
      )
      cbind(addr, df)
    }), fill = TRUE
  )

  # Return if not NULL data.talbe
  if (nrow(suggestion) > 0) {
    rownames(suggestion) <- NULL
    return(as.data.frame(suggestion))
  } else {
    return(NULL)
  }
}

#' HERE Geocoding & Search API: Autosuggest
#'
#' Completes addresses using the HERE 'Geocoder Autosuggest' API.
#'
#' @references
#' \href{https://developer.here.com/documentation/geocoding-search-api/dev_guide/topics/endpoint-autosuggest-brief.html}{HERE Geocoder API: Autosuggest}
#'
#' @param address character, address text to propose suggestions.
#' @param results numeric, maximum number of suggestions (Valid range: 1 and 100).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' A \code{data.frame} object, containing the suggestions for the input addresses.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' suggestions <- autosuggest(address = poi$city, url_only = TRUE)
autosuggest <- function(address, results = 5, url_only = FALSE) {
  # Check addresses
  .check_character(address)
  .check_numeric_range(results, 1, 100)
  .check_boolean(url_only)

  # Add API key
  url <- .add_key(
    url = "https://revgeocode.search.hereapi.com/v1/autosuggest?"
  )

  # Add address
  url <- paste0(
    url,
    "&q=",
    curl::curl_escape(address)
  )

  # Add bbox containing the world
  url <- paste0(
    url,
    "&in=bbox:-180,-90,180,90"
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
  suggestion <- .extract_suggestions(data)

  # Return data.frame
  if (nrow(suggestion) > 0) {
    rownames(suggestion) <- NULL
    return(as.data.frame(suggestion))
  } else {
    return(NULL)
  }
}

.extract_suggestions <- function(data) {
  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    suggestion = character(),
    type = character()
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
          suggestion = df$items$title,
          type = df$items$resultType
        )
      })
    ),
    fill = TRUE
  )
  result
}

#' @title 'sf'-Based Interface to the 'HERE' REST APIs
#'
#' @name hereR-package
#' @aliases hereR-package
#' @docType package
#' @author Merlin Unterfinger - \email{info@@munterfinger.ch}
#' @keywords package
#' @seealso
#' \itemize{
#'   \item\href{https://github.com/munterfinger/hereR}{https://github.com/munterfinger/hereR/}
#'   \item\href{https://munterfinger.github.io/hereR}{https://munterfinger.github.io/hereR/}
#'   \item\href{https://developer.here.com/develop/rest-apis/}{https://developer.here.com/develop/rest-apis/}
#' }
#' @description The hereR package provides an interface to the 'HERE' REST APIs:
#' \itemize{
#'   \item Geocode and autocomplete addresses or reverse geocode POIs using the 'Geocoder' API;
#'   \item Route directions, travel distance or time matrices and isolines using the 'Routing' API;
#'   \item Request real-time traffic flow and incident information from the 'Traffic' API;
#'   \item Find request public transport connections and nearby stations from the 'Public Transit' API;
#'   \item Get weather forecasts, reports on current weather conditions, astronomical
#' information and alerts at a specific location from the 'Destination Weather' API.
#' }
#' Locations, routes and isolines are returned as \code{\link{sf}} objects.
#'
#' @section Application credentials:
#' This package requires an API key for a HERE project.
#' The key is set for the current R session and is used to authenticate in the requests to the APIs.
#' A free login and project can be created on \href{https://developer.here.com/}{https://developer.here.com/}.
#' In order to obtain the API key navigate to a project of your choice in the developer portal, select 'REST: Generate APP' and then 'Create API Key'.
#' To set the API key, please use: \code{\link{set_key}("<YOUR API KEY>")}
#'
#' @section Functions to access the APIs:
#' \itemize{
#'  \item\code{\link{autocomplete}} - Get suggestions for address strings.
#'  \item\code{\link{geocode}} - Get coordinates from addresses.
#'  \item\code{\link{reverse_geocode}} - Get addresses or landmarks from locations.
#'  \item\code{\link{route}} - Find the fastest routes between places.
#'  \item\code{\link{route_matrix}} - Request a matrix of route summaries between places.
#'  \item\code{\link{isoline}} - Create isochrone, isodistance or isoconsumption lines around places.
#'  \item\code{\link{traffic}} - Get information about traffic jam and incidents in areas.
#'  \item\code{\link{connection}} - Request public transport connections between places.
#'  \item\code{\link{station}} - Find stations nearby places.
#'  \item\code{\link{weather}} - Get weather observations, forecasts and alerts at places.
#' }
#'
#' @import sf
NULL

#' Verbose API usage of hereR
#'
#' If set to \code{TRUE} the hereR package is messaging information about
#' the amount of requests sent to the APIs and data size received.
#'
#' @param ans boolean, verbose or not (default = \code{FALSE})?
#'
#' @return
#' None.
#'
#' @export
#'
#' @examples
#' set_verbose(TRUE)
set_verbose <- function(ans = FALSE) {
  .check_boolean(ans)
  if (ans) {
    Sys.setenv(
      "HERE_VERBOSE" = "TRUE"
    )
  } else {
    Sys.unsetenv("HERE_VERBOSE")
  }
}

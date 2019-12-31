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
#' In order to use the hereR package, an API key for a HERE project has to be provided.
#' The key is set for the current R session and is used to authenticate in the requests to the APIs.
#' To set the credentials, please use: \code{\link{set_key}("<YOUR API KEY>")}\cr\cr
#' No login yet? Get a free login here: \href{https://developer.here.com/}{https://developer.here.com/}
#'
#' @section Interesting functions:
#' \itemize{
#'  \item\code{\link{geocode}} - Get coordinates from address strings.
#'  \item\code{\link{route}} - Find the fastest routes between places.
#'  \item\code{\link{isoline}} - Create isochrone, isodistance or isoconsumption lines around places.
#'  \item\code{\link{traffic}} - Get information about traffic jam and incidents in areas.
#'  \item\code{\link{connection}} - Find public transport connections between places.
#'  \item\code{\link{weather}} - Get weather observations, forecasts and alerts at places.
#' }
#'
#' @import sf
NULL

#' @title Defunct functions in package \pkg{hereR}.
#' @description The functions listed below are defunct.
#'   When possible, alternative functions with similar
#'   functionality are also mentioned. Help pages for defunct functions are
#'   available at \code{help("-defunct")}.
#' @name hereR-defunct
#' @keywords internal
NULL

#' HERE Traffic API: Flow and Incidents
#'
#' Real-time traffic flow and incident information based on the HERE 'Traffic' API in areas of interest (AOIs).
#' The traffic flow data contains speed (\code{"SP"}) and congestion (jam factor: \code{"JF"}) information.
#' Traffic incidents contain information about location, time, duration, severity, description and other details.
#'
#' @references
#' \itemize{
#'   \item\href{https://developer.here.com/api-explorer/rest/traffic}{HERE Traffic API}
#'   \item\href{https://stackoverflow.com/questions/28476762/reading-traffic-flow-data-from-here-maps-rest-api}{Flow explanation, stackoverflow}
#' }
#'
#' @param aoi \code{sf} object, Areas of Interest (POIs) of geometry type \code{POLYGON}.
#' @param product character, traffic product of the 'Traffic API'. Supported products: \code{"flow"} and \code{"incidents"}.
#' @param from \code{POSIXct} object, datetime of the earliest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param to \code{POSIXct} object, datetime of the latest traffic incidents (Note: Only takes effect if \code{product} is set to \code{"incidents"}).
#' @param min_jam_factor numeric, only retrieve flow information with a jam factor greater than the value provided (Note: Only takes effect if \code{product} is set to \code{"flow"}, \code{default = 0}).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#'
#' @return
#' An \code{sf} object containing the requested traffic information.
#'
#' @name traffic-defunct
#' @usage
#' traffic(aoi,
#'   product = "flow", from = NULL, to = NULL,
#'   min_jam_factor = 0, url_only = FALSE
#' )
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{traffic}:
#' For \code{traffic(..., product = "flow")}, use \code{\link{flow}} and
#' for \code{traffic(..., product = "incidents")}, use \code{\link{incident}}.
#'
#' @export
traffic <- function(aoi, product = "flow", from = NULL, to = NULL,
                    min_jam_factor = 0, url_only = FALSE) {
  if (product == "flow") {
    .Defunct(new = "flow", package = "hereR")
  } else {
    .Defunct(new = "incident", package = "hereR")
  }
}

#' Defunct: Set Application Credentials
#'
#' Provide application credentials (APP ID and APP CODE) for a HERE project
#' of type 'REST & XYZ HUB API/CLI', that will be used to authenticate in
#' the requests to the APIs.
#'
#' No login yet? Get your free login here: \href{https://developer.here.com/}{klick}
#'
#' @param app_id character, the APP ID from a HERE project.
#' @param app_code character, the APP CODE from a HERE project.
#'
#' @return
#' None.
#'
#' @name set_auth-defunct
#' @usage set_auth(app_id, app_code)
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{set_auth}:
#' For \code{set_auth}, use \code{\link{set_key}}.
#'
#' @export
set_auth <- function(app_id, app_code) {
  .Defunct(new = "set_key", package = "hereR")
}

#' Remove Application Credentials
#'
#' Remove previously set HERE application credentials from the current R session.
#'
#' @return
#' None.
#'
#' @name unset_auth-defunct
#' @usage unset_auth()
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{unset_auth}:
#' For \code{unset_auth}, use \code{\link{unset_key}}.
#'
#' @export
unset_auth <- function() {
  .Defunct(new = "unset_key", package = "hereR")
}

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
#' A \code{data.frame} object, containing the autocomplete suggestions for the addresses.
#'
#' @name autocomplete-defunct
#' @usage autocomplete(addresses, results, url_only)
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{autocomplete}:
#' For \code{autocomplete}, use \code{\link{autosuggest}}.
#'
#' @export
autocomplete <- function(addresses, results = 5, url_only = FALSE) {
  .Defunct(new = "autosuggest", package = "hereR")
}

#' Proxy Configuration
#'
#' If a proxy is needed, for example because the computer is behind a corporate proxy,
#' it can be set as follows: \code{proxy = "http://your-proxy.net:port/"} or \code{"https://your-proxy.net:port/"} and \code{"proxyuserpwd" = "user:pwd"}.
#'
#' @param proxy character, the URL of the proxy (\code{"https://your-proxy.net:port/"}).
#' @param proxyuserpwd character, user and password for the authentication (\code{"user:pwd"}).
#'
#' @return
#' None.
#'
#' @name set_proxy-defunct
#' @usage set_proxy(proxy, proxyuserpwd)
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{set_proxy}:
#' For \code{set_proxy}, configure a global proxy for R in '~/.Renviron' instead.
#'
#' @export
set_proxy <- function(proxy, proxyuserpwd) {
  .Defunct(msg = "'set_proxy' is defunct.\nUse a global proxy configuration for R in '~/.Renviron' instead.")
}

#' Remove Proxy Configuration
#'
#' Remove a previously set proxy configuration from the current R session.
#'
#' @return
#' None.
#' @name unset_proxy-defunct
#' @usage unset_proxy()
#' @seealso \code{\link{hereR-defunct}}
#' @keywords internal
NULL

#' @rdname hereR-defunct
#' @section \code{unset_proxy}:
#' For \code{unset_proxy}, configure a global proxy for R in '~/.Renviron' instead.
#'
#' @export
unset_proxy <- function() {
  .Defunct(msg = "'unset_proxy' is defunct.\nUse a global proxy configuration for R in '~/.Renviron' instead.")
}

#' HERE Application Credentials
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
#' @export
#'
#' @examples
#' set_auth(
#'   app_id = "<YOUR APP ID>",
#'   app_code = "<YOUR APP CODE>"
#' )
set_auth <- function(app_id, app_code){
  .check_auth(app_id, app_code)
  Sys.setenv(
    "HERE_APP_ID" = app_id,
    "HERE_APP_CODE" = app_code
  )
}

#' Proxy Configuration
#'
#' If a proxy is needed, for example because the computer is behind a corporate proxy,
#' it can be set as follows: \code{proxy = "http://your-proxy.net:port/"} or
#' \code{"https://your-proxy.net:port/"} and \code{"proxyuserpwd" = "user:pwd"}.
#'
#' @param proxy character, the URL of the proxy (\code{"https://your-proxy.net:port/"}).
#' @param proxyuserpwd character, user and password for the authentication (\code{"user:pwd"}).
#'
#' @return
#' None.
#' @export
#'
#' @examples
#' set_proxy(
#'   proxy = "https://your-proxy.net:port/",
#'   proxyuserpwd = "user:pwd"
#' )
set_proxy <- function(proxy, proxyuserpwd){
  .check_proxy(proxy)
  .check_proxyuserpwd(proxyuserpwd)
  Sys.setenv(
    "HERE_PROXY" = proxy,
    "HERE_PROXYUSERPWD" = proxyuserpwd
  )
}

#' Remove HERE Application Credentials
#'
#' Remove previously set HERE application credentials from the current R session.
#'
#' @return
#' None.
#' @export
#'
#' @examples
#' unset_auth()
unset_auth <- function() {
  Sys.unsetenv("HERE_APP_ID")
  Sys.unsetenv("HERE_APP_CODE")
}

#' Remove Proxy Configuration
#'
#' Remove a previously set proxy configuration from the current R session.
#'
#' @return
#' None.
#' @export
#'
#' @examples
#' unset_proxy()
unset_proxy <- function() {
  Sys.unsetenv("HERE_PROXY")
  Sys.unsetenv("HERE_PROXYUSERPWD")
}

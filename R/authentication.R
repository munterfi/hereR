#' HERE Application Credentials
#'
#' Provide application credentials (APP ID and APP CODE) for a HERE project
#' of type "REST & XYZ HUB API/CLI", that will be used to authenticate in
#' the requests to the APIs.
#'
#' No login yet? Get your free login here: \href{https://developer.here.com/}{klick}
#'
#' @param app_id character, the APP ID from a HERE project.
#' @param app_code character, the APP CODE from a HERE project.
#'
#' @return
#' @export
#'
#' @examples
#' set_auth("123456", "XXX-XXX-XXX")
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
#' it can be set as follows: proxy = "http://your-proxy.net:port/" or
#' "https://your-proxy.net:port/" and "proxyuserpwd" = "user:pwd".
#'
#' @param proxy character, the URL of the proxy ("https://your-proxy.net:port/").
#' @param proxyuserpwd character, user and password for the authentication ("user:pwd").
#'
#' @return
#' @export
#'
#' @examples
#' set_proxy("https://your-proxy.net:port/", "user:pwd")
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
#' @return
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
#' @return
#' @export
#'
#' @examples
#' unset_proxy()
unset_proxy <- function() {
  Sys.unsetenv("HERE_PROXY")
  Sys.unsetenv("HERE_PROXYUSERPWD")
}

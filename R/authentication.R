#' Set HERE Application Credentials
#'
#' Provide an API Key for a HERE project of type 'REST'.
#' The key is set for the current R session and is used
#' to authenticate in the requests to the APIs.
#'
#' No login yet? Get a login and key here: \href{https://developer.here.com/}{klick}
#'
#' @param api_key character, the API key from a HERE project.
#'
#' @return
#' None.
#' @export
#'
#' @examples
#' set_key("<YOUR API KEY>")
set_key <- function(api_key) {
  .check_key(api_key)
  Sys.setenv(
    "HERE_API_KEY" = api_key
  )
}

#' Remove HERE Application Credentials
#'
#' Remove previously set HERE API key from the current R session.
#'
#' @return
#' None.
#' @export
#'
#' @examples
#' unset_key()
unset_key <- function() {
  Sys.unsetenv("HERE_API_KEY")
}

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

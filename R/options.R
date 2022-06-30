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

#' Set whether plan is freemium or not
#'
#' If set to \code{TRUE} the hereR package limits the requests per second (RPS)
#' sent to the APIs and routing matrices will be chopped up into submatrices
#' of size 15x100. This option is necessary for freemium licenses to avoid
#' hitting the rate limit of the APIs with status code 429. Deactivate this
#' option to increase speed of requests for paid plans.
#'
#' @param ans boolean, use limits or not (default = \code{TRUE})?
#'
#' @return
#' None.
#'
#' @export
#'
#' @examples
#' set_freemium(FALSE)
set_freemium <- function(ans = TRUE) {
  .check_boolean(ans)
  if (!ans) {
    Sys.setenv(
      "HERE_FREEMIUM" = "FALSE"
    )
  } else {
    Sys.unsetenv("HERE_FREEMIUM")
  }
}

#' Set the currency for HERE API requests
#'
#' If the currency is not set using this function call, the currency defined in
#' the monetary representations in the current locale is used. If the monetary
#' formatting category \code{"LC_MONETARY"} of the C locale is not set,
#' \code{"USD"} is set as default.
#'
#' @param currency character, the currency code compliant to ISO 4217 to use in
#' the requests (default = \code{NULL}, which defaults to the current system
#' locale settings).
#'
#' @return
#' None.
#'
#' @export
#'
#' @examples
#' set_currency("CHF")
set_currency <- function(currency = NULL) {
  .check_character(currency)
  if (!is.null(currency)) {
    Sys.setenv(
      "HERE_CURRENCY" = gsub(" ", "", currency, fixed = TRUE)
    )
  } else {
    Sys.unsetenv("HERE_CURRENCY")
  }
}

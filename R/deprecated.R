#' @title Deprecated functions in package \pkg{hereR}.
#' @description The functions listed below are deprecated and will be defunct in
#'   the near future. When possible, alternative functions with similar
#'   functionality are also mentioned. Help pages for deprecated functions are
#'   available at \code{help("-deprecated")}.
#' @name hereR-deprecated
#' @keywords internal
NULL

#' Limit requests to the APIs
#'
#' If set to \code{TRUE} the hereR package limits the requests per second (RPS)
#' sent to the APIs. This option is necessary for freemium licenses to avoid
#' hitting the rate limit of the APIs with status code 429. Deactivate this
#' option to increase speed of requests for paid plans.
#'
#' @param ans boolean, use limits or not (default = \code{TRUE})?
#'
#' @return
#' None.
#'
#' @name set_rate_limit-deprecated
#' @usage
#' set_rate_limit(ans)
#' @seealso \code{\link{hereR-deprecated}}
#' @keywords internal
NULL

#' @rdname hereR-deprecated
#' @section \code{set_rate_limit}:
#' For \code{set_rate_limit} use \code{\link{set_freemium}}.
#'
#' @export
set_rate_limit <- function(ans = TRUE) {
  .Deprecated(old = "set_rate_limit", new = "set_freemium", package = "hereR")
  set_freemium(ans)
}

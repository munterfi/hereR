#' @title Defunct functions in package \pkg{hereR}.
#' @description The functions listed below are defunct.
#'   When possible, alternative functions with similar
#'   functionality are also mentioned. Help pages for defunct functions are
#'   available at \code{help("-defunct")}.
#' @name hereR-defunct
#' @keywords internal
NULL

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
set_auth <- function(app_id, app_code){
  .Defunct(new = "set_key", package = "hereR")
}

#' Remove Application Credentials
#'
#' Remove previously set HERE application credentials from the current R session.
#'
#' @return
#' None.
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

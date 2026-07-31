
#' Terminate all Microsoft Excel processes
#'
#' Forcefully terminates all running Microsoft Excel processes on Windows.
#'
#' @return invisibly, the exit status returned by `shell()`.
#'
#' @details
#' This function calls the Windows `taskkill` command with the `/F` option.
#' All open Excel instances are terminated immediately, and unsaved changes
#' are lost.
#'
#' @note This function is available on Windows only.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' xlKill()
#' }
xlKill <- function () {
  shell("taskkill /F /IM EXCEL.EXE")
}


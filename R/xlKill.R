
#' Terminate all Microsoft Excel processes
#'
#' Forcefully terminates all running Microsoft Excel processes on Windows.
#'
#' @return invisibly, the exit status returned by `taskkill`.
#'
#' @details
#' This function calls the Windows `taskkill` command with the `/F` option.
#' All running Excel processes are terminated immediately, and unsaved
#' changes are lost.
#'
#' @note This function is available on Windows only.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' xlKill()
#' }
xlKill <- function() {
  
  if (.Platform$OS.type != "windows") {
    stop(
      "xlKill() is available on Windows only.",
      call. = FALSE
    )
  }
  
  status <- system2(
    command = "taskkill",
    args = c("/F", "/IM", "EXCEL.EXE")
  )
  
  invisible(status)
}
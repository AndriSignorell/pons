
# ================================================================
# Excel session state (internal)
# ================================================================

.xl_env <- new.env(parent = emptyenv())
.xl_env$default <- NULL



# ================================================================
# Public API
# ================================================================


#' Create a New Excel Session
#'
#' Starts a new Microsoft Excel instance via RDCOMClient.
#' The created instance is registered as the current default
#' Excel session.
#'
#' @param visible Logical; whether the Excel application should
#'   be visible.
#' @return An Excel COM object of class \code{"COMIDispatch"}.
#'
#' @examples
#' \dontrun{
#' xl <- newXl()
#' }
#'
#' @export
newXl <- function(visible = TRUE) {
  
  xl <- .createCOMApp(
    "Excel.Application",
    visible = visible
  )
  
  xl[["Visible"]] <- visible
  setXl(xl)
  
  xl
  
}




#' Set Current Excel Session
#'
#' Registers an Excel COM object as the current default session.
#' @param xl An Excel COM object.
#' @return Invisibly returns \code{xl}.
#'
#' @export
setXl <- function(xl) {
  
  if (!.isCOM(xl)) {
    stop("Invalid Excel COM object.", call. = FALSE)
  }
  
  .xl_env$default <- xl
  
  invisible(xl)
}




#' Get Current Excel Session
#'
#' Retrieves the current Excel COM object. If no valid session exists,
#' a new one can optionally be created.
#'
#' @param create Logical; if \code{TRUE}, a new Excel instance is
#'   created when none is available.
#'
#' @return An Excel COM object or \code{NULL}.
#'
#' @export
getXl <- function(create = TRUE) {
  
  xl <- .xl_env$default
  
  # existing valid session
  if (.isValidXl(xl)) {
    return(xl)
  }
  
  # try existing Excel instance
  xl <- tryCatch(
    RDCOMClient::getCOMInstance("Excel.Application"),
    error = function(e) NULL
  )
  
  if (.isValidXl(xl)) {
    
    setXl(xl)
    
    return(xl)
  }
  
  # create new instance
  if (create) {
    return(newXl())
  }
  
  NULL
}




#' Temporarily Use an Excel Session
#'
#' Evaluates an expression using a specified Excel session as the
#' default.
#'
#' @param xl An Excel COM object.
#' @param expr An expression to evaluate.
#'
#' @return The result of the evaluated expression.
#'
#' @export
withXl <- function(xl, expr) {
  
  old <- .xl_env$default
  
  on.exit(.xl_env$default <- old, add = TRUE)
  
  .xl_env$default <- xl
  
  eval.parent(substitute(expr))
}




#' Close Excel Session
#'
#' Closes the current Excel session.
#'
#' @param save logical should the save dialog be displayed?
#' @return Invisibly returns \code{NULL}.
#'
#' @export
closeXl <- function(save = FALSE) {
  
  xl <- .xl_env$default
  
  if (.isValidXl(xl)) {
    xl$Quit(save)
  }
  
  .xl_env$default <- NULL
  
  invisible(NULL)
}





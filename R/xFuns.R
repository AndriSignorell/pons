

#' Run xlView() on selected text.
#' @export
xxlView <- function()  .execFunction("pons::xlView")


#' Run toWrd() on selected text.
#' @export
xtoWrd <- function()  .execFunction("pons::toWrd")




# == internal helper functions =================================================

.execFunction <- function(FUN) {
  
  requireNamespace("pons")
  
  if (!rstudioapi::isAvailable()) {
    stop("RStudio API not available.")
  }
  
  sel <- rstudioapi::getActiveDocumentContext()$
    selection[[1]]$text
  
  if (nzchar(sel)) {
    rstudioapi::sendToConsole(
      sprintf("%s(%s)", FUN, sel),
      execute = TRUE,
      focus = FALSE
    )
  } else {
    message("No selection!")
  }
}



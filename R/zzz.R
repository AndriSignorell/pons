

.onLoad <- function(libname, pkgname) {
  
  # presetting DescTools options not already defined by the user
  op <- options()
  
  # not needed with new wrd env approach
  pkg.op <- list(
  #   pons.lastWrd   = NULL,
  #   pons.lastXL    = NULL,
  #   pons.lastPP    = NULL
  )
  
  toset <- !(names(pkg.op) %in% names(op))
  if (any(toset)) options(pkg.op[toset])
  
}

utils::globalVariables("wdConst")


#' @importFrom bedrock setNamesX
#' @importFrom readxl read_xlsx
#' @importFrom writexl write_xlsx
#' @importFrom pharos strLeft strTrim
#'   
#' @import RDCOMClient
NULL           

#' @param naForm,verbose for \code{TMod} tables (\code{alloy::tMod()}):
#'   passed to its \code{format()} method, as is \code{digits}.
#' @details \code{TMod} tables: the coefficients and, separated by a rule,
#'   the model statistics, all model columns aligned at the decimal point.
#'   The header of the first column is \code{rowtitle}.
#' @rdname toWrd
#' @method toWrd TMod
#' @export
toWrd.TMod <- function(x, font = list(name = "Arial Narrow", size = 10),
                       digits = 3, naForm = "-", verbose = NULL,
                       rowtitle = "", ..., wrd = NULL) {

  wrd <- .resolveWrd(wrd)

  # same content as print(), the formatting lives in alloy:::format.TMod
  f <- format(x, digits = digits, naForm = naForm, verbose = verbose)

  d <- rbind(f$coef, f$stats)
  names(d)[1L] <- rowtitle

  tab <- toWrd.data.frame(d, font = font, ..., wrd = wrd)

  # rule between coefficients and statistics (row 1 is the header)
  if (nrow(f$stats))
    .wrdBorder(tab$Rows(nrow(f$coef) + 2L), -1L)  # wdBorderTop

  invisible(tab)
}

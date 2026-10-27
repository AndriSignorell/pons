#' @param indent string replacing the leading blanks of the level rows of
#'   categorical variables in a \code{TOne} table (blanks would be trimmed).
#' @param legend logical, write the test legend of a \code{TOne} table below
#'   the table, in a font 2 pt smaller.
#' @details \code{TOne} tables (\code{DescToolsX::tOne()}): the column header
#'   \code{"var"} is left empty, the group columns are right aligned and the
#'   p-values aligned at the decimal point.
#' @rdname toWrd
#' @method toWrd TOne
#' @export
toWrd.TOne <- function(x, font = list(name = "Arial Narrow", size = 10),
                       align = NULL, indent = strrep("\u00A0", 3),
                       legend = TRUE, ..., wrd = NULL) {

  wrd <- .resolveWrd(wrd)

  m   <- unclass(x)
  leg <- attr(m, "legend")
  hasTest <- !is.null(leg)

  cn <- colnames(m)
  if (is.null(cn)) cn <- rep("", ncol(m))
  if (identical(cn[1L], "var")) cn[1L] <- ""

  # level rows are indented with blanks, which toWrd.data.frame() would trim
  lev <- grepl("^ +", m[, 1L])
  m[lev, 1L] <- paste0(indent, sub("^ +", "", m[lev, 1L]))

  if (is.null(align))
    align <- c("l", rep("r", ncol(m) - 1L - hasTest), if (hasTest) "d")

  d <- as.data.frame(m, stringsAsFactors = FALSE)
  names(d) <- cn

  tab <- toWrd.data.frame(d, font = font, align = align, ..., wrd = wrd)

  if (legend && hasTest)
    toWrd.character(c(strsplit(leg, "\n", fixed = TRUE)[[1L]], ""),
                    font = list(name = font$name, size = font$size - 2),
                    wrd = wrd)

  invisible(tab)
}

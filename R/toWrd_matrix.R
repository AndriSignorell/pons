#' @param rownames logical, write the row names as first column.
#'   Default: \code{TRUE} if \code{x} has row names.
#' @param rowtitle header of the row name column. Default: the name of the
#'   row dimension (\code{names(dimnames(x))[1]}), else empty.
#' @param digits for non-character matrices: passed to \code{format()},
#'   which formats all cells with a common number of decimals.
#' @rdname toWrd
#' @method toWrd matrix
#' @export
toWrd.matrix <- function(x, font = list(name = "Arial Narrow", size = 10),
                         rownames = !is.null(base::rownames(x)),
                         rowtitle = NULL, labels = NULL, digits = NULL,
                         align = NULL, ..., wrd = NULL) {

  # cell content as character, NAs preserved for the na argument
  m <- x
  if (!is.character(x)) {
    m <- format(x, digits = digits, trim = TRUE)
    m[is.na(x)] <- NA
  }

  cn <- base::colnames(x)
  if (is.null(cn)) cn <- rep("", ncol(x))

  if (rownames) {
    if (is.null(rowtitle)) rowtitle <- names(dimnames(x))[1L]
    if (is.null(rowtitle) || is.na(rowtitle)) rowtitle <- ""
    rn <- base::rownames(x)
    rn <- if (is.null(rn)) rep("", nrow(x)) else .relabel(rn, labels)
    m  <- cbind(rn, m)
    cn <- c(rowtitle, cn)
  }

  if (is.null(align)) align <- c(if (rownames) "l", rep("d", ncol(x)))

  d <- as.data.frame(m, stringsAsFactors = FALSE)
  names(d) <- cn                          # keeps duplicated/empty names

  toWrd.data.frame(d, font = font, align = align, ..., wrd = wrd)
}


#' @details Tables: a 1-dimensional table is written as one column of
#'   frequencies, a 2-dimensional one like a matrix, higher dimensions are
#'   flattened with \code{ftable()} first.
#' @param freqtitle header of the frequency column of a 1-dimensional table.
#' @rdname toWrd
#' @method toWrd table
#' @export
toWrd.table <- function(x, font = list(name = "Arial Narrow", size = 10),
                        freqtitle = "Freq", ..., wrd = NULL) {

  m <- switch(as.character(min(length(dim(x)), 3L)),
    "1" = matrix(unclass(x), ncol = 1L,
                 dimnames = c(dimnames(x), list(freqtitle))),
    "2" = unclass(x),
          as.matrix(stats::ftable(x))
  )
  toWrd.matrix(m, font = font, ..., wrd = wrd)
}

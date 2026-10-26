
#' @param align character vector, one per column: "l", "r", "c" or "d"
#'   (decimal). Default: first column "l", others "d".
#' @param halign alignment of the header cells of decimal columns ("l", "c", "r").
#' @param decpos numeric, position of the decimal tab in points from the left
#'   text boundary of the cell, recycled over the "d" columns. Default: the
#'   column content is centred on an estimated decimal position.
#' @param spacing paragraph spacing: \code{before}, \code{after} (points) and
#'   \code{line} (multiple of single line spacing).
#' @param symbols \code{TRUE} uses \code{wrdSymbolMap()}, \code{FALSE} none, or
#'   a named character vector (pattern = replacement, perl regex).
#' @param na string used for NA values.
#' @param autofit logical, fit columns to content and then to window width.
#' @rdname toWrd
#' @method toWrd data.frame
#' @export
toWrd.data.frame <- function(x, font = list(name = "Arial Narrow", size = 10),
                             align = NULL, halign = "c", decpos = NULL,
                             spacing = c(before = 1, after = 0, line = 1.25),
                             symbols = TRUE, na = "", autofit = TRUE,
                             ..., wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  nc <- ncol(x)
  if (is.null(align)) align <- c("l", rep("d", nc - 1L))
  align <- rep_len(align, nc)
  
  # cell content: character, NA -> na, no padding, no tabs/linebreaks
  m <- as.matrix(x)
  m[is.na(m)] <- na
  m <- gsub("[\t\r\n]", " ", trimws(m))
  hd <- gsub("[\t\r\n]", " ", names(x))
  if (!isFALSE(symbols)) {
    map <- if (isTRUE(symbols)) wrdSymbolMap() else symbols
    m[] <- .wrdSymbols(m, map)
    hd  <- .wrdSymbols(hd, map)
  }
  
  lines <- c(paste(hd, collapse = "\t"), apply(m, 1L, paste, collapse = "\t"))
  rng   <- .wrdInsertRange(paste(lines, collapse = "\r"), wrd = wrd)
  tab   <- rng$ConvertToTable(Separator  = 1L,             # wdSeparateByTabs
                              NumRows    = length(lines),
                              NumColumns = nc)
  brd <- tab[["Borders"]]
  brd[["Enable"]] <- FALSE
  
  # font and paragraph spacing for the whole table
  trng <- tab$Range()
  fnt  <- trng[["Font"]]
  fnt[["Name"]] <- font$name
  fnt[["Size"]] <- font$size
  .wrdSpacing(trng[["ParagraphFormat"]], spacing)
  
  if (autofit) {
    tab$AutoFitBehavior(1L)   # wdAutoFitContent
    tab$AutoFitBehavior(2L)   # wdAutoFitWindow
  }
  
  # header: bold, top + bottom border; last row: bottom border
  # NB: never assign through a property chain like hdr[["Range"]][["Font"]][[.]],
  # R writes back hdr[["Range"]] <- range, i.e. Range.Text into the row!
  hdr  <- tab$Rows(1L)
  hfnt <- hdr$Range()[["Font"]]
  hfnt[["Bold"]] <- TRUE
  hdr[["HeadingFormat"]] <- TRUE                  # repeat header on page break
  .wrdBorder(hdr, c(-1L, -3L))                    # wdBorderTop, wdBorderBottom
  .wrdBorder(tab$Rows(length(lines)), -3L)
  
  # column alignment
  alg   <- c(l = 0L, c = 1L, r = 2L)              # wdAlignParagraph*
  dcols <- which(align == "d")
  if (length(dcols) && is.null(decpos))
    decpos <- vapply(dcols, function(j)
      .decTabPos(m[, j], tab$Columns(j)[["Width"]], font$size), numeric(1))
  decpos <- rep_len(decpos, length(dcols))
  
  for (j in seq_len(nc)) {
    tab$Columns(j)$Select()
    pf <- wrd[["Selection"]][["ParagraphFormat"]]
    if (align[j] == "d") {
      pf[["Alignment"]] <- 0L
      pf[["TabStops"]]$ClearAll()
      pf[["TabStops"]]$Add(Position  = decpos[match(j, dcols)],
                           Alignment = 3L)        # wdAlignTabDecimal
      hpf <- tab$Cell(1L, j)$Range()[["ParagraphFormat"]]
      hpf[["TabStops"]]$ClearAll()
      hpf[["Alignment"]] <- alg[[halign]]
    } else {
      pf[["Alignment"]] <- alg[[align[j]]]
    }
  }
  
  # cursor behind the table
  tab$Range()$Select()
  wrd[["Selection"]]$Collapse(Direction = wdConst$wdCollapseEnd)
  
  invisible(tab)
}


#' Symbol Replacements for Word Output
#'
#' Default map of perl regex patterns and their typographic replacements,
#' applied in the given order (longer tokens first).
#' @export
wrdSymbolMap <- function() c(
  "<=>"                        = "\u21D4",   # ⇔
  "=>"                         = "\u21D2",   # ⇒
  "<->"                        = "\u2194",   # ↔
  "->"                         = "\u2192",   # →
  "<-"                         = "\u2190",   # ←
  "<="                         = "\u2264",   # ≤
  ">="                         = "\u2265",   # ≥
  "!="                         = "\u2260",   # ≠
  "\\+/-|\\+-"                 = "\u00B1",   # ±
  "\\.\\.\\."                  = "\u2026",   # …
  "(?<=\\d)--(?=\\d)"          = "\u2013",   # 1--5  -> 1–5
  "(?<=\\d) ?x ?(?=\\d)"       = "\u00A0\u00D7\u00A0",  # 2 x 3 -> 2 × 3
  "\\^2"                       = "\u00B2",   # ²
  "\\^3"                       = "\u00B3",   # ³
  "(?<=[pnN]) ?([<=>\u2264\u2265]) ?(?=[\u2212.\\d-])" = "\u00A0\\1\u00A0",
  # p < 0.001: non-breaking
  "(^|(?<=[\\s(\\[;,=<>\u2264\u2265]))-(?=[\\d.])" = "\u2212"  # minus
)

#' @noRd
.wrdSymbols <- function(x, map) {
  for (i in seq_along(map))
    x <- gsub(names(map)[i], map[[i]], x, perl = TRUE)
  x
}

#' @noRd
.wrdInsertRange <- function(txt, wrd) {
  # insert at the cursor via an explicit range and return exactly that range;
  # surplus characters (RDCOMClient garbage with non-ASCII) are deleted
  doc <- wrd[["ActiveDocument"]]
  sel <- wrd[["Selection"]]
  sel$Collapse(Direction = wdConst$wdCollapseEnd)
  start <- sel[["Start"]]
  rng <- doc$Range(start, start)
  rng$InsertAfter(txt)
  end <- start + nchar(txt)
  if (rng[["End"]] > end) doc$Range(end, rng[["End"]])$Delete()
  doc$Range(start, end)
}

#' @noRd
.wrdSpacing <- function(pf, spacing) {
  if (!is.na(spacing["before"])) pf[["SpaceBefore"]] <- spacing[["before"]]
  if (!is.na(spacing["after"]))  pf[["SpaceAfter"]]  <- spacing[["after"]]
  if (!is.na(spacing["line"])) {
    pf[["LineSpacingRule"]] <- 5L                     # wdLineSpaceMultiple
    pf[["LineSpacing"]]     <- 12 * spacing[["line"]] # Word: 12 pt = 1 line
  }
  invisible()
}

#' @noRd
.wrdBorder <- function(obj, which, style = 1L, width = 4L) {
  # style 1 = wdLineStyleSingle, width 4 = wdLineWidth050pt
  for (w in which) {
    b <- obj$Borders(w)
    b[["LineStyle"]] <- style
    b[["LineWidth"]] <- width
  }
  invisible()
}

#' @noRd
.decTabPos <- function(x, colwidth, size, pad = 2 * 5.4, cw = 0.5 * size) {
  # centre the content block (left part | right part incl. stars) in the cell
  x <- x[nzchar(x)]
  if (!length(x)) return((colwidth - pad) / 2)
  L <- max(nchar(sub("\\..*$", "", x)))
  R <- max(nchar(x) - nchar(sub("\\..*$", "", x)))
  max(((colwidth - pad) + (L - R) * cw) / 2, 0)
}


#' @param rownames logical, write the row names as first column.
#'   Default: \code{TRUE} if \code{x} has row names.
#' @param rowtitle header of the row name column. Default: the name of the
#'   row dimension (\code{names(dimnames(x))[1]}), else empty.
#' @param digits for non-character matrices: passed to \code{format()},
#'   which formats all cells with a common number of decimals.
#' @rdname toWrd
#' @method toWrd matrix
#' @export
toWrd.matrix <- function(x, rownames = !is.null(base::rownames(x)),
                         rowtitle = NULL, digits = NULL, align = NULL,
                         ..., wrd = NULL) {
  
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
    if (is.null(rn)) rn <- rep("", nrow(x))
    m  <- cbind(rn, m)
    cn <- c(rowtitle, cn)
  }
  
  if (is.null(align)) align <- c(if (rownames) "l", rep("d", ncol(x)))
  
  d <- as.data.frame(m, stringsAsFactors = FALSE)
  names(d) <- cn                          # keeps duplicated/empty names
  
  toWrd.data.frame(d, align = align, ..., wrd = wrd)
}


#' @details Tables: a 1-dimensional table is written as one column of
#'   frequencies, a 2-dimensional one like a matrix, higher dimensions are
#'   flattened with \code{ftable()} first.
#' @param freqtitle header of the frequency column of a 1-dimensional table.
#' @rdname toWrd
#' @method toWrd table
#' @export
toWrd.table <- function(x, freqtitle = "Freq", ..., wrd = NULL) {
  
  m <- switch(as.character(min(length(dim(x)), 3L)),
              "1" = matrix(unclass(x), ncol = 1L,
                           dimnames = c(dimnames(x), list(freqtitle))),
              "2" = unclass(x),
              as.matrix(ftable(x))
  )
  toWrd.matrix(m, ..., wrd = wrd)
}



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
                       align = NULL, indent = strrep(" ", 3),
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


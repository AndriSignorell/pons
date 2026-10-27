
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
  stopifnot(all(align %in% c("l", "c", "r", "d")),
            length(halign) == 1L, halign %in% c("l", "c", "r"))
  
  cells <- .wrdTabCells(x, symbols = symbols, na = na)
  m     <- cells$body
  lines <- .wrdTabLines(cells)
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
#' Default map of perl regex patterns (names) and their typographic
#' replacements (values), applied in the given order (longer tokens first).
#'
#' @details The map is built with \code{setNames()}: non-ASCII patterns as
#'   argument tags, \code{c("\\u2264" = ...)}, would be translated to the
#'   native encoding and broken in non-UTF-8 locales.
#'
#' @return a named character vector.
#' @examples
#' wrdSymbolMap()
#' # extend the map
#' map <- c(wrdSymbolMap(), "chi2" = "\u03C7\u00B2")
#' @export
wrdSymbolMap <- function() {

  map <- matrix(byrow = TRUE, ncol = 2L, c(
    # pattern                      replacement
    "<=>",                         "\u21D4",              # double arrow
    "=>",                          "\u21D2",              # implies
    "<->",                         "\u2194",
    "->",                          "\u2192",
    "<-",                          "\u2190",
    "<=",                          "\u2264",
    ">=",                          "\u2265",
    "!=",                          "\u2260",
    "\\+/-|\\+-",                  "\u00B1",              # plus-minus
    "\\.\\.\\.",                   "\u2026",              # ellipsis
    "(?<=\\d)--(?=\\d)",           "\u2013",              # 1--5 -> en dash
    "(?<=\\d) ?x ?(?=\\d)",        "\u00A0\u00D7\u00A0",  # 2 x 3
    "\\^2",                        "\u00B2",
    "\\^3",                        "\u00B3",
    # p < 0.001, n = 12: non-breaking spaces around the relation
    "(?<=[pnN]) ?([<=>\u2264\u2265]) ?(?=[\u2212.\\d-])", "\u00A0\\1\u00A0",
    # minus sign: at the start or after blank, bracket, separator, relation
    "(^|(?<=[\\s\u00A0(\\[;,=<>\u2264\u2265]))-(?=[\\d.])", "\u2212"
  ))

  stats::setNames(map[, 2L], map[, 1L])
}

#' @noRd
.relabel <- function(x, labels) {
  # replace names by labels: named character vector (lookup) or function
  if (is.null(labels)) return(x)
  if (is.function(labels)) {
    res <- as.character(labels(x))
    if (length(res) != length(x))
      stop("the labels function must return one label per name")
    return(res)
  }
  if (!is.character(labels) || is.null(names(labels)))
    stop("labels must be a named character vector or a function")
  i <- match(x, names(labels))
  x[!is.na(i)] <- labels[i[!is.na(i)]]
  x
}

#' @noRd
.wrdTabCells <- function(x, symbols = TRUE, na = "") {
  # cell content as character matrix: NA -> na, trimmed, no tabs/linebreaks
  # (they would split cells/rows), symbols replaced
  m <- as.matrix(x)
  if (is.null(dim(m))) m <- matrix(m, nrow = NROW(x))
  m[is.na(m)] <- na
  m[] <- gsub("[\t\r\n]", " ", trimws(m))
  hd <- gsub("[\t\r\n]", " ", names(x))
  if (!isFALSE(symbols)) {
    map <- if (isTRUE(symbols)) wrdSymbolMap() else symbols
    m[] <- .wrdSymbols(m, map)
    hd  <- .wrdSymbols(hd, map)
  }
  list(header = hd, body = m)
}

#' @noRd
.wrdTabLines <- function(cells) {
  # one tab separated line per table row, header first
  c(paste(cells$header, collapse = "\t"),
    if (nrow(cells$body)) apply(cells$body, 1L, paste, collapse = "\t"))
}

#' @noRd
.wrdSymbols <- function(x, map) {
  for (i in seq_along(map))
    x <- gsub(names(map)[i], map[[i]], x, perl = TRUE)
  x
}

#' @noRd
.wrdInsertRange <- function(txt, wrd) {
  # insert at the cursor via an explicit range and return that range
  doc <- wrd[["ActiveDocument"]]
  sel <- wrd[["Selection"]]
  sel$Collapse(Direction = wdConst$wdCollapseEnd)
  start <- sel[["Start"]]
  rng <- doc$Range(start, start)
  rng$InsertAfter(txt)
  rng
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


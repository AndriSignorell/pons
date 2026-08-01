# =============================================================================
#  Excel <-> R data transfer via RDCOMClient
#
#  Public functions:
#    xlImport()      interactive end-to-end import (dialog-driven)
#    xlGetRange()    read the raw values of the selected Excel range(s)
#    xlParseRange()  organize raw range data into a data.frame / matrix /
#                    list / table
#
#  Internal helpers:
#    .xlInsertAtCursor()  insert code at the RStudio editor cursor
#    .xlConvert()         per-column automatic type conversion
#    .xlDeparse()         constructive deparser (readable code, no structure())
#
#  Design notes for future-Andri:
#    * Excel's Range$Value2() returns a *column-wise* nested list, i.e.
#      values[[col]][[row]]. This tripped us up once; keep the [[j]][[i]]
#      indexing in mind everywhere.
#    * A selection can consist of several disjoint "Areas" (e.g. A1:A4 and
#      C3:D5). xlGetRange() returns a single "XLRange" object for one area,
#      or an unclassed list of "XLRange" objects (plus attributes) for many.
#    * Dates come back from Value2() as numeric serial days, NOT as text.
#      .xlConvert() therefore only detects *textual* dates; numeric-serial
#      dates would need NumberFormat inspection (not implemented).
# =============================================================================



#' Interactively Import the Selected Excel Range into R
#'
#' End-to-end, dialog-driven transfer of the currently selected Excel
#' range(s) into R. The function reads the selection via \code{\link{xlGetRange}},
#' asks the user how to organize and deliver the data via
#' \code{\link{xlDataTransferDialog}}, and then either returns / assigns the
#' resulting object or inserts constructive R code at the editor cursor.
#'
#' The dialog offers the following target structures (single range):
#' \describe{
#'   \item{data.frame (colnames)}{first row becomes the column names.}
#'   \item{data.frame (no colnames)}{base-R default names \code{V1, V2, ...}.}
#'   \item{matrix}{whole range as a matrix, no dim names, default type choice.}
#'   \item{table (dimnames)}{first column becomes row names, first row becomes
#'         column names, the top-left corner cell is discarded.}
#'   \item{list}{one component per column.}
#' }
#' When several disjoint areas are selected, only \code{data.frame} variants and
#' \code{list} are offered (see \code{\link{xlParseRange}} for how areas are
#' combined), and \code{list} is preselected.
#'
#' Delivery is controlled by two dialog inputs, giving four combinations:
#' \tabular{lll}{
#'   \strong{insert} \tab \strong{variable} \tab \strong{action} \cr
#'   FALSE \tab set   \tab \code{assign(variable, out, parent.frame())} \cr
#'   FALSE \tab empty \tab return the object (printed at the console) \cr
#'   TRUE  \tab set   \tab insert \code{variable <- <code>} at the cursor \cr
#'   TRUE  \tab empty \tab insert \code{<code>} at the cursor \cr
#' }
#'
#' @param xl optional Excel application handle (as returned by \code{getXl()}).
#'   If \code{NULL}, the running instance is used.
#'
#' @return Invisibly (or visibly, when no variable is given and nothing is
#'   inserted) the organized object: a \code{data.frame}, \code{matrix},
#'   \code{list} or \code{table}-like matrix. Returns \code{invisible(NULL)}
#'   if the dialog is cancelled.
#'
#' @seealso \code{\link{xlGetRange}}, \code{\link{xlParseRange}},
#'   \code{\link{xlDataTransferDialog}}
#'
#' @examples
#' \dontrun{
#' xl <- getXl()
#' # select a range in Excel, then:
#' xlImport(xl)
#' }
#'
#' @export
xlImport <- function(xl = NULL) {

  # Obtain the Excel handle (fall back to the running instance).
  if (is.null(xl))
    xl <- getXl()
  if (is.null(xl))
    stop("No running Excel instance found.")

  # Read the current selection.
  r <- xlGetRange(xl)

  # Prepare the address string for the dialog label (comma -> semicolon,
  # so "A1:A4,C3:D5" reads as "A1:A4; C3:D5").
  addr <- attr(r, "address")
  addr <- gsub(",", "; ", addr)

  # Several disjoint areas selected? Then xlGetRange() returned an unclassed
  # list of "XLRange" blocks rather than a single "XLRange".
  multi <- !inherits(r, "XLRange") && is.list(r)

  # Show the dialog. With multiple areas only column-combinable structures
  # are offered (data.frame variants + list), and "list" is preselected.
  res <- xlDataTransferDialog(range = addr, multi = multi)

  # Cancel / Escape -> silent exit.
  if (is.null(res))
    return(invisible(NULL))

  # Organize the raw data into the requested structure.
  out <- switch(res$structure,
                "data.frame"       = xlParseRange(r, as = "data.frame", header = TRUE),
                "data.frame.nocol" = xlParseRange(r, as = "data.frame", header = FALSE),
                "matrix"           = xlParseRange(r, as = "matrix"),
                "table"            = xlParseRange(r, as = "table"),
                "list"             = xlParseRange(r, as = "list"),
                stop("Unknown structure: ", res$structure)
  )

  # Delivery matrix (see @details): the two dialog switches "insert at cursor"
  # and "variable name" give four combinations.
  hasvar  <- nzchar(res$variable)
  varname <- res$variable

  if (!isTRUE(res$insert)) {
    # insert = FALSE: deliver the object into the R session.
    if (hasvar) {
      # Assign into the *caller's* environment, not .GlobalEnv. When xlImport()
      # is called interactively from the console this IS the workspace, so the
      # object lands as `varname` just as expected - but without tripping the
      # CRAN "assignment to the global environment" NOTE (that check fires on
      # .GlobalEnv / globalenv() / pos = 1, not on parent.frame()).
      assign(varname, out, envir = parent.frame())
      return(invisible(out))
    } else {
      return(out)                                # print at the console
    }

  } else {
    # insert = TRUE: build readable constructive code and drop it at the
    # editor cursor (prefixed with "<varname> <- " if a name was given).
    code <- .xlDeparse(out)
    if (hasvar)
      code <- paste0(varname, " <- ", code)
    .xlInsertAtCursor(code)
    return(invisible(out))
  }
}


#' Insert Code at the RStudio Editor Cursor
#'
#' Inserts a string at the current cursor position of the active RStudio source
#' editor. Falls back to writing the code to the console when \pkg{rstudioapi}
#' is unavailable (e.g. plain R, Rgui).
#'
#' @param code single character string to insert.
#' @return \code{invisible(NULL)}, called for its side effect.
#' @keywords internal
#' @noRd
.xlInsertAtCursor <- function(code) {
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable() &&
      rstudioapi::hasFun("insertText")) {
    # insertText() with only 'text' targets the active editor's cursor.
    rstudioapi::insertText(text = code)
    return(invisible(NULL))
  }
  # No RStudio -> fallback: echo to the console.
  cat(code, "\n")
  invisible(NULL)
}



#' Read the Raw Values of the Selected Excel Range(s)
#'
#' Reads the values of an Excel range via RDCOMClient and returns them in a
#' lightweight container for further processing by \code{\link{xlParseRange}}.
#' No type conversion or reshaping happens here. The raw \code{Value2()} data
#' is kept as-is together with the range geometry and metadata.
#'
#' A selection may consist of several disjoint \emph{areas} (e.g. \code{A1:A4}
#' together with \code{C3:D5}). Each area is returned as its own
#' \code{"XLRange"} block. With a single area a single block is returned; with
#' multiple areas an (unclassed) list of blocks is returned, carrying the
#' overall metadata as attributes.
#'
#' @param xl optional Excel application handle. If \code{NULL}, the running
#'   Excel instance is attached via \code{RDCOMClient::COMCreate(..., existing = TRUE)}.
#' @param range optional A1-style address (e.g. \code{"A1:C10"} or
#'   \code{"Sheet1!A1:C10"}). If \code{NULL}, the current selection is used.
#'
#' @return For a single area, an object of class \code{"XLRange"}: a list with
#'   components \code{values} (the raw column-wise nested list from
#'   \code{Value2()}), \code{nrow} and \code{ncol}, plus attributes
#'   \code{address}, \code{sheet} and \code{file}.
#'   For multiple areas, a list of such \code{"XLRange"} objects with
#'   \code{address}, \code{sheet} and \code{file} attributes on the list itself.
#'
#' @note \code{Value2()} returns dates as numeric serial days (base
#'   1899-12-30), not as text, and yields a column-wise nested list indexed as
#'   \code{values[[column]][[row]]}.
#'
#' @seealso \code{\link{xlParseRange}}, \code{\link{xlImport}}
#'
#' @examples
#' \dontrun{
#' xl <- getXl()
#' r  <- xlGetRange(xl)          # current selection
#' attr(r, "address")           # e.g. "A1:B34"
#' attr(r, "sheet")             # worksheet name
#' attr(r, "file")              # workbook (file) name
#' }
#'
#' @export
xlGetRange <- function(xl = NULL, range = NULL) {

  if (is.null(xl))
    xl <- RDCOMClient::COMCreate("Excel.Application", existing = TRUE)

  rng <- if (is.null(range)) xl$Selection() else xl$Range(range)

  # Sheet and file metadata. All areas of one selection share the same
  # worksheet, so we read this once. Parent() of the worksheet is the workbook;
  # use $FullName() instead of $Name() if the full path is ever needed.
  ws    <- rng$Worksheet()
  sheet <- ws$Name()
  file  <- ws$Parent()$Name()          # workbook name, e.g. "data.xlsx"

  nareas <- rng$Areas()$Count()

  # Read one area into an "XLRange" block.
  getArea <- function(a) {
    nr <- a$Rows()$Count()
    nc <- a$Columns()$Count()
    vals <- a$Value2()
    # Single-cell areas: Value2() returns a scalar, not a 2D list. Wrap it so
    # downstream code can always assume the values[[col]][[row]] shape.
    if (nr == 1 && nc == 1) vals <- list(list(vals))
    structure(
      list(values = vals, nrow = nr, ncol = nc),
      class   = "XLRange",
      address = a$Address(FALSE, FALSE),   # relative, no "$" -> "A1:B34"
      sheet   = sheet,
      file    = file
    )
  }

  # Single area -> return the block directly.
  if (nareas == 1) {
    return(getArea(rng$Areas(1)))
  }

  # Multiple areas -> list of blocks, overall metadata on the list.
  areas <- lapply(seq_len(nareas), function(i) getArea(rng$Areas(i)))
  attr(areas, "address") <- rng$Address(FALSE, FALSE)   # e.g. "A1:A4,C3:D5"
  attr(areas, "sheet")   <- sheet
  attr(areas, "file")    <- file
  areas
}



#' Organize a Raw Excel Range into a data.frame, matrix, list or table
#'
#' Turns the raw output of \code{\link{xlGetRange}} into a proper R object.
#' Handles a single range as well as a multi-area selection, with optional
#' header handling and automatic per-column type conversion.
#'
#' \strong{Single range.} The requested structure determines the result:
#' \describe{
#'   \item{\code{"data.frame"}}{with \code{header = TRUE} the first row supplies
#'     the column names; otherwise names are \code{V1, V2, ...}.}
#'   \item{\code{"matrix"}}{the whole range as a matrix. When \code{convert} is
#'     \code{TRUE} and every column is numeric, a numeric matrix results;
#'     otherwise a character matrix.}
#'   \item{\code{"list"}}{one component per column (named by the header when
#'     \code{header = TRUE}).}
#'   \item{\code{"table"}}{first column becomes row names, first row becomes
#'     column names, and the top-left corner cell is discarded. The result is a
#'     matrix with \code{dimnames} (not a \code{table} object). Requires at
#'     least 2 rows and 2 columns.}
#' }
#'
#' \strong{Multiple areas.} When \code{x} is a list of \code{"XLRange"} blocks
#' (disjoint selection), only two targets are supported:
#' \describe{
#'   \item{\code{"list"}}{each area is parsed as its own matrix; the result is a
#'     list of matrices.}
#'   \item{\code{"data.frame"}}{each area is parsed as a data.frame and the
#'     areas are bound column-wise into a single data.frame. Columns of unequal
#'     length are padded with \code{NA} up to the longest column, and duplicate
#'     column names are disambiguated with \code{\link{make.unique}}.}
#' }
#' Any other target raises an error for multi-area input.
#'
#' @param x an \code{"XLRange"} object, or a list of them (multi-area), as
#'   returned by \code{\link{xlGetRange}}.
#' @param as target structure. One of \code{"data.frame"}, \code{"matrix"},
#'   \code{"list"}, \code{"table"}.
#' @param header logical; if \code{TRUE}, the first row is treated as a header
#'   (column names). Ignored for \code{"table"}, which always uses the first
#'   row / column as names.
#' @param convert logical; if \code{TRUE} (default), each column is run through
#'   \code{.xlConvert()} for automatic numeric / Date detection.
#' @param stringsAsFactors logical; passed to \code{\link{data.frame}} for the
#'   \code{"data.frame"} target. Defaults to \code{FALSE}.
#'
#' @return A \code{data.frame}, \code{matrix}, \code{list}, or a matrix with
#'   \code{dimnames} (for \code{"table"}). For a multi-area \code{"list"}, the
#'   returned list carries an \code{address} attribute.
#'
#' @seealso \code{\link{xlGetRange}}, \code{\link{xlImport}}
#'
#' @examples
#' \dontrun{
#' r <- xlGetRange(xl)
#' xlParseRange(r, as = "data.frame", header = TRUE)
#' xlParseRange(r, as = "matrix")
#' xlParseRange(r, as = "table")     # first col = rownames, first row = colnames
#' }
#'
#' @export
xlParseRange <- function(x, as = c("data.frame", "matrix", "list", "table"),
                         header = FALSE, convert = TRUE, stringsAsFactors = FALSE) {

  as <- match.arg(as)

  # ---- Multi-area selection: a list of "XLRange" blocks ---------------------
  if (!inherits(x, "XLRange") && is.list(x) &&
      all(vapply(x, inherits, logical(1), "XLRange"))) {

    if (as == "list") {
      # Each area becomes its own matrix.
      out <- lapply(x, xlParseRange, as = "matrix",
                    header = header, convert = convert,
                    stringsAsFactors = stringsAsFactors)
      attr(out, "address") <- attr(x, "address")
      return(out)
    }

    if (as == "data.frame") {
      # Parse each area as a data.frame, then bind all columns side by side.
      dfs <- lapply(x, xlParseRange, as = "data.frame",
                    header = header, convert = convert,
                    stringsAsFactors = stringsAsFactors)
      # Collect every column across areas, pad to the longest with NA, then
      # combine. `length<-` keeps the vector's class (incl. Date) and pads NA.
      cols  <- unlist(lapply(dfs, as.list), recursive = FALSE)
      nmax  <- max(vapply(cols, length, integer(1)))
      cols  <- lapply(cols, function(cc) `length<-`(cc, nmax))
      out   <- as.data.frame(cols, stringsAsFactors = stringsAsFactors)
      # Disambiguate clashing names (e.g. several "V1" from "no colnames").
      names(out) <- make.unique(names(out))
      return(out)
    }

    stop("Multiple ranges are only supported with as = \"list\" or \"data.frame\".")
  }

  # ---- Single range ---------------------------------------------------------
  nr <- x$nrow; nc <- x$ncol
  vals <- x$values

  # Value2() nests column-wise: vals[[col]][[row]]. Build one R vector per
  # column; NULL cells (empty) become NA.
  cellval <- function(v) if (is.null(v)) NA else v
  cols <- lapply(seq_len(nc), function(j)
    unlist(lapply(seq_len(nr), function(i) cellval(vals[[j]][[i]])),
           use.names = FALSE))

  # table: first row -> colnames, first column -> rownames, corner A1 dropped.
  if (as == "table") {
    if (nr < 2 || nc < 2)
      stop("A table needs at least 2 rows and 2 columns.")
    rn   <- as.character(cols[[1]][-1])                  # left column, no corner
    cn   <- vapply(cols[-1], function(cc) as.character(cc[1]), character(1))
    body <- lapply(cols[-1], function(cc) cc[-1])        # drop header row
    if (convert)
      body <- lapply(body, .xlConvert)
    out <- if (all(vapply(body, is.numeric, logical(1))))
             matrix(unlist(body), nrow = nr - 1, ncol = nc - 1)
           else
             matrix(unlist(lapply(body, as.character)), nrow = nr - 1, ncol = nc - 1)
    dimnames(out) <- list(rn, cn)
    return(out)
  }

  # Split off the header row (column names) if requested.
  hdr <- NULL
  if (isTRUE(header)) {
    hdr  <- vapply(cols, function(cc) as.character(cc[1]), character(1))
    cols <- lapply(cols, function(cc) cc[-1])
    nr   <- nr - 1
  }

  # Automatic per-column type conversion.
  if (convert)
    cols <- lapply(cols, .xlConvert)

  switch(as,
         "matrix" = {
           # Numeric matrix only if every column is numeric, else character.
           out <- if (convert && all(vapply(cols, is.numeric, logical(1))))
             matrix(unlist(cols), nrow = nr, ncol = nc)
           else
             matrix(unlist(lapply(cols, as.character)), nrow = nr, ncol = nc)
           if (!is.null(hdr)) colnames(out) <- hdr
           out
         },
         "list" = {
           if (!is.null(hdr)) names(cols) <- hdr
           cols
         },
         "data.frame" = {
           df <- as.data.frame(cols, stringsAsFactors = stringsAsFactors)
           names(df) <- if (!is.null(hdr)) hdr else paste0("V", seq_len(nc))
           df
         }
  )
}




# == internal helper functions =================================================


#' Automatic Per-Column Type Conversion
#'
#' Best-effort conversion of a single column to a natural R type. Numeric and
#' logical input is returned unchanged (\code{Value2()} already types these);
#' character input is probed for a fully numeric interpretation, then for a
#' textual date in ISO (\code{\%Y-\%m-\%d}) or dotted (\code{\%d.\%m.\%Y})
#' format. If neither matches, the character vector is returned as-is.
#'
#' @param z a single column vector.
#' @return the (possibly converted) column vector.
#' @keywords internal
#' @noRd
.xlConvert <- function(z) {
  # Value2() already returns numeric / logical typed; only character needs work.
  if (is.numeric(z) || is.logical(z)) return(z)

  zc   <- as.character(z)
  nona <- zc[!is.na(zc) & zc != ""]
  if (!length(nona)) return(zc)

  # Fully numeric? (every non-empty entry parses as a number)
  num <- suppressWarnings(as.numeric(zc))
  if (!any(is.na(num) & !is.na(zc) & zc != "")) return(num)

  # Textual date? tryCatch guards against as.Date() erroring on non-dates
  # (it throws for some inputs instead of returning NA).
  d <- tryCatch(
    suppressWarnings(as.Date(zc, tryFormats = c("%Y-%m-%d", "%d.%m.%Y"))),
    error = function(e) rep(NA, length(zc))
  )
  if (!any(is.na(d) & !is.na(zc) & zc != "")) return(d)

  zc
}



#' Constructive Deparser for Readable Code
#'
#' Produces idiomatic, human-readable R code for the common container types
#' (\code{data.frame(...)}, \code{matrix(...)}, \code{list(...)}), unlike
#' \code{deparse()} / \code{dput()}, which emit the internal
#' \code{structure(...)} form. Used to insert code at the editor cursor.
#'
#' @param x object to deparse (data.frame, matrix, list or atomic vector).
#' @return a single character string of R code.
#' @keywords internal
#' @noRd
#'
#' @section Limitations:
#' Date columns are still rendered via \code{deparse()} (i.e. as a
#' \code{structure(..., class = "Date")} expression), since the atomic-vector
#' fallback delegates to \code{deparse()}. If fully readable date code
#' (\code{as.Date(c(...))}) is ever wanted, add an explicit Date branch.
.xlDeparse <- function(x) {

  # Deparse a single atomic vector to a one-line "c(...)" (or scalar).
  vec <- function(v) paste(deparse(v), collapse = "")

  if (is.data.frame(x)) {
    args <- mapply(function(nm, col) paste0(nm, " = ", vec(col)),
                   names(x), x, USE.NAMES = FALSE)
    # stringsAsFactors = FALSE so the round-trip reproduces the same object.
    return(paste0("data.frame(", paste(args, collapse = ", "),
                  ", stringsAsFactors = FALSE)"))
  }

  if (is.matrix(x)) {
    dn <- dimnames(x)
    # Only emit a dimnames argument when at least one dimension is named.
    dimarg <- if (!is.null(dn) && (!is.null(dn[[1]]) || !is.null(dn[[2]])))
                paste0(", dimnames = ", vec(dn))
              else ""
    return(paste0("matrix(", vec(as.vector(x)),
                  ", nrow = ", nrow(x), ", ncol = ", ncol(x),
                  dimarg, ")"))
  }

  if (is.list(x)) {
    nms <- names(x)
    parts <- vapply(seq_along(x), function(i) {
      el <- .xlDeparse(x[[i]])                        # recurse
      if (!is.null(nms) && nzchar(nms[i])) paste0(nms[i], " = ", el) else el
    }, character(1))
    return(paste0("list(", paste(parts, collapse = ", "), ")"))
  }

  # Fallback: atomic vector and everything else (incl. Date -> see Limitations).
  vec(x)
}

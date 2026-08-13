
#' View Objects in Excel
#'
#' Opens a data frame, a matrix, an atomic vector or a list of such objects in
#' Microsoft Excel for interactive inspection.
#'
#' A new workbook and worksheet are created automatically.
#'
#' @param x an object to be displayed: a data frame, a matrix or two-dimensional
#'   table, an atomic vector (with or without names) or a possibly nested list
#'   of these
#' @param sheet optional worksheet name; defaults to the deparsed name of
#'   \code{x}
#' @param rowNames logical or \code{NA}; if \code{TRUE}, row names (resp. the
#'   names of a vector) are written as a leading column. \code{NA} means
#'   automatic: names are written whenever the object carries them.
#' @param table logical; if \code{TRUE}, Excel filters are enabled. Ignored when
#'   the object has no header row and for lists.
#' @param autofit logical; if \code{TRUE}, column widths are adjusted
#'   automatically
#' @param freeze logical; if \code{TRUE}, the first row is frozen. Ignored when
#'   there is no header row and for lists.
#' @param gap integer, list method only; number of empty rows between two
#'   consecutive blocks
#' @param titles logical, list method only; if \code{TRUE}, the element names
#'   are written as a bold label above each block
#' @param xl optional Excel COM object
#' @param \dots further arguments, currently ignored
#'
#' @details
#' Data are transferred column-wise to preserve numeric types. Factors and
#' date-time objects are converted to character vectors.
#'
#' Matrices are written with those dimnames they actually have: a matrix without
#' column names gets no header row, a matrix without row names gets no leading
#' name column. Atomic vectors are written as a single column headed by the
#' deparsed expression.
#'
#' Lists are stacked vertically on one sheet, each element separated by
#' \code{gap} empty rows. Nested lists are indented by one column. Since Excel
#' allows only one autofilter per sheet, \code{table} and \code{freeze} are not
#' available for lists.
#'
#' The workbook is not saved automatically.
#'
#' @return Invisibly returns the worksheet COM object.
#'
#' @examples
#' \dontrun{
#' xlView(iris)
#' xlView(as.matrix(mtcars))
#' xlView(table(d.pizza$driver, d.pizza$area))
#' xlView(rnorm(10))
#' xlView(list(summary = summary(iris$Sepal.Length),
#'             counts  = table(iris$Species),
#'             data    = head(iris)))
#' }
#'
#' @family spreadsheet.utils
#' @concept excel
#' @concept spreadsheet
#' @concept data-inspection
#'
#' @export
xlView <- function(x, sheet = NULL, ...) {

  # evaluated here, so that the methods inherit the deparsed expression
  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  UseMethod("xlView")
}




#' @rdname xlView
#' @export
xlView.data.frame <- function(x,
                              sheet = NULL,
                              rowNames = FALSE,
                              table = TRUE,
                              autofit = TRUE,
                              freeze = TRUE,
                              xl = NULL,
                              ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  .xlViewSingle(
    x,
    sheet = sheet,
    rowNames = rowNames,
    table = table,
    autofit = autofit,
    freeze = freeze,
    xl = xl
  )
}




#' @rdname xlView
#' @export
xlView.matrix <- function(x,
                          sheet = NULL,
                          rowNames = NA,
                          table = TRUE,
                          autofit = TRUE,
                          freeze = TRUE,
                          xl = NULL,
                          ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  .xlViewSingle(
    x,
    sheet = sheet,
    rowNames = rowNames,
    table = table,
    autofit = autofit,
    freeze = freeze,
    xl = xl
  )
}


#' @rdname xlView
#' @export
xlView.table <- xlView.matrix


#' @rdname xlView
#' @export
xlView.array <- xlView.matrix




#' @rdname xlView
#' @export
xlView.default <- function(x,
                           sheet = NULL,
                           rowNames = NA,
                           table = TRUE,
                           autofit = TRUE,
                           freeze = TRUE,
                           xl = NULL,
                           ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  if (!is.atomic(x)) {
    stop("'x' must be a data.frame, a matrix, an atomic vector or a list.",
         call. = FALSE)
  }

  .xlViewSingle(
    x,
    sheet = sheet,
    rowNames = rowNames,
    table = table,
    autofit = autofit,
    freeze = freeze,
    xl = xl,
    name = sheet
  )
}




#' @rdname xlView
#' @export
xlView.list <- function(x,
                        sheet = NULL,
                        rowNames = NA,
                        autofit = TRUE,
                        gap = 2L,
                        titles = TRUE,
                        xl = NULL,
                        ...) {

  if (is.null(sheet)) {
    sheet <- deparse(substitute(x))[1L]
  }

  if (is.data.frame(x)) {
    return(xlView.data.frame(x, sheet = sheet, xl = xl, ...))
  }

  h <- .xlNewSheet(sheet, xl = xl)
  ws <- h$ws

  .xlWriteList(
    ws,
    x,
    row = 1L,
    col = 1L,
    rowNames = rowNames,
    gap = as.integer(gap),
    titles = titles
  )

  if (autofit) {
    ws[["UsedRange"]]$Columns()$AutoFit()
  }

  ws$Activate()

  h$wb[["Saved"]] <- TRUE

  invisible(ws)
}




# ================================================================
# Internal helpers
# ================================================================


#' @keywords internal
#' @noRd
.xlViewSingle <- function(x,
                          sheet,
                          rowNames = NA,
                          table = TRUE,
                          autofit = TRUE,
                          freeze = TRUE,
                          xl = NULL,
                          name = NULL) {

  blk <- .asBlockData(x, rowNames = rowNames, name = name %||% sheet)

  if (is.null(blk)) {
    stop("'x' cannot be represented as a rectangular block.", call. = FALSE)
  }

  h <- .xlNewSheet(sheet, xl = xl)
  ws <- h$ws

  dim <- .xlWriteBlock(
    ws,
    blk$data,
    row = 1L,
    col = 1L,
    header = blk$header
  )

  used <- ws$Range(
    ws$Cells(1, 1),
    ws$Cells(max(dim$rows, 1L), max(dim$cols, 1L))
  )

  # filter and freeze only make sense with a header row
  if (table && blk$header) {
    used$AutoFilter()
  }

  if (autofit) {
    used$Columns()$AutoFit()
  }

  ws$Activate()

  if (freeze && blk$header) {
    .freezeTopRow(h$xl)
  }

  # no save dialogs when leaving...
  h$wb[["Saved"]] <- TRUE

  invisible(ws)
}




#' Create a new workbook with a single named worksheet
#'
#' @keywords internal
#' @noRd
.xlNewSheet <- function(sheet, xl = NULL) {

  if (is.null(xl)) {
    xl <- getXl()
  }

  xl[["Visible"]] <- TRUE

  wb <- xl[["Workbooks"]]$Add()
  ws <- wb$Worksheets(1)

  ws[["Name"]] <- .xlSheetName(sheet)

  list(xl = xl, wb = wb, ws = ws)
}




#' @keywords internal
#' @noRd
.xlSheetName <- function(x) {

  x <- paste(x, collapse = "")
  x <- gsub("[:\\\\/?*\\[\\]]", "_", x)
  x <- substr(x, 1L, 31L)

  if (!nzchar(x)) {
    x <- "Sheet1"
  }

  x
}




#' Write one rectangular block at a given top left cell
#'
#' Returns the number of rows and columns actually occupied, header included.
#'
#' @keywords internal
#' @noRd
.xlWriteBlock <- function(ws, x, row = 1L, col = 1L, header = TRUE) {

  x <- .asExcelDataFrame(x)

  nRow <- nrow(x)
  nCol <- ncol(x)

  if (nCol == 0L) {
    return(invisible(list(rows = 0L, cols = 0L)))
  }

  hdrRow <- as.integer(header)

  # --- header ------------------------------------------------------

  if (header) {

    hdrRng <- ws$Range(
      ws$Cells(row, col),
      ws$Cells(row, col + nCol - 1L)
    )

    hdrRng[["Value"]] <- RDCOMClient::asCOMArray(
      matrix(colnames(x), nrow = 1L)
    )

    font <- hdrRng[["Font"]]

    font[["Bold"]] <- TRUE
    font[["ColorIndex"]] <- 1

    # bottom border, 9 = xlEdgeBottom
    b <- hdrRng$Borders(9)

    b[["LineStyle"]] <- 1
    b[["Weight"]] <- 2
  }

  # --- data, column-wise to preserve types --------------------------

  if (nRow > 0L) {

    for (j in seq_len(nCol)) {

      val <- matrix(x[[j]], ncol = 1L)

      rng <- ws$Range(
        ws$Cells(row + hdrRow, col + j - 1L),
        ws$Cells(row + hdrRow + nRow - 1L, col + j - 1L)
      )

      rng[["Value"]] <- RDCOMClient::asCOMArray(val)
    }
  }

  invisible(list(rows = nRow + hdrRow, cols = nCol))
}




#' Write a list as stacked blocks, recursing into nested lists
#'
#' Returns the next free row.
#'
#' @keywords internal
#' @noRd
.xlWriteList <- function(ws, x, row = 1L, col = 1L,
                         rowNames = NA, gap = 2L, titles = TRUE) {

  nms <- names(x)

  if (is.null(nms)) {
    nms <- rep("", length(x))
  }

  isEmpty <- !nzchar(nms) | is.na(nms)
  nms[isEmpty] <- paste0("[[", which(isEmpty), "]]")

  for (i in seq_along(x)) {

    el <- x[[i]]

    if (titles) {
      .xlWriteLabel(ws, nms[i], row = row, col = col)
      row <- row + 1L
    }

    if (is.list(el) && !is.data.frame(el)) {

      # nested list: indent by one column
      row <- .xlWriteList(
        ws, el,
        row = row, col = col + 1L,
        rowNames = rowNames, gap = gap, titles = titles
      )

      next
    }

    blk <- .asBlockData(el, rowNames = rowNames, name = nms[i])

    if (is.null(blk)) {

      .xlWriteLabel(
        ws,
        paste0("<", paste(class(el), collapse = "/"), ">"),
        row = row, col = col, bold = FALSE
      )

      row <- row + 1L + gap

      next
    }

    dim <- .xlWriteBlock(
      ws, blk$data,
      row = row, col = col,
      header = blk$header
    )

    row <- row + dim$rows + gap
  }

  row
}




#' @keywords internal
#' @noRd
.xlWriteLabel <- function(ws, txt, row, col, bold = TRUE) {

  cell <- ws$Cells(row, col)

  cell[["Value"]] <- txt

  font <- cell[["Font"]]

  font[["Bold"]] <- bold

  invisible(cell)
}




#' Coerce an object to a rectangular block
#'
#' Returns a list with the components \code{data} (a data frame, row names
#' already merged in as a leading column if requested) and \code{header} (should
#' a header row be written), or \code{NULL} if \code{x} has no rectangular
#' representation.
#'
#' @keywords internal
#' @noRd
.asBlockData <- function(x, rowNames = NA, name = "x") {

  auto <- is.na(rowNames)

  # --- data frame ---------------------------------------------------

  if (is.data.frame(x)) {

    d <- x
    header <- TRUE

    useRn <- if (auto) .hasRowNames(x) else isTRUE(rowNames)

    rnVal <- if (useRn) rownames(x) else NULL
    label <- "Row"

    # --- matrix, 2-d table ------------------------------------------

  } else if (length(dim(x)) == 2L) {

    m <- unclass(x)

    d <- as.data.frame(
      m,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    header <- !is.null(colnames(m))

    if (!header) {
      colnames(d) <- rep("", ncol(d))
    }

    useRn <- if (auto) !is.null(rownames(m)) else isTRUE(rowNames)

    rnVal <- if (useRn) {
      if (is.null(rownames(m))) seq_len(nrow(m)) else rownames(m)
    } else {
      NULL
    }

    label <- ""

    # --- n-dimensional array or table, long format ------------------

  } else if (length(dim(x)) > 2L) {

    d <- as.data.frame(
      as.table(provideDimnames(unclass(x))),
      stringsAsFactors = FALSE
    )

    header <- TRUE
    rnVal <- NULL
    label <- ""

    # --- atomic vector ----------------------------------------------

  } else if (is.atomic(x)) {

    d <- data.frame(
      unname(x),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    colnames(d) <- .xlSheetName(name)

    header <- TRUE

    useRn <- if (auto) !is.null(names(x)) else isTRUE(rowNames)

    rnVal <- if (useRn) {
      if (is.null(names(x))) seq_along(x) else names(x)
    } else {
      NULL
    }

    label <- ""

  } else {

    return(NULL)
  }

  # --- merge row names as leading column ----------------------------

  if (!is.null(rnVal)) {

    rnVal <- as.character(rnVal)
    rnVal[is.na(rnVal)] <- ""

    d <- data.frame(
      rnVal,
      d,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    colnames(d)[1L] <- label
  }

  list(data = d, header = header)
}




#' Has the data frame row names worth writing?
#'
#' Automatic row names (the integer sequence) carry no information and are
#' suppressed in the automatic mode.
#'
#' @keywords internal
#' @noRd
.hasRowNames <- function(x) {

  rn <- attr(x, "row.names")

  !is.null(rn) &&
    !is.integer(rn) &&
    !identical(rn, as.character(seq_len(nrow(x))))
}




#' @keywords internal
#' @noRd
.freezeTopRow <- function(xl, n = 1L) {

  win <- xl[["ActiveWindow"]]

  if (is.null(win)) {
    return(invisible(FALSE))
  }

  win[["SplitRow"]] <- n
  win[["FreezePanes"]] <- TRUE

  invisible(TRUE)
}




#' @keywords internal
#' @noRd
.isValidXl <- function(xl) {

  if (is.null(xl)) {
    return(FALSE)
  }

  tryCatch({
    xl[["Name"]]
    TRUE
  }, error = function(e) FALSE)
}




#' Coerce column types to something Excel can swallow
#'
#' @keywords internal
#' @noRd
.asExcelDataFrame <- function(x, rowNames = FALSE) {

  x <- as.data.frame(
    x,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  x[] <- lapply(x, function(z) {

    if (inherits(z, c("factor", "POSIXct", "POSIXlt", "Date", "difftime"))) {
      z <- as.character(z)
    }

    if (!is.atomic(z)) {
      z <- as.character(z)
    }

    z
  })

  if (rowNames) {

    x <- data.frame(
      Row = rownames(x),
      x,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  x
}

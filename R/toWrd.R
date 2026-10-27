
#' Insert Content into Microsoft Word
#'
#' Inserts content into an active Microsoft Word document via RDCOMClient.
#' The function supports different input types and dispatches methods based
#' on the class of \code{x}.
#'
#' @param x Object to be written to Word. Supported types include character
#'   vectors and arbitrary objects (converted via \code{capture}-like behavior).
#' @param font Optional font specification (list or object of class \code{"font"}).
#'   If \code{"fix"}, a fixed-width font is used.
#' @param ... Additional arguments passed to methods. A \code{bookmark}
#'   argument is handled by the generic for all methods, see Bookmarks.
#' @param wrd A Word COM object. Defaults to the last active Word instance.
#'
#' @return Invisibly the result of the method, with \code{bookmark} the
#'   bookmark name.
#'
#' @section Bookmarks:
#' With \code{bookmark = "name"} the output is enclosed in a Word bookmark.
#' If the bookmark already exists in the document, its content (text and
#' tables) is replaced in place. Re-running the same call, e.g. the whole
#' analysis script, thus updates the report instead of appending to it.
#' \code{bookmark = TRUE} creates a new name (\code{"bmt"}, for plots
#' \code{"bmp"}, followed by 9 digits), returned invisibly. Names must start with a letter and consist
#' of at most 40 letters, digits and underscores.
#'
#' @details
#' The function inserts text into the current selection of a Word document.
#' Character input is inserted directly, while other objects are first converted
#' to text using an internal capture mechanism.
#'
#' Formatting options such as paragraph style, font, and bullet lists can be
#' applied via method-specific arguments.
#'
#' @examples
#' \dontrun{
#' toWrd("Hello World")
#' toWrd(1:10)
#' toWrd(c("Line 1", "Line 2"), bullet = TRUE)
#'
#' # updatable output: the second call replaces the first table
#' toWrd(head(mtcars), bookmark = "bmtCars")
#' toWrd(tail(mtcars), bookmark = "bmtCars")
#' }
#'
#' @export
toWrd <- function(x, font = NULL, ..., wrd = NULL) {

  # bookmark is handled here once for all methods: call the generic again
  # without it, enclose the output and replace an existing bookmark
  dots <- list(...)
  if (!is.null(dots[["bookmark"]])) {
    args <- c(list(x), if (!missing(font)) list(font = font),
              dots[names(dots) != "bookmark"])
    prefix <- if (inherits(x, .wrdPlotClasses)) "bmp" else "bmt"
    return(.toWrdBookmark(args, dots[["bookmark"]], prefix = prefix, wrd = wrd))
  }

  UseMethod("toWrd")
}

#' @rdname toWrd
#' @method toWrd default
#' @export
toWrd.default <- function(x, font = NULL, ..., wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  toWrd.character(x = .captOut(x), font = font, ..., wrd = wrd)
  invisible()
}


#' @param para paragraph format
#' @param style style template name
#' @param bullet for bullet style
#' @rdname toWrd
#' @method toWrd character
#' @export
toWrd.character <- function(x, font = NULL, para = NULL, 
                            style = NULL, bullet=FALSE, ..., wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  .wrdInsertAfter(paste(x, collapse = "\n"), wrd = wrd)
  
  if (!is.null(style))
    wrdStyle(wrd) <- style
  
  if (!is.null(para))
    wrdPara(wrd) <- para
  
  
  if(identical(font, "fix")){
    # font <- DescToolsOptions("fixedfont")
    font <- NULL
    if(is.null(font))
      font <- structure(list(name="Courier New", size=8), class="font")
  }
  
  if(!is.null(font)){
    currfont <- wrdFont(wrd)
    wrdFont(wrd) <- font
    on.exit(wrdFont(wrd) <- currfont)
  }
  
  if(bullet)
    wrd[["Selection"]]$Range()$ListFormat()$ApplyBulletDefault()
  
  wrd[["Selection"]]$Collapse(Direction=wdConst$wdCollapseEnd)
  
  invisible()
  
}



# == internal helper functions =============================================


#' @noRd
.toWrdBookmark <- function(args, bookmark, prefix = "bmt", wrd) {

  name <- .wrdBookmarkName(bookmark, prefix)
  wrd  <- .resolveWrd(wrd)
  doc  <- wrd[["ActiveDocument"]]
  bms  <- doc[["Bookmarks"]]

  # existing bookmark: clear its content, write at its position
  if (bms$Exists(name)) {
    rng <- bms$Item(name)[["Range"]]
    .wrdClearRange(rng)
    rng$Select()
  }

  sel <- wrd[["Selection"]]
  sel$Collapse(Direction = wdConst$wdCollapseEnd)
  start <- sel[["Start"]]

  res <- do.call(toWrd, c(args, list(wrd = wrd)))

  # the methods leave the cursor collapsed behind their output
  end <- wrd[["Selection"]][["Start"]]
  bms$Add(name, doc$Range(start, end))

  invisible(structure(name, result = res))
}


#' @noRd
.wrdBookmarkName <- function(bookmark, prefix = "bmt") {
  # the prefix tells the RStudio addins the type: "bmt" text, "bmp" plot
  if (isTRUE(bookmark))
    bookmark <- paste0(prefix, paste(sample(0:9, 9L, replace = TRUE),
                                     collapse = ""))
  # Word: starts with a letter, max. 40 letters, digits or underscores
  if (!is.character(bookmark) || length(bookmark) != 1L ||
      !grepl("^[A-Za-z][A-Za-z0-9_]{0,39}$", bookmark))
    stop("bookmark must be TRUE or a name starting with a letter, with at ",
         "most 40 letters, digits and underscores", call. = FALSE)
  bookmark
}


#' @noRd
.wrdClearRange <- function(rng) {
  # Range$Delete() empties table cells but leaves the table, so delete the
  # tables first (from the last), then the remaining text
  tabs <- rng[["Tables"]]
  for (i in rev(seq_len(tabs[["Count"]])))
    tabs$Item(i)$Delete()
  # a collapsed range would delete the following character
  if (rng[["End"]] > rng[["Start"]]) rng$Delete()
  invisible()
}


#' @noRd
.wrdInsertAfter <- function(x, wrd){

  # insert at the selection and return the inserted range (selected).
  # Unicode safe with RDCOMClient >= r46-unicode, older versions appended
  # garbage characters after non-ASCII text.
  wrd[["Selection"]]$InsertAfter(paste(x, collapse = "\n"))
  invisible(wrd[["Selection"]]$Range())
}

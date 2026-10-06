
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
#' @param ... Additional arguments passed to methods.
#' @param wrd A Word COM object. Defaults to the last active Word instance.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @details
#' The function inserts text into the current selection of a Word document.
#' Character input is inserted directly, while other objects are first converted
#' to text using an internal capture mechanism.
#'
#' UTF-8 strings may be converted to Latin-1 depending on system locale to avoid
#' encoding issues in Word.
#'
#' Formatting options such as paragraph style, font, and bullet lists can be
#' applied via method-specific arguments.
#'
#' @examples
#' \dontrun{
#' toWrd("Hello World")
#' toWrd(1:10)
#' toWrd(c("Line 1", "Line 2"), bullet = TRUE)
#' }
#'
#' @export
toWrd <- function(x, font = NULL, ..., wrd = NULL) {
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
  
  # we will convert UTF-8 strings to Latin-1, if the local info is Latin-1
  if (any(l10n_info()[["Latin-1"]] & Encoding(x) == "UTF-8"))
    x[Encoding(x) == "UTF-8"] <- iconv(x[Encoding(x) == "UTF-8"], 
                                       from = "UTF-8", to = "latin1")
  
  # handle garbage of special characters inserted on the 
  # existance of non ASCII characters
  # wrd[["Selection"]]$InsertAfter(paste(x, collapse = "\n"))
  
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
.wrdInsertAfter <- function(x, remove=TRUE, wrd){
  
  # RDCOMClient together with InsertAfter inserts a number of 
  # special characters at the end of the inserted text, as soon 
  # as the the text contains non ascii characters.
  # 
  # As we see no solution to avoid this, we try to remove the characters here
  # by typing backspace.
  
  # example
  # xx <- do.call(gettextf, as.list(c("m\U00A0=\U00A0%s, 
  #               f\U00A0=\U00A0%s", fm(c(0.568,0.432), fmt="%", d=1))))
  
  # Test with: no correction
  # .wrdInsertAfter(xx, remove=FALSE)  
  # with correction
  # .wrdInsertAfter(xx)  
  
  
  wrd[["Selection"]]$InsertAfter(paste(x, collapse = "\n"))
  res <- wrd[["Selection"]]$Range()
  
  if (remove && getOption("wrdinsert_rm_garbage", TRUE)){
    
    # remove selection
    wrd[["Selection"]]$Collapse(Direction = wdConst$wdCollapseEnd)
    
    # Now deleting the special characters
    if((j <- .countNonASCII(x)) > 0){
      sapply(seq(j), 
             function(i) wrd[["Selection"]]$TypeBackspace())
    }
    res$Select()
    
  }
  
  invisible(res)
  
}


.countNonASCII <- function(x){
  nchar(x) - nchar(iconv(x, "UTF-8", "ASCII", ""))
}



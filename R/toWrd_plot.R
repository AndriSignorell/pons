#' Plots for Word
#'
#' \code{wrdPlot()} captures plotting code for \code{\link{toWrd}()}, which
#' renders it to a picture of the requested size and inserts it into Word.
#' Besides such captured code, \code{toWrd()} accepts recorded base graphics
#' (\code{\link[grDevices]{recordPlot}()}, e.g. the current plot in RStudio),
#' \pkg{ggplot2} and \pkg{lattice} objects.
#'
#' The plot is drawn anew on a file device of the requested size, so fonts
#' and symbols keep their size in the document, independently of the size
#' of the screen device. Like all output of \code{toWrd()} a plot can be
#' placed in an updatable bookmark (\code{bookmark = "name"}); a generated
#' name starts with \code{"bmp"}.
#'
#' @param expr plotting code, e.g. \code{{hist(x); abline(v = 0)}}. Not
#'   evaluated by \code{wrdPlot()}. A visible \code{ggplot} or
#'   \code{trellis} result is printed.
#' @param env environment in which \code{expr} is evaluated.
#'
#' @return \code{wrdPlot()}: an object of class \code{"WrdPlot"}.
#'
#' @seealso \code{\link{toWrd}}
#' @examples
#' \dontrun{
#' toWrd(wrdPlot(hist(rnorm(100))), width = 12)
#'
#' plot(cars); abline(lm(dist ~ speed, cars))
#' toWrd(recordPlot(), bookmark = "bmpCars")      # the current plot
#'
#' # vector graphics, picture left aligned
#' toWrd(wrdPlot(boxplot(count ~ spray, InsectSprays)), type = "emf",
#'       align = "l")
#' }
#' @export
wrdPlot <- function(expr, env = parent.frame()) {
  structure(list(expr = substitute(expr), env = env), class = "WrdPlot")
}


#' @param width,height size of the picture in cm. \code{height} defaults to
#'   \code{width * asp}.
#' @param asp aspect ratio height/width used for the default height.
#' @param type file format: \code{"png"} (default), \code{"emf"} (vector,
#'   Windows) or \code{"svg"} (vector, Word 2016 or later).
#' @param res resolution of png pictures in dpi.
#' @param pointsize base font size of the plot.
#' @param newpara logical, end a picture with a paragraph mark (the text
#'   following it starts on a new line with the former alignment).
#' @details Pictures: \code{align} is one of \code{"c"} (default),
#'   \code{"l"} or \code{"r"}.
#' @rdname toWrd
#' @method toWrd WrdPlot
#' @export
toWrd.WrdPlot <- function(x, font = NULL, width = 15, height = NULL,
                          asp = 2/3, type = c("png", "emf", "svg"),
                          res = 300, pointsize = 10, align = "c",
                          newpara = TRUE, ..., wrd = NULL) {

  .toWrdPicture(.wrdDrawFun(x), width = width, height = height, asp = asp,
                type = match.arg(type), res = res, pointsize = pointsize,
                align = align, newpara = newpara, wrd = wrd)
}

#' @rdname toWrd
#' @method toWrd recordedplot
#' @export
toWrd.recordedplot <- toWrd.WrdPlot

#' @rdname toWrd
#' @method toWrd ggplot
#' @export
toWrd.ggplot <- toWrd.WrdPlot

#' @rdname toWrd
#' @method toWrd trellis
#' @export
toWrd.trellis <- toWrd.WrdPlot



# == internal helper functions =============================================

# classes written as pictures (bookmark prefix "bmp")
.wrdPlotClasses <- c("WrdPlot", "recordedplot", "ggplot", "trellis")


#' @noRd
.wrdDrawFun <- function(x) {
  # a function drawing x on the current device
  if (inherits(x, "recordedplot"))
    return(function() grDevices::replayPlot(x))
  if (inherits(x, c("ggplot", "trellis")))
    return(function() print(x))
  # WrdPlot: evaluate the code, print visible grid based results
  function() {
    v <- withVisible(eval(x$expr, x$env))
    if (v$visible && inherits(v$value, c("ggplot", "trellis")))
      print(v$value)
    invisible()
  }
}


#' @noRd
.wrdRenderPlot <- function(draw, file, type = "png", width = 15,
                           height = 10, res = 300, pointsize = 10) {
  # draw on a file device of the given size (cm)
  w <- width / 2.54
  h <- height / 2.54
  switch(type,
    png = grDevices::png(file, width = w, height = h, units = "in",
                         res = res, pointsize = pointsize),
    svg = grDevices::svg(file, width = w, height = h, pointsize = pointsize),
    emf = grDevices::win.metafile(file, width = w, height = h,
                                  pointsize = pointsize),
    stop("unknown type: ", type)
  )
  dev <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(dev))
  draw()
  invisible(file)
}


#' @noRd
.toWrdPicture <- function(draw, width = 15, height = NULL, asp = 2/3,
                          type = "png", res = 300, pointsize = 10,
                          align = "c", newpara = TRUE, wrd = NULL) {

  alg <- c(l = 0L, c = 1L, r = 2L)                  # wdAlignParagraph*
  stopifnot(is.numeric(width), width > 0, align %in% names(alg))
  if (is.null(height)) height <- width * asp

  # render first: a plotting error must not leave traces in the document
  file <- tempfile(fileext = paste0(".", type))
  on.exit(unlink(file))
  .wrdRenderPlot(draw, file, type = type, width = width, height = height,
                 res = res, pointsize = pointsize)

  wrd <- .resolveWrd(wrd)
  sel <- wrd[["Selection"]]
  sel$Collapse(Direction = wdConst$wdCollapseEnd)
  oldalign <- sel[["ParagraphFormat"]][["Alignment"]]

  shp <- sel[["InlineShapes"]]$AddPicture(FileName = normalizePath(file),
                                          LinkToFile = FALSE,
                                          SaveWithDocument = TRUE)
  shp[["LockAspectRatio"]] <- FALSE
  shp[["Width"]]  <- cmToPts(width)
  shp[["Height"]] <- cmToPts(height)

  rng <- shp$Range()
  pf  <- rng[["ParagraphFormat"]]
  pf[["Alignment"]] <- alg[[align]]

  # cursor behind the picture
  end <- rng[["End"]]
  wrd[["ActiveDocument"]]$Range(end, end)$Select()

  if (newpara) {
    sel <- wrd[["Selection"]]
    sel$TypeParagraph()
    npf <- sel[["ParagraphFormat"]]
    npf[["Alignment"]] <- oldalign
  }

  invisible(shp)
}

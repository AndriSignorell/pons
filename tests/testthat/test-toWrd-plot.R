pngDim <- function(f) {
  # width and height from the IHDR chunk of a png file
  b <- readBin(f, "raw", 24L)
  c(readBin(b[17:20], "integer", endian = "big"),
    readBin(b[21:24], "integer", endian = "big"))
}

render <- function(x, ...) {
  f <- tempfile(fileext = ".png")
  pons:::.wrdRenderPlot(pons:::.wrdDrawFun(x), f, ...)
  f
}


test_that("wrdPlot captures the code without evaluating it", {
  hit <- FALSE
  p <- wrdPlot({hit <- TRUE; plot(1:3)})
  expect_s3_class(p, "WrdPlot")
  expect_false(hit)
  expect_identical(p$env, environment())
})

test_that("captured code is drawn in its environment at the given size", {
  y <- c(3, 1, 2)
  f <- render(wrdPlot(plot(y)), width = 7.62, height = 5.08, res = 50)
  on.exit(unlink(f))
  expect_identical(pngDim(f), c(150L, 100L))        # 3 x 2 inch
})

test_that("recorded base graphics are replayed", {
  grDevices::pdf(NULL); dev <- grDevices::dev.cur()
  grDevices::dev.control("enable")                  # display list
  graphics::plot(1:10)
  rp <- grDevices::recordPlot()
  grDevices::dev.off(dev)

  f <- render(rp, width = 5.08, height = 5.08, res = 72)
  on.exit(unlink(f))
  expect_gt(file.size(f), 0)
  expect_identical(pngDim(f), c(144L, 144L))     # 2 inch * 72
})

test_that("lattice and ggplot objects are printed", {
  skip_if_not_installed("lattice")
  f <- render(lattice::xyplot(1:3 ~ 1:3), width = 5, height = 4, res = 50)
  on.exit(unlink(f))
  expect_gt(file.size(f), 0)

  skip_if_not_installed("ggplot2")
  g <- ggplot2::ggplot(data.frame(x = 1:3), ggplot2::aes(x, x)) +
    ggplot2::geom_point()
  f2 <- render(g, width = 5, height = 4, res = 50)
  expect_gt(file.size(f2), 0)
  unlink(f2)
})

test_that("a visible lattice result of captured code is printed", {
  skip_if_not_installed("lattice")
  drawn <- FALSE
  local_mocked_bindings(print = function(x, ...) drawn <<- TRUE,
                        .package = "base")
  pons:::.wrdDrawFun(wrdPlot(lattice::xyplot(1 ~ 1)))()
  expect_true(drawn)
})

test_that("the device is closed even if the plot fails", {
  n <- length(grDevices::dev.list())
  f <- tempfile(fileext = ".png")
  expect_error(pons:::.wrdRenderPlot(function() stop("boom"), f), "boom")
  expect_identical(length(grDevices::dev.list()), n)
  unlink(f)
})

test_that("svg is supported, unknown types are rejected", {
  skip_if_not(capabilities("cairo"))
  f <- tempfile(fileext = ".svg"); on.exit(unlink(f))
  pons:::.wrdRenderPlot(function() plot(1), f, type = "svg", width = 5,
                        height = 5)
  expect_match(readLines(f, n = 2L)[1:2], "svg|xml", all = FALSE)
  expect_error(pons:::.wrdRenderPlot(function() NULL, f, type = "gif"),
               "unknown type")
})


# == insertion into Word (fake COM) ===========================================

fakePicDoc <- function() {
  st <- fakeCOM(file = NULL, exists = NA, align = list(), typed = 0L,
                selected = NULL)
  pf  <- function(tag) {
    e <- fakeCOM(Alignment = 3L)                    # justified before
    makeActiveBinding("Alignment", local({
      v <- 3L
      function(x) if (missing(x)) v else { v <<- x; st$align[[tag]] <- x }
    }), e2 <- fakeCOM())
    e2
  }
  pfPic <- pf("picture"); pfNew <- pf("new")
  shp <- fakeCOM(Range = function() fakeCOM(End = 42, ParagraphFormat = pfPic))
  sel <- fakeCOM(
    Collapse = function(...) NULL,
    ParagraphFormat = pf("old"),
    InlineShapes = fakeCOM(AddPicture = function(FileName, ...) {
      st$file <- FileName; st$exists <- file.exists(FileName); shp
    }),
    TypeParagraph = function() {
      st$typed <- st$typed + 1L
      assign("ParagraphFormat", pfNew, envir = sel)
    })
  doc <- fakeCOM(Range = function(s, e)
    fakeCOM(Select = function() st$selected <- c(s, e)))
  list(wrd = fakeCOM(Selection = sel, ActiveDocument = doc), st = st, shp = shp)
}

test_that("the picture is inserted with its size, aligned, cursor behind", {
  fd <- fakePicDoc()
  local_mocked_bindings(.resolveWrd = function(wrd) fd$wrd)

  shp <- toWrd(wrdPlot(plot(1:3)), width = 10, height = 5, res = 30)

  expect_true(fd$st$exists)                         # rendered before insert
  expect_false(file.exists(fd$st$file))             # temp file removed
  expect_identical(shp$Width, cmToPts(10))
  expect_identical(shp$Height, cmToPts(5))
  expect_identical(fd$st$align$picture, 1L)         # centred
  expect_identical(fd$st$selected, c(42, 42))
  expect_identical(fd$st$typed, 1L)
  expect_identical(fd$st$align$new, 3L)             # former alignment back
})

test_that("height from asp, left alignment, no paragraph", {
  fd <- fakePicDoc()
  local_mocked_bindings(.resolveWrd = function(wrd) fd$wrd)

  shp <- toWrd(wrdPlot(plot(1)), width = 9, asp = 0.5, res = 30,
               align = "l", newpara = FALSE)
  expect_identical(shp$Height, cmToPts(4.5))
  expect_identical(fd$st$align$picture, 0L)
  expect_identical(fd$st$typed, 0L)
})

test_that("a failing plot leaves the document untouched", {
  fd <- fakePicDoc()
  local_mocked_bindings(.resolveWrd = function(wrd) fd$wrd)
  expect_error(toWrd(wrdPlot(stop("no plot"))), "no plot")
  expect_null(fd$st$file)
})

test_that("invalid arguments are rejected", {
  local_mocked_bindings(.resolveWrd = function(wrd) stop("Word touched"))
  expect_error(toWrd(wrdPlot(plot(1)), align = "d"))
  expect_error(toWrd(wrdPlot(plot(1)), width = -1))
  expect_error(toWrd(wrdPlot(plot(1)), type = "gif"))
})

test_that("generated bookmark names of plots start with bmp", {
  rec <- new.env()
  local_mocked_bindings(
    .toWrdBookmark = function(args, bookmark, prefix, wrd)
      rec$name <- pons:::.wrdBookmarkName(bookmark, prefix))
  toWrd(wrdPlot(plot(1)), bookmark = TRUE)
  expect_match(rec$name, "^bmp[0-9]{9}$")
  toWrd("text", bookmark = TRUE)
  expect_match(rec$name, "^bmt[0-9]{9}$")
})

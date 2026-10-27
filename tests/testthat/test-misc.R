test_that("cmToPts and ptsToCm are inverse", {
  expect_equal(cmToPts(1), 28.35)
  expect_equal(ptsToCm(28.35), 1)
  expect_equal(ptsToCm(cmToPts(c(0, 2.54, 10))), c(0, 2.54, 10))
})

test_that("nbsp is the non-breaking space", {
  expect_identical(nbsp, "\u{00A0}")
})

test_that(".captOut captures printed output of visible values only", {
  co <- pons:::.captOut
  expect_identical(co(1:3), "[1] 1 2 3")
  expect_identical(co(invisible(5)), character(0))
  expect_identical(co(1, "a"), c("[1] 1", "[1] \"a\""))

  x <- 7
  f <- function() { y <- 8; co(x + y) }
  expect_identical(f(), "[1] 15")                       # caller's frame
})

test_that(".captOut honours width and restores options and sinks", {
  w <- getOption("width"); n <- sink.number()
  out <- pons:::.captOut(1:30, width = 20)
  expect_gt(length(out), 1L)
  expect_identical(getOption("width"), w)
  expect_identical(sink.number(), n)
})

test_that(".captOut writes to files and connections", {
  f <- tempfile(); on.exit(unlink(f))
  expect_null(pons:::.captOut(1, file = f))
  pons:::.captOut(2, file = f, append = TRUE)
  expect_identical(readLines(f), c("[1] 1", "[1] 2"))
  expect_error(pons:::.captOut(1, file = 3), "'file' must be")
})

test_that("local options are prefixed with the package name", {
  old <- options(pons.testopt = NULL)
  on.exit(options(old))
  expect_identical(pons:::.getOptionLocal("testopt", "def"), "def")
  pons:::.setOptionLocal(testopt = 42)
  expect_identical(getOption("pons.testopt"), 42)
  expect_identical(pons:::.getOptionLocal("testopt"), 42)
  expect_error(pons:::.setOptionLocal())
})

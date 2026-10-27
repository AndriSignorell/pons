d <- data.frame(Coefficients = c("(Intercept)", "Age", "MPR"),
                "With MPR"   = c("-5.248 ***", "0.430 ***", "0.467 ***"),
                "Without"    = c("-4.073 ***", "0.384 ***", NA),
                check.names  = FALSE)

test_that(".wrdTabCells returns trimmed character cells and the header", {
  cl <- pons:::.wrdTabCells(d)
  expect_identical(cl$header, c("Coefficients", "With MPR", "Without"))
  expect_true(is.matrix(cl$body))
  expect_identical(dim(cl$body), c(3L, 3L))
  expect_identical(cl$body[[1, 2]], "\u{2212}5.248 ***")
  expect_identical(cl$body[[3, 3]], "")                  # NA -> na
})

test_that("na, symbols = FALSE and a custom map are honoured", {
  cl <- pons:::.wrdTabCells(d, symbols = FALSE, na = "-")
  expect_identical(cl$body[[1, 2]], "-5.248 ***")
  expect_identical(cl$body[[3, 3]], "-")

  cl <- pons:::.wrdTabCells(d, symbols = c("\\*" = "+"))
  expect_identical(cl$body[[2, 2]], "0.430 +++")
})

test_that("tabs and line breaks cannot split cells or rows", {
  x <- data.frame("a\tb" = c(" x\ty ", "1\r\n2"), check.names = FALSE)
  cl <- pons:::.wrdTabCells(x)
  expect_false(any(grepl("[\t\r\n]", c(cl$header, cl$body))))
  expect_identical(cl$body[[1, 1]], "x y")                # trimmed first
})

test_that("numeric, factor and logical columns become character", {
  x <- data.frame(n = c(1.5, NA), f = factor(c("u", "v")), l = c(TRUE, FALSE))
  cl <- pons:::.wrdTabCells(x)
  expect_type(cl$body, "character")
  expect_identical(unname(cl$body[, "f"]), c("u", "v"))
  expect_identical(cl$body[[2, "n"]], "")
  expect_false(any(grepl("^ | $", cl$body)))           # no format() padding
})

test_that("one-row and one-column data.frames keep their shape", {
  cl <- pons:::.wrdTabCells(d[1, ])
  expect_identical(dim(cl$body), c(1L, 3L))
  cl <- pons:::.wrdTabCells(d[, 1, drop = FALSE])
  expect_identical(dim(cl$body), c(3L, 1L))
})

test_that(".wrdTabLines builds one tab separated line per row", {
  ln <- pons:::.wrdTabLines(pons:::.wrdTabCells(d))
  expect_length(ln, 4L)
  expect_identical(ln[1], "Coefficients\tWith MPR\tWithout")
  expect_identical(ln[4], "MPR\t0.467 ***\t")
  expect_true(all(lengths(strsplit(paste0(ln, "\t."), "\t")) == 4L))

  ln0 <- pons:::.wrdTabLines(pons:::.wrdTabCells(d[0, ]))
  expect_identical(ln0, "Coefficients\tWith MPR\tWithout")
})

test_that(".decTabPos centres the content block on the decimal position", {
  # colwidth 100, size 10: pad 10.8, glyph width 5
  # "1.23": 1 char left, 3 right -> (89.2 + (1 - 3) * 5) / 2
  expect_equal(pons:::.decTabPos("1.23", 100, 10), 39.6)
  expect_equal(pons:::.decTabPos(c("1.23", "-12.5 ***"), 100, 10),
               (89.2 + (3 - 6) * 5) / 2)
  # no decimal point: everything counts as left part
  expect_equal(pons:::.decTabPos("12", 100, 10), (89.2 + 2 * 5) / 2)
  # empty cells are ignored, all empty -> middle of the text area
  expect_equal(pons:::.decTabPos(c("", "1.23"), 100, 10), 39.6)
  expect_equal(pons:::.decTabPos(c("", ""), 100, 10), 89.2 / 2)
  # never negative
  expect_equal(pons:::.decTabPos("1.2345678901234567890", 20, 10), 0)
})

test_that(".decTabPos grows with the left and shrinks with the right part", {
  p <- function(x) pons:::.decTabPos(x, 100, 10)
  expect_gt(p("123.4"), p("1.4"))
  expect_lt(p("1.4 ***"), p("1.4"))
})

test_that(".wrdSpacing sets the paragraph format in points", {
  pf <- fakeCOM()
  pons:::.wrdSpacing(pf, c(before = 1, after = 0, line = 1.25))
  expect_identical(pf$SpaceBefore, 1)
  expect_identical(pf$SpaceAfter, 0)
  expect_identical(pf$LineSpacingRule, 5L)          # wdLineSpaceMultiple
  expect_identical(pf$LineSpacing, 15)              # 12 pt per line

  pf <- fakeCOM()
  pons:::.wrdSpacing(pf, c(before = 6, after = NA, line = NA))
  expect_identical(pf$SpaceBefore, 6)
  expect_false(exists("SpaceAfter", pf, inherits = FALSE))
  expect_false(exists("LineSpacing", pf, inherits = FALSE))
})

test_that(".wrdBorder sets style and width of the requested borders", {
  tab <- fakeTable(2)
  pons:::.wrdBorder(tab$Rows(1), c(-1L, -3L))
  b <- tab$rows[[1]]$borders
  expect_named(b, c("-1", "-3"))
  expect_identical(b[["-1"]]$LineStyle, 1L)
  expect_identical(b[["-3"]]$LineWidth, 4L)
  expect_length(tab$rows[[2]]$borders, 0L)
})

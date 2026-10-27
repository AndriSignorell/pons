# The table methods only prepare a data.frame for toWrd.data.frame(), which
# is mocked here: the tests check what would be sent to Word.

capture_df <- function(env = parent.frame()) {
  rec <- new.env()
  local_mocked_bindings(
    .resolveWrd      = function(wrd) "WRD",
    toWrd.data.frame = function(x, ..., wrd = NULL) {
      rec$x <- x; rec$args <- list(...); rec$wrd <- wrd
      invisible(fakeTable(nrow(x) + 1L))
    },
    toWrd.character  = function(x, ..., wrd = NULL) {
      rec$text <- x; rec$targs <- list(...)
      invisible()
    },
    .env = env
  )
  rec
}


# == toWrd.data.frame: text sent to Word ====================================

test_that("toWrd.data.frame inserts header + rows and converts to a table", {
  rec <- new.env()
  local_mocked_bindings(
    .resolveWrd     = function(wrd) "WRD",
    .wrdInsertRange = function(txt, wrd) {
      rec$txt <- txt
      fakeCOM(ConvertToTable = function(...) {
        rec$conv <- list(...)
        stop("stop after conversion")
      })
    }
  )
  d <- data.frame(a = c("x", "y"), b = c("-1.5", NA))
  expect_error(toWrd(d), "stop after conversion")
  expect_identical(rec$txt, "a\tb\rx\t\u{2212}1.5\ry\t")
  expect_identical(rec$conv, list(Separator = 1L, NumRows = 3L, NumColumns = 2L))
})

test_that("toWrd.data.frame rejects invalid alignments before touching Word", {
  local_mocked_bindings(
    .resolveWrd     = function(wrd) "WRD",
    .wrdInsertRange = function(txt, wrd) stop("Word touched")
  )
  d <- data.frame(a = 1, b = 2)
  expect_error(toWrd(d, align = c("l", "x")), "align")
  expect_error(toWrd(d, halign = "d"), "halign")
})


# == matrix ===================================================================

test_that("a matrix with dimnames gets a row name column", {
  rec <- capture_df()
  m <- matrix(c(1.5, 2, 3.25, NA), 2,
              dimnames = list(grp = c("a", "b"), c("x", "y")))
  toWrd(m, wrd = "W")

  expect_identical(names(rec$x), c("grp", "x", "y"))
  expect_identical(rec$x$grp, c("a", "b"))
  expect_identical(rec$x$x, c("1.50", "2.00"))           # common decimals
  expect_identical(rec$x$y[2], NA_character_)            # NA kept for na=
  expect_identical(rec$args$align, c("l", "d", "d"))
  expect_identical(rec$wrd, "W")
})

test_that("matrix options: rownames, rowtitle, digits, align, font", {
  rec <- capture_df()
  m <- matrix(c(pi, exp(1)), 1, dimnames = list("r1", c("p", "e")))

  toWrd(m, rownames = FALSE)
  expect_identical(names(rec$x), c("p", "e"))
  expect_identical(rec$args$align, c("d", "d"))

  toWrd(m, rowtitle = "Row", digits = 2)
  expect_identical(names(rec$x)[1], "Row")
  expect_identical(rec$x$p, "3.1")

  toWrd(m, align = "r", font = list(name = "Arial", size = 8))
  expect_identical(rec$args$align, "r")
  expect_identical(rec$args$font, list(name = "Arial", size = 8))
})

test_that("a matrix without dimnames gets empty headers and no row column", {
  rec <- capture_df()
  toWrd(matrix(1:4, 2))
  expect_identical(names(rec$x), c("", ""))
  expect_identical(rec$x[[1]], c("1", "2"))

  toWrd(matrix(1:4, 2), rownames = TRUE)                 # forced, but none
  expect_identical(rec$x[[1]], c("", ""))
})

test_that("a character matrix is passed unchanged, duplicated names kept", {
  rec <- capture_df()
  m <- matrix(c(" a", "b", "c", "d"), 2, dimnames = list(NULL, c("v", "v")))
  toWrd(m)
  expect_identical(names(rec$x), c("v", "v"))
  expect_identical(rec$x[[1]], c(" a", "b"))
})


# == table ====================================================================

test_that("a 1-dimensional table becomes a frequency column", {
  rec <- capture_df()
  toWrd(table(cyl = c(4, 4, 6, 8, 8, 8)))
  expect_identical(names(rec$x), c("cyl", "Freq"))
  expect_identical(rec$x$cyl, c("4", "6", "8"))
  expect_identical(rec$x$Freq, c("2", "1", "3"))

  toWrd(table(c("a", "b")), freqtitle = "n")
  expect_identical(names(rec$x), c("", "n"))
})

test_that("a 2-dimensional table is written like a matrix", {
  rec <- capture_df()
  tab <- table(g = c("a", "a", "b"), h = c("x", "y", "y"))
  toWrd(tab)
  expect_identical(names(rec$x), c("g", "x", "y"))
  expect_identical(rec$x$x, c("1", "0"))

  toWrd(prop.table(tab, 1), digits = 2)
  expect_identical(rec$x$y, c("0.5", "1.0"))
})

test_that("higher dimensional tables are flattened, font is passed on", {
  rec <- capture_df()
  tab <- table(a = c(1, 1, 2), b = c("u", "v", "v"), c = c("p", "p", "q"))
  toWrd(tab, font = list(name = "Arial", size = 9))
  expect_identical(nrow(rec$x), 4L)                      # a x b combinations
  expect_identical(ncol(rec$x), 3L)                      # row names + c levels
  expect_identical(rec$args$font, list(name = "Arial", size = 9))
})


# == TOne =====================================================================

tone <- function(legend = TRUE) {
  m <- rbind(c("n",     "8",         "4 (50.0%)",  "4 (50.0%)",  ""),
             c("num",   "4.5 (2.4)", "2.5 (1.3)",  "6.5 (1.3)",  "0.021 *'"),
             c("cat",   "",          "",           "",           "0.80 \""),
             c("  a",   "3 (37.5%)", "2 (50.0%)",  "1 (25.0%)",  ""),
             c("  b",   "5 (62.5%)", "2 (50.0%)",  "3 (75.0%)",  ""))
  colnames(m) <- c("var", "total", "x", "y", "")
  if (!legend) m <- m[, -5]
  structure(m, legend = if (legend) "') Kruskal-Wallis test\nSignif. codes: 0 '***'",
            class = "TOne")
}

test_that("TOne: empty first header, indented levels, decimal p-values", {
  rec <- capture_df()
  toWrd(tone())

  expect_identical(names(rec$x), c("", "total", "x", "y", ""))
  expect_identical(rec$x[[1]][4], "\u{00A0}\u{00A0}\u{00A0}a")
  expect_identical(rec$x[[1]][2], "num")                 # not indented
  expect_identical(rec$args$align, c("l", "r", "r", "r", "d"))
})

test_that("TOne: legend below the table in a smaller font, optional", {
  rec <- capture_df()
  toWrd(tone(), font = list(name = "Arial Narrow", size = 10))
  expect_identical(rec$text,
                   c("') Kruskal-Wallis test", "Signif. codes: 0 '***'", ""))
  expect_identical(rec$targs$font, list(name = "Arial Narrow", size = 8))

  rec$text <- NULL
  toWrd(tone(), legend = FALSE)
  expect_null(rec$text)
})

test_that("TOne without tests: no decimal column, no legend", {
  rec <- capture_df()
  toWrd(tone(legend = FALSE))
  expect_identical(rec$args$align, c("l", "r", "r", "r"))
  expect_null(rec$text)
})

test_that("TOne: user indent and align win", {
  rec <- capture_df()
  toWrd(tone(), indent = "--", align = "c")
  expect_identical(rec$x[[1]][5], "--b")
  expect_identical(rec$args$align, "c")
})


# == TMod =====================================================================

# a stand-in for alloy's format.TMod(): the class FakeTMod only exists here
registerS3method("format", "FakeTMod", function(x, ...) {
  x$args <- list(...)
  assign("fmtArgs", list(...), envir = x$rec)
  list(coef  = data.frame(coef = c("(Intercept)", "age"),
                          m1 = c("-5.248 ***", "0.430 ***")),
       stats = if (x$stats)
                 data.frame(coef = c("AIC", "N"), m1 = c("4192.761", "10333"))
               else
                 data.frame(coef = character(0), m1 = character(0)))
}, envir = asNamespace("pons"))

tmod <- function(rec, stats = TRUE)
  structure(list(rec = rec, stats = stats), class = c("FakeTMod", "TMod"))

test_that("TMod: coefficients and statistics in one table, rule between", {
  rec <- capture_df()
  tab <- toWrd(tmod(rec))

  expect_identical(names(rec$x), c("", "m1"))
  expect_identical(rec$x[[1]], c("(Intercept)", "age", "AIC", "N"))
  # header + 2 coefficients -> the rule is the top border of row 4
  expect_named(tab$rows[[4]]$borders, "-1")
  expect_length(unlist(lapply(tab$rows[-4], `[[`, "borders")), 0L)
})

test_that("TMod: format arguments and rowtitle are passed on", {
  rec <- capture_df()
  toWrd(tmod(rec), digits = 2, naForm = "", verbose = TRUE,
        rowtitle = "Coefficients")
  expect_identical(rec$fmtArgs,
                   list(digits = 2, naForm = "", verbose = TRUE))
  expect_identical(names(rec$x)[1], "Coefficients")
})

test_that("TMod without statistics has no rule", {
  rec <- capture_df()
  tab <- toWrd(tmod(rec, stats = FALSE))
  expect_identical(nrow(rec$x), 2L)
  expect_length(unlist(lapply(tab$rows, `[[`, "borders")), 0L)
})


# == default ==================================================================

test_that("toWrd.default writes the printed output as text", {
  rec <- capture_df()
  toWrd(1:3)
  expect_match(paste(rec$text, collapse = "\n"), "[1] 1 2 3", fixed = TRUE)
})

sym <- function(x) pons:::.wrdSymbols(x, wrdSymbolMap())

test_that("arrows and relations are replaced, longest token first", {
  expect_identical(sym("a <=> b"), "a \u{21D4} b")
  expect_identical(sym("a => b"),  "a \u{21D2} b")
  expect_identical(sym("a <-> b"), "a \u{2194} b")
  expect_identical(sym("a -> b"),  "a \u{2192} b")
  expect_identical(sym("a <- b"),  "a \u{2190} b")
  expect_identical(sym("a != b"),  "a \u{2260} b")
  expect_identical(sym("x >= y"),  "x \u{2265} y")
  expect_identical(sym("x <= y"),  "x \u{2264} y")
})

test_that("plus-minus, ellipsis and powers", {
  expect_identical(sym("5 +/- 2"), "5 \u{00B1} 2")
  expect_identical(sym("5 +- 2"),  "5 \u{00B1} 2")
  expect_identical(sym("a..."),    "a\u{2026}")
  expect_identical(sym("m^2"),     "m\u{00B2}")
  expect_identical(sym("m^3"),     "m\u{00B3}")
})

test_that("ranges and multiplication only between digits", {
  expect_identical(sym("1--5"),  "1\u{2013}5")
  expect_identical(sym("a--b"),  "a--b")
  expect_identical(sym("2 x 3"), "2\u{00A0}\u{00D7}\u{00A0}3")
  expect_identical(sym("2x3"),   "2\u{00A0}\u{00D7}\u{00A0}3")
  expect_identical(sym("box 3"), "box 3")
})

test_that("minus sign before numbers, but not in words or ranges", {
  expect_identical(sym("-5.248 ***"), "\u{2212}5.248 ***")
  expect_identical(sym("-.5"),        "\u{2212}.5")
  expect_identical(sym("a -1"),       "a \u{2212}1")
  expect_identical(sym("(-1, -2)"),   "(\u{2212}1, \u{2212}2)")
  expect_identical(sym("[-1; 2]"),    "[\u{2212}1; 2]")
  expect_identical(sym("x=-1"),       "x=\u{2212}1")

  expect_identical(sym("L-dopa"),        "L-dopa")
  expect_identical(sym("DC-inhibitors"), "DC-inhibitors")
  expect_identical(sym("N04-1"),         "N04-1")     # hyphen after a digit
  expect_identical(sym("2.5-3.5"),       "2.5-3.5")
  expect_identical(sym("-"),             "-")         # naForm stays
  expect_identical(sym("a - b"),         "a - b")
})

test_that("p, n and N expressions get non-breaking spaces", {
  expect_identical(sym("p < 0.001"), "p\u{00A0}<\u{00A0}0.001")
  expect_identical(sym("p<0.05"),    "p\u{00A0}<\u{00A0}0.05")
  expect_identical(sym("n = 12"),    "n\u{00A0}=\u{00A0}12")
  expect_identical(sym("N=-3"),      "N\u{00A0}=\u{00A0}\u{2212}3")
  expect_identical(sym("p <= 0.05"), "p\u{00A0}\u{2264}\u{00A0}0.05")
})

test_that("vectors, NA and plain text pass through", {
  expect_identical(sym(c("a", NA, "-1")), c("a", NA, "\u{2212}1"))
  expect_identical(sym("Age (per 10 years)"), "Age (per 10 years)")
  expect_identical(sym(character(0)), character(0))
})

test_that("the map is a named character vector of valid perl regexes", {
  map <- wrdSymbolMap()
  expect_type(map, "character")
  expect_false(anyNA(names(map)) || any(names(map) == ""))
  for (p in names(map))
    expect_silent(grepl(p, "x", perl = TRUE))
})

test_that("a user map can extend or replace the default", {
  map <- c(wrdSymbolMap(), "chi2" = "\u{03C7}\u{00B2}")
  expect_identical(pons:::.wrdSymbols("chi2 = 3", map), "\u{03C7}\u{00B2} = 3")
  expect_identical(pons:::.wrdSymbols("a -> b", c("->" = "to")), "a to b")
})

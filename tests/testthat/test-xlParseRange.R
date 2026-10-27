# XLRange blocks as delivered by xlGetRange(): Value2() nests column-wise,
# values[[col]][[row]], empty cells are NULL
xlr <- function(..., address = "A1") {
  cols <- list(...)
  structure(list(values = cols, nrow = length(cols[[1]]), ncol = length(cols)),
            class = "XLRange", address = address, sheet = "S1", file = "f.xlsx")
}

r <- xlr(list("id", 1, 2, 3),
         list("name", "a", NULL, "c"),
         list("date", "2024-01-31", "2024-02-29", NULL))

test_that("data.frame with header converts the columns", {
  df <- xlParseRange(r, header = TRUE)
  expect_s3_class(df, "data.frame")
  expect_named(df, c("id", "name", "date"))
  expect_identical(df$id, c(1, 2, 3))
  expect_identical(df$name, c("a", NA, "c"))
  expect_s3_class(df$date, "Date")
  expect_identical(df$date[2], as.Date("2024-02-29"))
  expect_true(is.na(df$date[3]))
})

test_that("data.frame without header uses V1, V2, ...", {
  df <- xlParseRange(r)
  expect_named(df, c("V1", "V2", "V3"))
  expect_identical(nrow(df), 4L)
  expect_type(df$V1, "character")                       # "id" is not numeric
})

test_that("convert = FALSE keeps the raw values", {
  df <- xlParseRange(r, header = TRUE, convert = FALSE)
  expect_type(df$date, "character")
})

test_that("matrix: numeric only if every column is numeric", {
  num <- xlr(list(1, 2), list(3, 4))
  m <- xlParseRange(num, output = "matrix")
  expect_identical(m, matrix(c(1, 2, 3, 4), 2))

  m <- xlParseRange(r, output = "matrix", header = TRUE)
  expect_type(m, "character")
  expect_identical(colnames(m), c("id", "name", "date"))
  expect_identical(m[[2, "date"]], "2024-02-29")
})

test_that("list: one component per column, named by the header", {
  l <- xlParseRange(r, output = "list", header = TRUE)
  expect_named(l, c("id", "name", "date"))
  expect_identical(l$id, c(1, 2, 3))
})

test_that("table: first row and column become dimnames", {
  t <- xlr(list(NULL, "r1", "r2"), list("c1", 1, 2), list("c2", 3, 4))
  m <- xlParseRange(t, output = "table")
  expect_identical(dimnames(m), list(c("r1", "r2"), c("c1", "c2")))
  expect_identical(unname(m), matrix(c(1, 2, 3, 4), 2))

  expect_error(xlParseRange(xlr(list(1, 2)), output = "table"), "at least 2")
})

test_that("single cells and string numbers", {
  one <- xlr(list(5))
  expect_identical(xlParseRange(one, output = "matrix"), matrix(5))
  s <- xlr(list("1.5", "2", ""))
  expect_identical(xlParseRange(s)$V1, c(1.5, 2, NA))
})

test_that("multi-area selections: list of matrices or bound data.frame", {
  a1 <- xlr(list("x", 1, 2), address = "A1:A3")
  a2 <- xlr(list("y", 3, 4, 5), list("x", "u", "v", "w"), address = "C1:D4")
  areas <- structure(list(a1, a2), address = "A1:A3,C1:D4")

  l <- xlParseRange(areas, output = "list", header = TRUE)
  expect_length(l, 2L)
  expect_identical(attr(l, "address"), "A1:A3,C1:D4")
  expect_identical(l[[1]], matrix(c(1, 2), 2, dimnames = list(NULL, "x")))

  df <- xlParseRange(areas, output = "data.frame", header = TRUE)
  expect_named(df, c("x", "y", "x.1"))                  # made unique
  expect_identical(df$x, c(1, 2, NA))                   # padded
  expect_identical(df$y, c(3, 4, 5))

  expect_error(xlParseRange(areas, output = "matrix"), "Multiple ranges")
})


# == .xlConvert ===============================================================

test_that(".xlConvert detects numbers and dates, else keeps text", {
  cv <- pons:::.xlConvert
  expect_identical(cv(c(1, 2)), c(1, 2))
  expect_identical(cv(c(TRUE, NA)), c(TRUE, NA))
  expect_identical(cv(c("1", "2.5", NA, "")), c(1, 2.5, NA, NA))
  expect_identical(cv(c("1e3", "-2")), c(1000, -2))
  expect_identical(cv(c("2024-01-31", NA)), as.Date(c("2024-01-31", NA)))
  expect_identical(cv("31.01.2024"), as.Date("2024-01-31"))
  expect_identical(cv(c("a", "1")), c("a", "1"))
  expect_identical(cv(c("2024-01-31", "x")), c("2024-01-31", "x"))
  expect_identical(cv(c(NA_character_, "")), c(NA, ""))
})


# == .xlDeparse ===============================================================

test_that(".xlDeparse produces code that rebuilds the object", {
  rt <- function(x) eval(parse(text = pons:::.xlDeparse(x)))

  df <- data.frame(a = c(1, NA), b = c("u", "v"), stringsAsFactors = FALSE)
  expect_identical(rt(df), df)
  expect_match(pons:::.xlDeparse(df), "^data\\.frame\\(a = ")

  m <- matrix(1:4, 2, dimnames = list(NULL, c("x", "y")))
  expect_identical(rt(m), m)
  m0 <- matrix(c(1.5, 2), 1)
  expect_identical(rt(m0), m0)
  expect_false(grepl("dimnames", pons:::.xlDeparse(m0)))

  l <- list(a = 1:2, 3, b = list(c = "x"))
  expect_identical(rt(l), l)

  expect_identical(rt(c(a = 1, b = 2)), c(a = 1, b = 2))
  d <- as.Date("2024-01-31")
  expect_identical(rt(d), d)
})

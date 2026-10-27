# Fake COM objects for the COM-free tests: environments accept the
# obj[["Prop"]] <- value assignments RDCOMClient objects use, and methods
# are plain functions stored in them.

fakeCOM <- function(...) list2env(list(...))

# a fake table recording the borders set per row
fakeTable <- function(nrow) {
  rows <- lapply(seq_len(nrow), function(i) {
    r <- fakeCOM(borders = list())
    r$Borders <- function(w) {
      b <- fakeCOM(id = w)
      r$borders[[as.character(w)]] <- b
      b
    }
    r
  })
  fakeCOM(Rows = function(i) rows[[i]], rows = rows)
}

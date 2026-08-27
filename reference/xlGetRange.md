# Read the Raw Values of the Selected Excel Range(s)

Reads the values of an Excel range via RDCOMClient and returns them in a
lightweight container for further processing by
[`xlParseRange`](https://andrisignorell.github.io/pons/reference/xlParseRange.md).
No type conversion or reshaping happens here. The raw `Value2()` data is
kept as-is together with the range geometry and metadata.

## Usage

``` r
xlGetRange(xl = NULL, range = NULL)
```

## Arguments

- xl:

  optional Excel application handle. If `NULL`, the running Excel
  instance is attached via
  `RDCOMClient::COMCreate(..., existing = TRUE)`.

- range:

  optional A1-style address (e.g. `"A1:C10"` or `"Sheet1!A1:C10"`). If
  `NULL`, the current selection is used.

## Value

For a single area, an object of class `"XLRange"`: a list with
components `values` (the raw column-wise nested list from `Value2()`),
`nrow` and `ncol`, plus attributes `address`, `sheet` and `file`. For
multiple areas, a list of such `"XLRange"` objects with `address`,
`sheet` and `file` attributes on the list itself.

## Details

A selection may consist of several disjoint *areas* (e.g. `A1:A4`
together with `C3:D5`). Each area is returned as its own `"XLRange"`
block. With a single area a single block is returned; with multiple
areas an (unclassed) list of blocks is returned, carrying the overall
metadata as attributes.

## Note

`Value2()` returns dates as numeric serial days (base 1899-12-30), not
as text, and yields a column-wise nested list indexed as
`values[[column]][[row]]`.

## See also

[`xlParseRange`](https://andrisignorell.github.io/pons/reference/xlParseRange.md),
[`xlImport`](https://andrisignorell.github.io/pons/reference/xlImport.md)

## Examples

``` r
if (FALSE) { # \dontrun{
xl <- getXl()
r  <- xlGetRange(xl)          # current selection
attr(r, "address")           # e.g. "A1:B34"
attr(r, "sheet")             # worksheet name
attr(r, "file")              # workbook (file) name
} # }
```

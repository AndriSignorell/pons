# Organize a Raw Excel Range into a data.frame, matrix, list or table

Turns the raw output of
[`xlGetRange`](https://andrisignorell.github.io/pons/reference/xlGetRange.md)
into a proper R object. Handles a single range as well as a multi-area
selection, with optional header handling and automatic per-column type
conversion.

## Usage

``` r
xlParseRange(
  x,
  as = c("data.frame", "matrix", "list", "table"),
  header = FALSE,
  convert = TRUE,
  stringsAsFactors = FALSE
)
```

## Arguments

- x:

  an `"XLRange"` object, or a list of them (multi-area), as returned by
  [`xlGetRange`](https://andrisignorell.github.io/pons/reference/xlGetRange.md).

- as:

  target structure. One of `"data.frame"`, `"matrix"`, `"list"`,
  `"table"`.

- header:

  logical; if `TRUE`, the first row is treated as a header (column
  names). Ignored for `"table"`, which always uses the first row /
  column as names.

- convert:

  logical; if `TRUE` (default), each column is run through
  `.xlConvert()` for automatic numeric / Date detection.

- stringsAsFactors:

  logical; passed to
  [`data.frame`](https://rdrr.io/r/base/data.frame.html) for the
  `"data.frame"` target. Defaults to `FALSE`.

## Value

A `data.frame`, `matrix`, `list`, or a matrix with `dimnames` (for
`"table"`). For a multi-area `"list"`, the returned list carries an
`address` attribute.

## Details

**Single range.** The requested structure determines the result:

- `"data.frame"`:

  with `header = TRUE` the first row supplies the column names;
  otherwise names are `V1, V2, ...`.

- `"matrix"`:

  the whole range as a matrix. When `convert` is `TRUE` and every column
  is numeric, a numeric matrix results; otherwise a character matrix.

- `"list"`:

  one component per column (named by the header when `header = TRUE`).

- `"table"`:

  first column becomes row names, first row becomes column names, and
  the top-left corner cell is discarded. The result is a matrix with
  `dimnames` (not a `table` object). Requires at least 2 rows and 2
  columns.

**Multiple areas.** When `x` is a list of `"XLRange"` blocks (disjoint
selection), only two targets are supported:

- `"list"`:

  each area is parsed as its own matrix; the result is a list of
  matrices.

- `"data.frame"`:

  each area is parsed as a data.frame and the areas are bound
  column-wise into a single data.frame. Columns of unequal length are
  padded with `NA` up to the longest column, and duplicate column names
  are disambiguated with
  [`make.unique`](https://rdrr.io/r/base/make.unique.html).

Any other target raises an error for multi-area input.

## See also

[`xlGetRange`](https://andrisignorell.github.io/pons/reference/xlGetRange.md),
[`xlImport`](https://andrisignorell.github.io/pons/reference/xlImport.md)

## Examples

``` r
if (FALSE) { # \dontrun{
r <- xlGetRange(xl)
xlParseRange(r, as = "data.frame", header = TRUE)
xlParseRange(r, as = "matrix")
xlParseRange(r, as = "table")     # first col = rownames, first row = colnames
} # }
```

# Excel Data Transfer Dialog

Modal Tcl/Tk dialog that asks the user how to organize and deliver an
Excel range that is being transferred to R. It is the interactive
front-end used by
[`xlImport`](https://andrisignorell.github.io/pons/reference/xlImport.md)
and returns the user's choices as a plain list.

## Usage

``` r
xlDataTransferDialog(range = NULL, multi = FALSE)
```

## Arguments

- range:

  character; the range address to display in the header label, e.g.
  `"A1:B34; C23:E55"`. `NULL` or empty shows `"(no selection)"`.

- multi:

  logical; `TRUE` if several disjoint areas are selected. Restricts the
  structure choices and preselects `"list"`.

## Value

A list with components

- structure:

  internal structure code: one of `"data.frame"`, `"data.frame.nocol"`,
  `"matrix"`, `"table"`, `"list"`.

- variable:

  the variable name typed by the user (possibly `""`).

- insert:

  logical; whether "insert at cursor position" was checked.

Returns `NULL` if the dialog is cancelled (Cancel button or Escape).

## Details

The dialog shows the selected range address, a structure chooser, a
variable name entry, and an "insert data at cursor position" checkbox.

The offered structures are:

- data.frame (colnames):

  first row becomes the column names.

- data.frame (no colnames):

  base-R default names `V1, V2, ...`.

- matrix:

  whole range as a matrix.

- table (dimnames):

  first column / first row as dim names.

- list:

  one component per column.

When `multi = TRUE` (a disjoint multi-area selection), only the
column-combinable structures are offered - the two `data.frame` variants
and `list` - and `list` is preselected, because `matrix` and `table` are
not defined across several areas (see
[`xlParseRange`](https://andrisignorell.github.io/pons/reference/xlParseRange.md)).

## See also

[`xlImport`](https://andrisignorell.github.io/pons/reference/xlImport.md)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- xlDataTransferDialog(range = "A1:B34")
str(res)
} # }
```

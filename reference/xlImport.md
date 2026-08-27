# Interactively Import the Selected Excel Range into R

End-to-end, dialog-driven transfer of the currently selected Excel
range(s) into R. The function reads the selection via
[`xlGetRange`](https://andrisignorell.github.io/pons/reference/xlGetRange.md),
asks the user how to organize and deliver the data via
[`xlDataTransferDialog`](https://andrisignorell.github.io/pons/reference/xlDataTransferDialog.md),
and then either returns / assigns the resulting object or inserts
constructive R code at the editor cursor.

## Usage

``` r
xlImport(xl = NULL)
```

## Arguments

- xl:

  optional Excel application handle (as returned by
  [`getXl()`](https://andrisignorell.github.io/pons/reference/getXl.md)).
  If `NULL`, the running instance is used.

## Value

Invisibly (or visibly, when no variable is given and nothing is
inserted) the organized object: a `data.frame`, `matrix`, `list` or
`table`-like matrix. Returns `invisible(NULL)` if the dialog is
cancelled.

## Details

The dialog offers the following target structures (single range):

- data.frame (colnames):

  first row becomes the column names.

- data.frame (no colnames):

  base-R default names `V1, V2, ...`.

- matrix:

  whole range as a matrix, no dim names, default type choice.

- table (dimnames):

  first column becomes row names, first row becomes column names, the
  top-left corner cell is discarded.

- list:

  one component per column.

When several disjoint areas are selected, only `data.frame` variants and
`list` are offered (see
[`xlParseRange`](https://andrisignorell.github.io/pons/reference/xlParseRange.md)
for how areas are combined), and `list` is preselected.

Delivery is controlled by two dialog inputs, giving four combinations:

|            |              |                                            |
|------------|--------------|--------------------------------------------|
| **insert** | **variable** | **action**                                 |
| FALSE      | set          | `assign(variable, out, parent.frame())`    |
| FALSE      | empty        | return the object (printed at the console) |
| TRUE       | set          | insert `variable <- <code>` at the cursor  |
| TRUE       | empty        | insert `<code>` at the cursor              |

## See also

[`xlGetRange`](https://andrisignorell.github.io/pons/reference/xlGetRange.md),
[`xlParseRange`](https://andrisignorell.github.io/pons/reference/xlParseRange.md),
[`xlDataTransferDialog`](https://andrisignorell.github.io/pons/reference/xlDataTransferDialog.md)

## Examples

``` r
if (FALSE) { # \dontrun{
xl <- getXl()
# select a range in Excel, then:
xlImport(xl)
} # }
```

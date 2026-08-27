# View Objects in Excel

Opens a data frame, a matrix, an atomic vector or a list of such objects
in Microsoft Excel for interactive inspection.

## Usage

``` r
# S3 method for class 'glm'
xlView(
  x,
  sheet = NULL,
  conf.level = NA,
  method = c("profile", "wald"),
  exponentiate = FALSE,
  anova = FALSE,
  fitted = FALSE,
  autofit = TRUE,
  gap = 2L,
  xl = NULL,
  ...
)

# S3 method for class 'lm'
xlView(
  x,
  sheet = NULL,
  conf.level = NA,
  anova = FALSE,
  fitted = FALSE,
  autofit = TRUE,
  gap = 2L,
  xl = NULL,
  ...
)

xlView(x, sheet = NULL, ...)

# S3 method for class 'data.frame'
xlView(
  x,
  sheet = NULL,
  rowNames = FALSE,
  table = TRUE,
  autofit = TRUE,
  freeze = TRUE,
  xl = NULL,
  ...
)

# S3 method for class 'matrix'
xlView(
  x,
  sheet = NULL,
  rowNames = NA,
  table = TRUE,
  autofit = TRUE,
  freeze = TRUE,
  xl = NULL,
  ...
)

# S3 method for class 'table'
xlView(
  x,
  sheet = NULL,
  rowNames = NA,
  table = TRUE,
  autofit = TRUE,
  freeze = TRUE,
  xl = NULL,
  ...
)

# S3 method for class 'array'
xlView(
  x,
  sheet = NULL,
  rowNames = NA,
  table = TRUE,
  autofit = TRUE,
  freeze = TRUE,
  xl = NULL,
  ...
)

# Default S3 method
xlView(
  x,
  sheet = NULL,
  rowNames = NA,
  table = TRUE,
  autofit = TRUE,
  freeze = TRUE,
  xl = NULL,
  ...
)

# S3 method for class 'list'
xlView(
  x,
  sheet = NULL,
  rowNames = NA,
  autofit = TRUE,
  gap = 2L,
  titles = TRUE,
  xl = NULL,
  ...
)
```

## Arguments

- x:

  an object to be displayed: a data frame, a matrix or two-dimensional
  table, an atomic vector (with or without names) or a possibly nested
  list of these

- sheet:

  optional worksheet name; defaults to the deparsed name of `x`

- conf.level:

  confidence level for the coefficient intervals, or `NA` (default) to
  omit them

- method:

  the procedure for the coefficient intervals, either `"profile"`
  (profile likelihood, the default of `confint.glm`) or `"wald"`

- exponentiate:

  logical; if `TRUE`, the estimates and their interval bounds are
  additionally reported on the exponentiated scale (odds ratios for a
  logit link, rate ratios for a log link)

- anova:

  logical; if `TRUE`, the sequential analysis of variance table is
  appended

- fitted:

  logical; if `TRUE`, the model frame together with fitted values and
  residuals is appended

- autofit:

  logical; if `TRUE`, column widths are adjusted automatically

- gap:

  integer, list method only; number of empty rows between two
  consecutive blocks

- xl:

  optional Excel COM object

- ...:

  further arguments, currently ignored

- rowNames:

  logical or `NA`; if `TRUE`, row names (resp. the names of a vector)
  are written as a leading column. `NA` means automatic: names are
  written whenever the object carries them.

- table:

  logical; if `TRUE`, Excel filters are enabled. Ignored when the object
  has no header row and for lists.

- freeze:

  logical; if `TRUE`, the first row is frozen. Ignored when there is no
  header row and for lists.

- titles:

  logical, list method only; if `TRUE`, the element names are written as
  a bold label above each block

## Value

Invisibly returns the worksheet COM object.

## Details

A new workbook and worksheet are created automatically.

Data are transferred column-wise to preserve numeric types. Factors and
date-time objects are converted to character vectors.

Matrices are written with those dimnames they actually have: a matrix
without column names gets no header row, a matrix without row names gets
no leading name column. Atomic vectors are written as a single column
headed by the deparsed expression.

Lists are stacked vertically on one sheet, each element separated by
`gap` empty rows. Nested lists are indented by one column. Since Excel
allows only one autofilter per sheet, `table` and `freeze` are not
available for lists.

The workbook is not saved automatically.

## Examples

``` r
if (FALSE) { # \dontrun{
xlView(iris)
xlView(as.matrix(mtcars))
xlView(table(d.pizza$driver, d.pizza$area))
xlView(rnorm(10))
xlView(list(summary = summary(iris$Sepal.Length),
            counts  = table(iris$Species),
            data    = head(iris)))
} # }
```

# Capture Output from Evaluated Expressions

Evaluates one or more expressions and captures their printed output,
closely mimicking the behavior of the R console. Only visibly returned
results are printed.

## Usage

``` r
.captOut(..., file = NULL, append = FALSE, width = 150)
```

## Arguments

- ...:

  Expressions to be evaluated. Each expression is evaluated in the
  calling environment, and its visible result is printed.

- file:

  Optional destination for the output. If `NULL` (default), output is
  captured and returned as a character vector. If a character string,
  output is written to the specified file. If a connection, output is
  written to the connection.

- append:

  Logical; if `TRUE`, output is appended to `file` when a file path or
  connection is provided.

- width:

  Integer; line width used during evaluation (temporarily sets
  `options(width)`).

## Value

If `file = NULL`, a character vector containing the captured output.
Otherwise, the output is written to `file` and the function returns
`invisible(NULL)`.

## Details

This function evaluates each expression in `...` using
[`withVisible`](https://rdrr.io/r/base/withVisible.html), ensuring that
only visible results are printed, similar to interactive R sessions.
Output is captured via [`sink`](https://rdrr.io/r/base/sink.html).

Unlike [`capture.output`](https://rdrr.io/r/utils/capture.output.html),
this function supports multiple expressions and reproduces console-like
evaluation semantics.

## See also

[`capture.output`](https://rdrr.io/r/utils/capture.output.html),
[`sink`](https://rdrr.io/r/base/sink.html),
[`withVisible`](https://rdrr.io/r/base/withVisible.html)

## Examples

``` r
# Capture output as character vector
if (FALSE) { # \dontrun{
.captOut(1 + 1, sqrt(4))

# Write output to file
.captOut(1:5, summary(1:5), file = "output.txt")

# Use with expressions
.captOut({ x <- 1:3; x * 2 })
} # }
```

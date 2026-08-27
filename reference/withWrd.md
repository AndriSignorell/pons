# Temporarily Use a Word Session

Evaluates an expression using a specified Word session as the default.

## Usage

``` r
withWrd(wrd, expr)
```

## Arguments

- wrd:

  A Word COM object.

- expr:

  An expression to evaluate.

## Value

The result of the evaluated expression.

## Examples

``` r
if (FALSE) { # \dontrun{
withWrd(newWrd(), {
  toWrd("Hello")
})
} # }
```

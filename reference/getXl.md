# Get Current Excel Session

Retrieves the current Excel COM object. If no valid session exists, a
new one can optionally be created.

## Usage

``` r
getXl(create = TRUE)
```

## Arguments

- create:

  Logical; if `TRUE`, a new Excel instance is created when none is
  available.

## Value

An Excel COM object or `NULL`.

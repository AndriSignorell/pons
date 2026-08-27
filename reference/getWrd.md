# Get Current Word Session

Retrieves the current Word COM object. If no valid session exists, a new
one can be created.

## Usage

``` r
getWrd(create = TRUE)
```

## Arguments

- create:

  Logical; if `TRUE`, a new Word instance is created when none is
  available.

## Value

A Word COM object or `NULL`.

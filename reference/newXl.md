# Create a New Excel Session

Starts a new Microsoft Excel instance via RDCOMClient. The created
instance is registered as the current default Excel session.

## Usage

``` r
newXl(visible = TRUE)
```

## Arguments

- visible:

  Logical; whether the Excel application should be visible.

## Value

An Excel COM object of class `"COMIDispatch"`.

## Examples

``` r
if (FALSE) { # \dontrun{
xl <- newXl()
} # }
```

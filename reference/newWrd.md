# Create a New Word Session

Starts a new Microsoft Word instance via RDCOMClient and creates an
empty document. The created instance is registered as the current
default Word session.

## Usage

``` r
newWrd(visible = TRUE)
```

## Arguments

- visible:

  Logical; whether the Word application should be visible.

## Value

A Word COM object of class `"COMIDispatch"`.

## Details

The function initializes a Word application and ensures that at least
one document is open. The instance is stored internally and can be
accessed by other helper functions.

## Examples

``` r
if (FALSE) { # \dontrun{
wrd <- newWrd()
} # }
```

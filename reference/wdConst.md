# Word Constants for RDCOMClient

A list of Microsoft Word constants used for automation via
`RDCOMClient`. These constants correspond to enumerations defined in the
Word object model and are used when calling methods on Word COM objects.

## Usage

``` r
wdConst
```

## Format

An object of class `"list"` containing named integer constants (e.g.,
`wdCollapseEnd`, `wdAlignParagraphLeft`, etc.).

## Details

The constants are intended for use with Word COM interfaces, for
example:


    wrd[["Selection"]]$Collapse(Direction = wdConst$wdCollapseEnd)

This avoids the need to manually define or remember numeric values for
Word enumerations.

## See also

[`toWrd`](https://andrisignorell.github.io/pons/reference/toWrd.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Collapse selection to end of document
wrd[["Selection"]]$Collapse(Direction = wdConst$wdCollapseEnd)

# Apply paragraph alignment
wrd[["Selection"]]$ParagraphFormat()$Alignment <- wdConst$wdAlignParagraphLeft
} # }
```

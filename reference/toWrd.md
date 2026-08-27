# Insert Content into Microsoft Word

Inserts content into an active Microsoft Word document via RDCOMClient.
The function supports different input types and dispatches methods based
on the class of `x`.

## Usage

``` r
toWrd(x, font = NULL, ..., wrd = NULL)

# Default S3 method
toWrd(x, font = NULL, ..., wrd = NULL)

# S3 method for class 'character'
toWrd(
  x,
  font = NULL,
  para = NULL,
  style = NULL,
  bullet = FALSE,
  ...,
  wrd = NULL
)
```

## Arguments

- x:

  Object to be written to Word. Supported types include character
  vectors and arbitrary objects (converted via `capture`-like behavior).

- font:

  Optional font specification (list or object of class `"font"`). If
  `"fix"`, a fixed-width font is used.

- ...:

  Additional arguments passed to methods.

- wrd:

  A Word COM object. Defaults to the last active Word instance.

- para:

  paragraph format

- style:

  style template name

- bullet:

  for bullet style

## Value

Invisibly returns `NULL`.

## Details

The function inserts text into the current selection of a Word document.
Character input is inserted directly, while other objects are first
converted to text using an internal capture mechanism.

UTF-8 strings may be converted to Latin-1 depending on system locale to
avoid encoding issues in Word.

Formatting options such as paragraph style, font, and bullet lists can
be applied via method-specific arguments.

## Examples

``` r
if (FALSE) { # \dontrun{
toWrd("Hello World")
toWrd(1:10)
toWrd(c("Line 1", "Line 2"), bullet = TRUE)
} # }
```

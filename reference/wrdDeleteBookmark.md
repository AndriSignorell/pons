# Delete a Word Bookmark

Deletes a bookmark from the active Word document.

## Usage

``` r
wrdDeleteBookmark(name, wrd = NULL)
```

## Arguments

- name:

  Bookmark name.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

Logical. Returns `TRUE` if the bookmark was deleted, otherwise `FALSE`.

## Examples

``` r
if (FALSE) { # \dontrun{
wrdDeleteBookmark("intro")
} # }
```

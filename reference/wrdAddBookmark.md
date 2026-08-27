# Add a Word Bookmark

Adds a new bookmark at the current cursor position in the active Word
document.

## Usage

``` r
wrdAddBookmark(name, wrd = NULL)
```

## Arguments

- name:

  Bookmark name.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

Invisibly returns the created bookmark COM object.

## Examples

``` r
if (FALSE) { # \dontrun{
wrdAddBookmark("results")
} # }
```

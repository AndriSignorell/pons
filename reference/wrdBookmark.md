# Get a Word Bookmark

Retrieves a bookmark object from the active Word document.

## Usage

``` r
wrdBookmark(name, wrd = NULL)
```

## Arguments

- name:

  Bookmark name.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

A Word bookmark COM object of class `"COMIDispatch"`, or `NULL` if the
bookmark does not exist.

## Examples

``` r
if (FALSE) { # \dontrun{
bm <- wrdBookmark("intro")
} # }
```

# List Word Bookmarks

Returns a data frame containing all bookmarks in the active Word
document.

## Usage

``` r
bookmarkList(wrd = NULL)
```

## Arguments

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

A data frame with the following columns:

- id:

  Internal Word bookmark ID.

- name:

  Bookmark name.

- pagenr:

  Page number of the bookmark.

- type:

  Bookmark type inferred from the bookmark name.

## Details

Bookmarks are returned in the order in which they appear in the
document.

## Examples

``` r
if (FALSE) { # \dontrun{
bookmarkList()
} # }
```

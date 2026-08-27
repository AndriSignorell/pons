# Replace Bookmark Text

Replaces the text content of a bookmark while preserving the bookmark
itself.

## Usage

``` r
replaceBookmarkText(name, text, wrd = NULL)
```

## Arguments

- name:

  Bookmark name.

- text:

  Replacement text.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

Invisibly returns `TRUE`.

## Details

Word removes bookmarks automatically when their text content is
replaced. This function restores the bookmark after updating the
associated text range.

## Examples

``` r
if (FALSE) { # \dontrun{
replaceBookmarkText("title", "New title")
} # }
```

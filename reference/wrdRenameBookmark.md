# Rename a Word Bookmark

Renames a bookmark in the active Word document while preserving its
associated text range.

## Usage

``` r
wrdRenameBookmark(name, newName, wrd = NULL)
```

## Arguments

- name:

  Existing bookmark name.

- newName:

  New bookmark name.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

Invisibly returns `TRUE` on success and `FALSE` otherwise.

## Details

Word bookmarks cannot always be renamed reliably by directly modifying
their `Name` property. Therefore, this function preserves the bookmark
range, deletes the existing bookmark, and recreates it with the new
name.

If a bookmark with `newName` already exists, the function returns
`FALSE` and leaves the document unchanged.

## Examples

``` r
if (FALSE) { # \dontrun{
wrdRenameBookmark("old_name", "new_name")
} # }
```

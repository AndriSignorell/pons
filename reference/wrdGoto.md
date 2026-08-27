# Go to a Word Object

Moves the current Word selection to a specified object, such as a
bookmark.

## Usage

``` r
wrdGoto(name, what = NULL, wrd = NULL)
```

## Arguments

- name:

  Name of the target object.

- what:

  Word GoTo constant defining the target type. Defaults to
  `wdConst$wdGoToBookmark`.

- wrd:

  A Word COM object. If `NULL`, the current active Word session is used.

## Value

Invisibly returns `TRUE` on success and `FALSE` if the target bookmark
does not exist.

## Details

The function moves the current Word selection to the specified target
object using Word's `GoTo()` method.

When navigating to bookmarks, existence of the bookmark is checked
before attempting the navigation.

## Examples

``` r
if (FALSE) { # \dontrun{
wrdGoto("intro")
} # }
```

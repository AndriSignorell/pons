# Changelog

## pons (development version)

### New features

- Interface between R and Microsoft Word and Excel via the Component
  Object Model, supplying the Office layer of the DescToolsX package
  suite. Windows only; requires a local Office installation and
  `RDCOMClient`.
- [`toWrd()`](https://andrisignorell.github.io/pons/reference/toWrd.md)
  writes content of the common R classes into a running Word document,
  with control over font, paragraph format, style template and bullet
  lists.
- Bookmark handling makes reports updatable in place:
  [`wrdAddBookmark()`](https://andrisignorell.github.io/pons/reference/wrdAddBookmark.md),
  [`wrdBookmark()`](https://andrisignorell.github.io/pons/reference/wrdBookmark.md),
  [`renameBookmark()`](https://andrisignorell.github.io/pons/reference/renameBookmark.md),
  [`wrdDeleteBookmark()`](https://andrisignorell.github.io/pons/reference/wrdDeleteBookmark.md),
  [`bookmarkList()`](https://andrisignorell.github.io/pons/reference/bookmarkList.md)
  and
  [`wrdGoto()`](https://andrisignorell.github.io/pons/reference/wrdGoto.md).
  [`replaceBookmarkText()`](https://andrisignorell.github.io/pons/reference/replaceBookmarkText.md)
  restores the bookmark that Word discards when the underlying text is
  replaced.
- [`xlGetRange()`](https://andrisignorell.github.io/pons/reference/xlGetRange.md)
  and
  [`xlParseRange()`](https://andrisignorell.github.io/pons/reference/xlParseRange.md)
  read an Excel selection - including disjoint multi-area selections -
  into a data frame, matrix, list or table, with header handling and
  per-column type detection.
- [`xlImport()`](https://andrisignorell.github.io/pons/reference/xlImport.md)
  wraps the above in a Tcl/Tk dialog and either assigns the result or
  inserts constructive R code at the editor cursor.
- [`xlView()`](https://andrisignorell.github.io/pons/reference/xlView.md)
  opens data frames, matrices, tables, vectors and nested lists in
  Excel, with methods for `lm` and `glm` that write the coefficient
  table with optional confidence intervals, ANOVA and fitted values.

### Acknowledgements

Parts of the code and documentation were reviewed with the help of large
language models (OpenAI Codex, Anthropic Claude). Every suggestion was
assessed, edited and verified by the maintainer, who remains solely
responsible for the content of this package.

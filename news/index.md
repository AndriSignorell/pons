# Changelog

## pons (development version)

### New features

- Interface between R and Microsoft Word and Excel via the Component
  Object Model, supplying the Office layer of the DescToolsX package
  suite. Windows only; requires a local Office installation and
  `RDCOMClient`.
- [`toWrd()`](../reference/toWrd.md) writes content of the common R
  classes into a running Word document, with control over font,
  paragraph format, style template and bullet lists.
- Bookmark handling makes reports updatable in place:
  [`wrdAddBookmark()`](../reference/wrdAddBookmark.md),
  [`wrdBookmark()`](../reference/wrdBookmark.md), `renameBookmark()`,
  [`wrdDeleteBookmark()`](../reference/wrdDeleteBookmark.md),
  `bookmarkList()` and [`wrdGoto()`](../reference/wrdGoto.md).
  `replaceBookmarkText()` restores the bookmark that Word discards when
  the underlying text is replaced.
- [`xlGetRange()`](../reference/xlGetRange.md) and
  [`xlParseRange()`](../reference/xlParseRange.md) read an Excel
  selection - including disjoint multi-area selections - into a data
  frame, matrix, list or table, with header handling and per-column type
  detection.
- [`xlImport()`](../reference/xlImport.md) wraps the above in a Tcl/Tk
  dialog and either assigns the result or inserts constructive R code at
  the editor cursor.
- [`xlView()`](../reference/xlView.md) opens data frames, matrices,
  tables, vectors and nested lists in Excel, with methods for `lm` and
  `glm` that write the coefficient table with optional confidence
  intervals, ANOVA and fitted values.

### Acknowledgements

Parts of the code and documentation were reviewed with the help of large
language models (OpenAI Codex, Anthropic Claude). Every suggestion was
assessed, edited and verified by the maintainer, who remains solely
responsible for the content of this package.

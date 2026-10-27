# pons 0.0.0.921

## New features

- Interface between R and Microsoft Word and Excel via the Component
  Object Model, supplying the Office layer of the DescToolsX package
  suite. Windows only; requires a local Office installation and
  `RDCOMClient`.
- `toWrd()` writes content of the common R classes into a running Word
  document, with control over font, paragraph format, style template and
  bullet lists.
- `toWrd()` methods for `data.frame`, `matrix`, `table`, `TOne` and `TMod`
  write formatted tables (header rules, decimal-tab alignment, paragraph
  spacing); `wrdSymbolMap()` replaces `-`, `=>`, `<=` etc. by their
  typographic characters.
- Bookmark handling makes reports updatable in place: `wrdAddBookmark()`,
  `wrdBookmark()`, `renameBookmark()`, `wrdDeleteBookmark()`,
  `bookmarkList()` and `wrdGoto()`. `replaceBookmarkText()` restores the
  bookmark that Word discards when the underlying text is replaced.
- `xlGetRange()` and `xlParseRange()` read an Excel selection - including
  disjoint multi-area selections - into a data frame, matrix, list or
  table, with header handling and per-column type detection.
- `xlImport()` wraps the above in a Tcl/Tk dialog and either assigns the
  result or inserts constructive R code at the editor cursor.
- `xlView()` opens data frames, matrices, tables, vectors and nested
  lists in Excel, with methods for `lm` and `glm` that write the
  coefficient table with optional confidence intervals, ANOVA and fitted
  values.

## Bug fixes

- `xlParseRange()` failed on multi-area selections (internal calls used the
  non-existent argument `as =` instead of `output =`).
- `wrdSymbolMap()` was broken in non-UTF-8 locales: non-ASCII regex
  patterns given as argument tags were translated to `<U+2264>` text.
  The minus rule now also applies after a non-breaking space (`N = -3`).
- The internal output capture failed on literal constants
  ("bad argument").

## Internal

- Test suite for all COM-free parts (symbol map, table preparation, the
  `toWrd()` table methods with a mocked Word layer, `xlParseRange()`, type
  conversion, deparser, output capture).

## Acknowledgements

Parts of the code and documentation were reviewed with the help of large
language models (OpenAI Codex, Anthropic Claude). Every suggestion was
assessed, edited and verified by the maintainer, who remains solely
responsible for the content of this package.

# Package index

## Word Sessions

Creating, retrieving, registering and closing a Word instance.

- [`newWrd()`](newWrd.md) : Create a New Word Session
- [`getWrd()`](getWrd.md) : Get Current Word Session
- [`setWrd()`](setWrd.md) : Set Current Word Session
- [`closeWrd()`](closeWrd.md) : Close Word Session
- [`withWrd()`](withWrd.md) : Temporarily Use a Word Session

## Writing to Word

Inserting R content into a document and the constants needed to address
the Word object model.

- [`toWrd()`](toWrd.md) : Insert Content into Microsoft Word
- [`wdConst`](wdConst.md) : Word Constants for RDCOMClient

## Word Bookmarks

Creating, listing, renaming and refilling bookmarks - the mechanism that
makes a report updatable in place.

- [`wrdAddBookmark()`](wrdAddBookmark.md) : Add a Word Bookmark
- [`wrdBookmark()`](wrdBookmark.md) : Get a Word Bookmark
- [`wrdDeleteBookmark()`](wrdDeleteBookmark.md) : Delete a Word Bookmark
- [`wrdRenameBookmark()`](wrdRenameBookmark.md) : Rename a Word Bookmark
- [`wrdBookmarks()`](wrdBookmarks.md) : List Word Bookmarks
- [`wrdReplaceBookmarkText()`](wrdReplaceBookmarkText.md) : Replace
  Bookmark Text
- [`wrdGoto()`](wrdGoto.md) : Go to a Word Object

## Excel Sessions

Creating, retrieving, registering and terminating an Excel instance.

- [`newXl()`](newXl.md) : Create a New Excel Session
- [`getXl()`](getXl.md) : Get Current Excel Session
- [`setXl()`](setXl.md) : Set Current Excel Session
- [`closeXl()`](closeXl.md) : Close Excel Session
- [`xxlView()`](xXlView.md) : Run xlView() on selected text.
- [`withXl()`](withXl.md) : Temporarily Use an Excel Session
- [`xlKill()`](xlKill.md) : Terminate all Microsoft Excel processes

## Reading from Excel

Transferring the selected range - including disjoint multi-area
selections - into a data frame, matrix, list or table.

- [`xlGetRange()`](xlGetRange.md) : Read the Raw Values of the Selected
  Excel Range(s)
- [`xlParseRange()`](xlParseRange.md) : Organize a Raw Excel Range into
  a data.frame, matrix, list or table
- [`xlImport()`](xlImport.md) : Interactively Import the Selected Excel
  Range into R
- [`xlDataTransferDialog()`](xlDataTransferDialog.md) : Excel Data
  Transfer Dialog

## Writing to Excel

Opening R objects and fitted models in a spreadsheet for inspection.

- [`xlView()`](xlView.md) : View Objects in Excel
- [`xxlView()`](xXlView.md) : Run xlView() on selected text.

## Unit Conversion

Converting between the length units used by the Office object models.

- [`cmToPts()`](cm_pts_conversion.md)
  [`ptsToCm()`](cm_pts_conversion.md) : Convert Between Centimeters and
  Points

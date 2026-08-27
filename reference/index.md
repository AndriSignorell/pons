# Package index

## Word Sessions

Creating, retrieving, registering and closing a Word instance.

- [`newWrd()`](https://andrisignorell.github.io/pons/reference/newWrd.md)
  : Create a New Word Session
- [`getWrd()`](https://andrisignorell.github.io/pons/reference/getWrd.md)
  : Get Current Word Session
- [`setWrd()`](https://andrisignorell.github.io/pons/reference/setWrd.md)
  : Set Current Word Session
- [`closeWrd()`](https://andrisignorell.github.io/pons/reference/closeWrd.md)
  : Close Word Session
- [`withWrd()`](https://andrisignorell.github.io/pons/reference/withWrd.md)
  : Temporarily Use a Word Session

## Writing to Word

Inserting R content into a document and the constants needed to address
the Word object model.

- [`toWrd()`](https://andrisignorell.github.io/pons/reference/toWrd.md)
  : Insert Content into Microsoft Word
- [`wdConst`](https://andrisignorell.github.io/pons/reference/wdConst.md)
  : Word Constants for RDCOMClient

## Word Bookmarks

Creating, listing, renaming and refilling bookmarks - the mechanism that
makes a report updatable in place.

- [`wrdAddBookmark()`](https://andrisignorell.github.io/pons/reference/wrdAddBookmark.md)
  : Add a Word Bookmark
- [`wrdBookmark()`](https://andrisignorell.github.io/pons/reference/wrdBookmark.md)
  : Get a Word Bookmark
- [`wrdDeleteBookmark()`](https://andrisignorell.github.io/pons/reference/wrdDeleteBookmark.md)
  : Delete a Word Bookmark
- [`renameBookmark()`](https://andrisignorell.github.io/pons/reference/renameBookmark.md)
  : Rename a Word Bookmark
- [`bookmarkList()`](https://andrisignorell.github.io/pons/reference/bookmarkList.md)
  : List Word Bookmarks
- [`replaceBookmarkText()`](https://andrisignorell.github.io/pons/reference/replaceBookmarkText.md)
  : Replace Bookmark Text
- [`wrdGoto()`](https://andrisignorell.github.io/pons/reference/wrdGoto.md)
  : Go to a Word Object

## Excel Sessions

Creating, retrieving, registering and terminating an Excel instance.

- [`newXl()`](https://andrisignorell.github.io/pons/reference/newXl.md)
  : Create a New Excel Session
- [`getXl()`](https://andrisignorell.github.io/pons/reference/getXl.md)
  : Get Current Excel Session
- [`setXl()`](https://andrisignorell.github.io/pons/reference/setXl.md)
  : Set Current Excel Session
- [`closeXl()`](https://andrisignorell.github.io/pons/reference/closeXl.md)
  : Close Excel Session
- [`withXl()`](https://andrisignorell.github.io/pons/reference/withXl.md)
  : Temporarily Use an Excel Session
- [`xlKill()`](https://andrisignorell.github.io/pons/reference/xlKill.md)
  : Terminate all Microsoft Excel processes

## Reading from Excel

Transferring the selected range - including disjoint multi-area
selections - into a data frame, matrix, list or table.

- [`xlGetRange()`](https://andrisignorell.github.io/pons/reference/xlGetRange.md)
  : Read the Raw Values of the Selected Excel Range(s)
- [`xlParseRange()`](https://andrisignorell.github.io/pons/reference/xlParseRange.md)
  : Organize a Raw Excel Range into a data.frame, matrix, list or table
- [`xlImport()`](https://andrisignorell.github.io/pons/reference/xlImport.md)
  : Interactively Import the Selected Excel Range into R
- [`xlDataTransferDialog()`](https://andrisignorell.github.io/pons/reference/xlDataTransferDialog.md)
  : Excel Data Transfer Dialog

## Writing to Excel

Opening R objects and fitted models in a spreadsheet for inspection.

- [`xlView()`](https://andrisignorell.github.io/pons/reference/xlView.md)
  : View Objects in Excel
- [`xxlView()`](https://andrisignorell.github.io/pons/reference/xXlView.md)
  : Run xlView() on selected text.

## Unit Conversion

Converting between the length units used by the Office object models.

- [`cmToPts()`](https://andrisignorell.github.io/pons/reference/cm_pts_conversion.md)
  [`ptsToCm()`](https://andrisignorell.github.io/pons/reference/cm_pts_conversion.md)
  : Convert Between Centimeters and Points

# 📦 pons <img src="man/figures/logo.png" align="right" height="139" alt="pons logo" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/pons)](https://CRAN.R-project.org/package=pons)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
<!-- badges: end -->

**Title:** Interface to Microsoft Office for the DescToolsX Ecosystem\
**License:** GPL (≥ 2)

## 🧩 Overview

`pons` is the bridge between R and Microsoft Office. It writes R results
into a running Word document and reads Excel selections back into R,
both through the Component Object Model.

The bookmark functions are what make reporting repeatable: place a
bookmark once in a Word template, and `replaceBookmarkText()` refills it
on every run. A report is then updated in place rather than rebuilt from
scratch, and the layout stays where the author put it.

> **Windows only.** `pons` requires a local installation of Microsoft
> Office and depends on `RDCOMClient`, which is distributed through the
> Omegahat repository rather than CRAN.

📖 **Documentation:** <https://andrisignorell.github.io/pons/>

## ⚙️ Installation

`RDCOMClient` first:

``` r
install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")
```

Then:

``` r
remotes::install_github("AndriSignorell/pons")
```

## 📚 Core Features

### 🔹 Word Sessions

-   `newWrd()`, `getWrd()`, `setWrd()`, `closeWrd()`, `withWrd()`

### 🔹 Writing to Word

-   `toWrd()` — insert content at the current selection, with methods
    for character vectors and arbitrary objects, and control over font,
    paragraph format, style template and bullets
-   `wdConst` — the Word enumeration constants, so numeric values need
    not be looked up

### 🔹 Bookmarks

-   `wrdAddBookmark()`, `wrdBookmark()`, `wrdDeleteBookmark()`,
    `renameBookmark()`
-   `replaceBookmarkText()` — replace the text while preserving the
    bookmark, which Word would otherwise discard
-   `bookmarkList()` — all bookmarks of the document as a data frame
-   `wrdGoto()` — move the selection to a bookmark or other target

### 🔹 Excel Sessions

-   `newXl()`, `getXl()`, `setXl()`, `closeXl()`, `withXl()`,
    `xlKill()`

### 🔹 Reading from Excel

-   `xlGetRange()` — raw values of the selection, including disjoint
    multi-area selections
-   `xlParseRange()` — organise them into a data frame, matrix, list or
    table, with header handling and per-column type detection
-   `xlImport()` — the dialog-driven round trip: read, choose the
    structure, and either assign the object or insert constructive code
    at the editor cursor
-   `xlDataTransferDialog()` — the Tcl/Tk front end used by `xlImport()`

### 🔹 Writing to Excel

-   `xlView()` — open a data frame, matrix, table, vector or nested list
    in Excel, with methods for `lm` and `glm` that write the coefficient
    table, optionally with confidence intervals, ANOVA and fitted values

### 🔹 Units

-   `cmToPts()`, `ptsToCm()`

## 🧪 Example

``` r
library(pons)

# a new document and some content
wrd <- newWrd()
toWrd("Results", style = "heading 1")
toWrd(summary(lm(mpg ~ wt, mtcars)))

# refill a bookmark in a template
replaceBookmarkText("n_patients", "1'284")

# read the current Excel selection
xl <- getXl()
d <- xlParseRange(xlGetRange(xl), as = "data.frame", header = TRUE)

# send a model to Excel
xlView(glm(am ~ wt, mtcars, family = binomial),
       conf.level = 0.95, exponentiate = TRUE)
```

## 🧱 The Suite

`pons` builds on `bedrock` and `pharos` and supplies the Office interface
used by `DescToolsX` and `swissValet`.

## 🙏 Acknowledgements

Parts of the code and documentation were reviewed with the help of large
language models (OpenAI Codex, Anthropic Claude). Every suggestion was
assessed, edited and verified by the maintainer, who remains solely
responsible for the content of this package.

## 📜 License

GPL (≥ 2)

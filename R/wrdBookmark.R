

# Basic bookmark handling code



#' List Word Bookmarks
#'
#' Returns a data frame containing all bookmarks in the active
#' Word document.
#'
#' Bookmarks are returned in the order in which they appear
#' in the document.
#'
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @return
#' A data frame with the following columns:
#' \describe{
#'   \item{id}{Internal Word bookmark ID.}
#'   \item{name}{Bookmark name.}
#'   \item{pagenr}{Page number of the bookmark.}
#'   \item{type}{Bookmark type inferred from the bookmark name.}
#' }
#'
#' @examples
#' \dontrun{
#' wrdBookmarks()
#' }
#'

#' @export
wrdBookmarks <- function(wrd = NULL) {
  
    wrd <- .resolveWrd(wrd)
    wbms <- .bookmarks(wrd)

    n <- wbms$count()
    
    if(n > 0){
      
      # Names in order of their appearing in the document 
      lst <- list()
      for(i in seq_len(n)){
        
        bm <- wbms[[i]]
        
        lst[[i]] <- data.frame(name=bm$name(),
                               pagenr=bm[["range"]]$information(
                                 pons::wdConst$wdActiveEndAdjustedPageNumber), 
                               id=bm[["range"]]$bookmarkid()
        )
      }
      
      bms <- do.call(rbind, lst)
      bms$type <- vapply(bms$name, .bookmarkType, character(1))
      bms <- bms[, c("id", "name", "pagenr", "type")]
      
    } else {
      
      bms <- data.frame(
        id = integer(),
        name = character(),
        pagenr = integer(),
        type = character()
      )
      
    }
    
    return(bms)

}



#' Get a Word Bookmark
#'
#' Retrieves a bookmark object from the active Word document.
#'
#' @param name Bookmark name.
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @return
#' A Word bookmark COM object of class \code{"COMIDispatch"},
#' or \code{NULL} if the bookmark does not exist.
#'
#' @examples
#' \dontrun{
#' bm <- wrdBookmark("intro")
#' }
#'

#' @export
wrdBookmark <- function(name, wrd = NULL){
  
  wrd <- .resolveWrd(wrd)
  
  wbms <- .bookmarks(wrd)
  
  n <- wbms$count()
  
  if(n > 0){
    # get bookmark names
    bmnames <- vapply(
      seq_len(n),
      function(i) wbms[[i]]$name(),
      character(1)
    )
    
    id <- match(name, bmnames)
    
    if (is.na(id))
      res <- NULL
    else
      res <- wbms[[id]]
    # no attributes for S4 objects... :-(
    #  res@idx <- which(name == bmnames)
    
  } else {
    # warning(gettextf("bookmark %s not found", bookmark))
    res <- NULL
  }
  
  return(res)  
  
}



#' Delete a Word Bookmark
#'
#' Deletes a bookmark from the active Word document.
#'
#' @param name Bookmark name.
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @return
#' Logical. Returns \code{TRUE} if the bookmark was deleted,
#' otherwise \code{FALSE}.
#'
#' @examples
#' \dontrun{
#' wrdDeleteBookmark("intro")
#' }
#'

#' @export
wrdDeleteBookmark <- function(name, wrd = NULL){
  
  wrd <- .resolveWrd(wrd)
  
  bookmarks <- .bookmarks(wrd)
  if(bookmarks$exists(name)){
    wrdBookmark(name)$Delete()
    res <- TRUE
  } else {
    warning(gettextf("Bookmark %s does not exist, so there's nothing to delete", name))
    res <- FALSE
  }
  
  return(res)
  # TRUE for success / FALSE for fail
}  




#' Add a Word Bookmark
#'
#' Adds a new bookmark at the current cursor position
#' in the active Word document.
#'
#' @param name Bookmark name.
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @return
#' Invisibly returns the created bookmark COM object.
#'
#' @examples
#' \dontrun{
#' wrdAddBookmark("results")
#' }
#'
#' @export
wrdAddBookmark <- function (name, wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  bookmarks <- .bookmarks(wrd)
  bookmark <- bookmarks$Add(name)
  
  invisible(bookmark)
  
}




#' Replace Bookmark Text
#'
#' Replaces the text content of a bookmark while preserving
#' the bookmark itself.
#'
#' @param name Bookmark name.
#' @param text Replacement text.
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @details
#' Word removes bookmarks automatically when their text
#' content is replaced. This function restores the bookmark
#' after updating the associated text range.
#'
#' @return
#' Invisibly returns \code{TRUE}.
#'
#' @examples
#' \dontrun{
#' wrdReplaceBookmarkText("title", "New title")
#' }
#'
#' @export
wrdReplaceBookmarkText <- function(name, text, wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  bm <- wrdBookmark(name, wrd)
  
  if (is.null(bm)) {
    stop(sprintf("Bookmark '%s' not found", name), call. = FALSE)
  }
  
  rng <- bm[["Range"]]
  rng[["Text"]] <- text
  .bookmarks(wrd)$Add(name, rng)
  
  invisible(TRUE)
  
}


#' Rename a Word Bookmark
#'
#' Renames a bookmark in the active Word document while preserving
#' its associated text range.
#'
#' @param name Existing bookmark name.
#' @param newName New bookmark name.
#' @param wrd A Word COM object. If \code{NULL}, the current
#'   active Word session is used.
#'
#' @details
#' Word bookmarks cannot always be renamed reliably by directly
#' modifying their \code{Name} property. Therefore, this function
#' preserves the bookmark range, deletes the existing bookmark,
#' and recreates it with the new name.
#'
#' If a bookmark with \code{newName} already exists, the function
#' returns \code{FALSE} and leaves the document unchanged.
#'
#' @return
#' Invisibly returns \code{TRUE} on success and
#' \code{FALSE} otherwise.
#'
#' @examples
#' \dontrun{
#' wrdRenameBookmark("old_name", "new_name")
#' }
#'

#' @export
wrdRenameBookmark <- function(name, newName, wrd = NULL) {
  
  wrd <- .resolveWrd(wrd)
  
  bookmarks <- .bookmarks(wrd)
  
  if (!bookmarks$Exists(name)) {
    
    warning(
      gettextf(
        "Bookmark %s does not exist, so there's nothing to rename",
        name
      )
    )
    
    return(invisible(FALSE))
  }
  
  if (bookmarks$Exists(newName)) {
    
    warning(
      gettextf("Bookmark %s already exists", newName)
    )
    
    return(invisible(FALSE))
  }
  
  bm <- wrdBookmark(name, wrd)
  
  rng <- bm[["Range"]]
  
  bm$Delete()
  
  bookmarks$Add(newName, rng)
  
  invisible(TRUE)
  
}




# == internal helper functions ================================================

.bookmarkType <- function(x){
  
  if(startsWith(x, "bmt"))
    "text"
  
  else if(startsWith(x, "bmp"))
    "plot"
  
  else 
    "other"
  
}


.bookmarks <- function(wrd) {
  wrd[["ActiveDocument"]][["Bookmarks"]]
}




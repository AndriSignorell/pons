

# ToDo:
# Make Addin UpdateAllBookmarks() to update all bookmark sections



ToWrdWithBookmark <- function(){
  
  requireNamespace("pons")
  opt <- options(useFancyQuotes = FALSE); on.exit(options(opt))
  
  sel <- rstudioapi::getActiveDocumentContext()$selection[[1]]$text
  if(sel != "") {
    bm <- eval(parse(text=gettextf("pons::toWrd({%s}, bookmark = TRUE)", sel)))
    rstudioapi::modifyRange(gettextf("## BookmarkName: %s\n{\n%s}\n", bm, sel))
    
  } else {
    cat("No selection!\n")
  }
}



ToWrdPlotWithBookmark <- function(){
  
  requireNamespace("pons")
  opt <- options(useFancyQuotes = FALSE); on.exit(options(opt))
  
  sel <- rstudioapi::getActiveDocumentContext()$selection[[1]]$text
  if(sel != "") {
    bm <- eval(parse(text=gettextf("pons::toWrd(pons::wrdPlot({%s}), width = 15, bookmark = TRUE)", sel)))
    rstudioapi::modifyRange(gettextf("## BookmarkName: %s (width = 15)\n{\n%s}\n", 
                                     bm, sel))
    
  } else {
    cat("No selection!\n")
  }
}



.parseBookmark <- function(sel){
  
  # expected structure of the code (args are optional)
  # ## Bookmark: <bookmarkname> (<args>) { <code> }
  # the bookmarkname must consist of bm(p|t)000000000, p standing for plot, t for text
  # the type of the bookmark must be visible in the name, as 
  # updatebookmark gets nothing else...
  
  # first separate the bookmark name between : and { of the selected text
  bm <- strTrim(regmatches(sel, gregexpr("(?s)(?<=:).*?(?=\\{)", sel, perl=TRUE)))
  
  # split name from args and get the bookmark type
  # greedy to the last )
  args <- regmatches(bm, gregexpr("(?<=\\().*(?=\\))", bm, perl=TRUE))[[1]]
  if(length(args) > 0) args <- paste(",", args) else args <- ""
  
  bm <- gsub(" .*", "", bm)   # take first word only as name
  bmtype <- substr(bm, 1, 3)
  
  # get the commands between the brackets
  code <- regmatches(sel, gregexpr("(?s)(?<=\\{).*(?=\\})", sel, perl=TRUE))[[1]]
  
  return(list(name=bm, type=bmtype, args=args, code=code))  
  
}


UpdateBookmark <- function(){
  
  requireNamespace("pons")
  
  sel <- rstudioapi::getActiveDocumentContext()$selection[[1]]$text
  
  if(sel != "") {
    
    bm <- .parseBookmark(sel)
    
    with(bm,    
         if(!is.null(pons::wrdBookmark(name = name))){
           .updateBookmark(bm)
           
         } else {
           warning(gettextf("bookmark %s not found", name))
         }
    )    
    
  } else {
    cat("No selection!\n")
  }
  
}


.updateBookmark <- function(bm, wrd = NULL){
  
  with(bm, {
    
    if(type=="bmt") {         # text bookmark: toWrd() replaces the content
      eval(parse(text=gettextf('pons::toWrd({%s}, bookmark="%s" %s, wrd = wrd)',
                               code, name, args)))
      
    } else if(type=="bmp") {  # plot bookmark: toWrd() replaces the picture
      eval(parse(text=gettextf('pons::toWrd(pons::wrdPlot({%s}), bookmark="%s" %s, wrd = wrd)',
                               code, name, args)))
      
    } else {
      warning(gettextf("unknown bookmark type %s", type)) # warning("unknown bookmark type")
    }
  }) 
  
  invisible()
  
}





RecreateBookmarkChunk <- function(){
  
  requireNamespace("pons")
  opt <- options(useFancyQuotes = FALSE); on.exit(options(opt))
  
  sel <- rstudioapi::getActiveDocumentContext()$selection[[1]]$text
  
  if(sel != "") {
    
    bm <- .parseBookmark(sel)
    
    # create bookmark at current position if it's not already there
    if(is.null(wrdBookmark(bm$name))){
      # create new bookmark with the name in bm
      if(sel=="\n") sel <- "'\n'"
        pons::wrdAddBookmark(name=bm$name)
      # rstudioapi::sendToConsole(gettextf("pons::wrdAddBookmark(name='%s')", bm$name), 
      #                           focus = FALSE)
    }
    
    .updateBookmark(bm)
    
  } else {
    cat("No selection!\n")
  }
  
}







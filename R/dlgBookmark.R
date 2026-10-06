


dlgBookmark <- function(){
  
  requireNamespace("pons")
  requireNamespace("tcltk")
  
  .ManipBM <- function(action, newname=NULL) {
    
    var.name <- as.numeric(tcltk::tkcurselection(tlist.var))
    lst <- .GetVarName(as.character(tcltk::tkget(tlist.var, 0, "end")))
    
    if (length(var.name) == 0)
      tcltk::tkmessageBox(message = "No variable selected",
                          icon = "info", type = "ok")
    
    if (length(var.name) > 0) {
      vn <- pharos::strTrim(lst[var.name + 1])
      if(action=="select"){
        pons::wrdGoto(vn)  
      }
      else if(action=="delete"){
        res <- pons::wrdDeleteBookmark(vn)  
        if(res){
          
          # remove listentry
          # tcltk::tkdelete(tlist.var, var.name)
          
          d.bm <- d.bm[d.bm$name != vn, ]
          
          tcltk::tclvalue(tbm_name) <- d.bm$name
          tcltk::tclvalue(tbm_type) <- d.bm$type
          
          .PopulateListBox(d.bm$name)
          
          return(list(id=var.name, name=vn))
          
        }
      }
      else if(action=="rename"){
        newname <- .GetNewName(vn)
        if(!newname==FALSE)
          wrdRenameBookmark(vn, newname)  
      }
    }
  }
  
  .GetNewName <- function(x){
    .simpEntryDlg("Enter new bookmark name:", default = x, main="Rename Bookmark")
  }
  
  .BtnSelect <- function() .ManipBM("select")
  
  .BtnDelete <- function() {
    res <- .ManipBM("delete")
  }
  
  .BtnRename <- function() .ManipBM("rename", .GetNewName())
  
  .imgFile <- function(fn) {
    system.file("extdata", fn, package = "pons")
  }
  
  imgAsc <-  tcltk::tclVar()
  tclimgAsc <-  tcltk::tkimage.create("photo", 
                    imgAsc, file = .imgFile("SortListAsc.gif"))
  imgDesc <-  tcltk::tclVar()
  tclimgDesc <-  tcltk::tkimage.create("photo", 
                    imgDesc, file = .imgFile("SortListDesc.gif"))
  imgNone <-  tcltk::tclVar()
  tclimgNone <-  tcltk::tkimage.create("photo", 
                    imgNone, file = .imgFile("SortListNo.gif"))
  
  .BtnSortVarListAsc <- function() .SortVarList("a")
  .BtnSortVarListDesc <- function() .SortVarList("d")
  .BtnSortVarListNone <- function() .SortVarList("n")
  
  
  .SortVarList <- function(ord){
    
    lst <- as.character(tcltk::tkget(tlist.var, 0, "end"))
    
    if(ord == "a"){
      v <- pharos::strTrim(sort(lst, decreasing = FALSE))
    } else if(ord == "d"){
      v <- pharos::strTrim(sort(lst, decreasing = TRUE))
    } else {
      v <- pharos::strTrim(.VarNames()[strsplit(tcltk::tclvalue(tbm_name), split=" ")[[1]] %in% .GetVarName(lst)])
    }
    
    .PopulateListBox(v)
    
  }
  
  .FilterVarList <- function(){
    
    pat <- pharos::strTrim(tcltk::tclvalue(tffilter))
    # print(pat)
    if(pat=="")
      v <- .VarNames()
    else
      v <- grep(pattern = pat, .VarNames(), value=TRUE, fixed=TRUE)
    
    # for (i in (length(names(x)):0)) tcltk::tkdelete(tlist.var, i)
    
    .PopulateListBox(v)
    
  }
  
  .SelectVarList <- function(){
    
    var.name <- as.numeric(tcltk::tkcurselection(tlist.var))
    lst <- .GetVarName(as.character(tcltk::tkget(tlist.var, 0, "end")))
    
    if (length(var.name) > 0) {
      
      .EnableBtn(TRUE)
      
      z <- d.bm[d.bm$name==strTrim(lst[var.name + 1]), ]
      txt <- gettextf(" ID:\t%s\n Type:\t%s\n Page:\t%s", z$id, z$type, z$pagenr)
      tcltk::tclvalue(tflbl) <- txt
      
    } else {
      tcltk::tclvalue(tflbl) <- " ID:\t.\n Type:\t.\n Page:\t."  # "\n"
    }
    
  }
  
  
  .VarNames <- function(){
    
    # gettextf("%s (%s)", d.bm$name, d.bm$type)
    gettextf("%s (%s)", strsplit(tcltk::tclvalue(tbm_name), split = " ")[[1]], 
             strsplit(tcltk::tclvalue(tbm_type), split = " ")[[1]])
  }
  
  .GetVarName <- function(x){
    strTrim(gsub(" .*", "", strTrim(x)))
  }
  
  .EmptyListBox <- function(){
    n <- as.character(tcltk::tksize(tlist.var))
    for (i in (n:0)) tcltk::tkdelete(tlist.var, i)
  }
  
  
  .PopulateListBox <- function(x, empty=TRUE){
    
    if(empty)
      .EmptyListBox()
    
    for (z in x) {
      tcltk::tkinsert(tlist.var, "end", paste0(" ", z))
    }
    
    # update frame label
    tcltk::tkconfigure(frmVar, 
                       text=gettextf("Bookmarks (%s/%s):", length(x), 
                                 length(strsplit(tcltk::tclvalue(tbm_name), 
                                                 split=" ")[[1]])))
    
    # as far as there are no selections we should disable action btns
    .EnableBtn(FALSE)
    .SelectVarList()
    
  }
  
  
  .OnOK <- function() {
    tcltk::tkdestroy(root)
  }
  
  .EnableBtn <- function(enable=TRUE){
    if(enable)
      state <- "active"
    else
      state <- "disabled"
    
    tcltk::tkconfigure(tfButSelect, state = state)
    # Renaming needs more work...
    tcltk::tkconfigure(tfButRename, state = "disabled")
    tcltk::tkconfigure(tfButDelete, state = state)
  }
  
  
  # start main proc **************
  
  wrd <- getWrd(FALSE)
  if(is.null(wrd))
    stop("no running instance of word found")
  
  # get the bookmarks of current wrd
  d.bm <- wrdBookmarks()
  
  if(identical(d.bm, NA))
    d.bm <- data.frame(id=NA, name="[...no bookmarks found!]", pagenr="", type="" )
  
  
  fam <- "comic"
  size <- 10
  myfont <- tcltk::tkfont.create(family = fam, size = size)
  mySerfont <- tcltk::tkfont.create(family = "Times", size = size)
  
  tffilter <- tcltk::tclVar("")
  tflbl <- tcltk::tclVar("\n")
  tfframe <- tcltk::tclVar("Variables:")
  
  # the bookmarks for the list
  tbm_name <- tcltk::tclVar(d.bm$name)
  tbm_type <- tcltk::tclVar(d.bm$type)
  
  xname <- wrd[["ActiveDocument"]][["name"]]
  
  # do not update screen
  tcltk::tclServiceMode(on = FALSE)
  
  # create window
  root <- .initDlg(width = 380, height = 550, resizex=FALSE, resizey=FALSE,
                   main=gettextf("Bookmarks (%s)", xname), ico="R")
  
  # define widgets
  content <- tcltk::tkframe(root, padx=10, pady=10)
  
  
  # Variable list
  frmVar <- tcltk::tkwidget(content, "labelframe", text=gettextf("Bookmarks (%s/%s):", nrow(d.bm), nrow(d.bm)),
                            fg = "black", padx = 10, pady = 10, font = myfont)
  
  
  tfFilter <- tcltk::tkentry(frmVar, textvariable=tffilter, width= 20, bg="white")
  tfButSortAsc <- tcltk::tkbutton(frmVar, image = tclimgAsc, compound="none",
                                  command = .BtnSortVarListAsc, height = 21, width = 21)
  tfButSortDesc <- tcltk::tkbutton(frmVar, image = tclimgDesc, compound="none",
                                   command = .BtnSortVarListDesc, height = 21, width = 21)
  tfButSortNone <- tcltk::tkbutton(frmVar, image=tclimgNone, compound="none",
                                   command = .BtnSortVarListNone, height = 21, width = 21)
  var.scr <- tcltk::tkscrollbar(frmVar, repeatinterval = 5,
                                command = function(...) tcltk::tkyview(tlist.var, ...))
  
  tlist.var <- tcltk::tklistbox(frmVar, selectmode = "single",
                                yscrollcommand = function(...)
                                  tcltk::tkset(var.scr, ...), background = "white",
                                exportselection = FALSE, activestyle= "none", highlightthickness=0,
                                height=20, width=20, font = myfont)
  tfVarLabel <- tcltk::tklabel(frmVar, justify="left", width=26, anchor="w", textvariable=tflbl, font=myfont)
  
  tcltk::tclvalue(tflbl) <- " ID:\n Type:\n Page:"
  
  
  tcltk::tkbind(tlist.var)
  tcltk::tkgrid(tfFilter, row=0, padx=0, sticky = "n")
  tcltk::tkgrid(tcltk::tklabel(frmVar, text="  "), row=0, column=1)
  tcltk::tkgrid(tfButSortAsc, row=0, column=2, padx=0, sticky = "n")
  tcltk::tkgrid(tfButSortDesc, row=0, column=3,  sticky = "n")
  tcltk::tkgrid(tfButSortNone, row=0, column=4, sticky = "n")
  tcltk::tkgrid(tcltk::tklabel(frmVar, text=" "))
  tcltk::tkgrid(tlist.var, var.scr, row=2, columnspan=5, sticky = "news")
  tcltk::tkgrid(tfVarLabel, row=3, columnspan=5, pady=3, sticky = "es")
  tcltk::tkgrid.configure(var.scr, sticky = "news")

  # Buttons
  frmButtons <- tcltk::tkwidget(content, "labelframe", text = "",  bd=0,
                                fg = "black", padx = 5, pady = 25)
  
  tfButSelect <- tcltk::tkbutton(frmButtons, text = "Select",
                                 command = .BtnSelect, height = 1, width = 7, font=myfont)
  tfButDelete <- tcltk::tkbutton(frmButtons, text = "Delete",
                                 command = .BtnDelete, height = 1, width = 7, font=myfont)
  tfButRename <- tcltk::tkbutton(frmButtons, text = "Rename",
                                 command = .BtnRename,
                                 height = 1, width = 7, font=myfont)
  
  tcltk::tkgrid(tcltk::tklabel(frmButtons, text="\n\n"))
  tcltk::tkgrid(tfButSelect, row = 40, padx = 5, sticky = "s")
  tcltk::tkgrid(tfButRename, row = 50, padx = 5, sticky = "s")
  tcltk::tkgrid(tfButDelete, row = 60, padx = 5, sticky = "s")
  
  # root
  tfButOK = tcltk::tkbutton(content, text="Close", width=6, command=.OnOK)
  
  tcltk::tkbind(tfFilter, "<KeyRelease>", .FilterVarList)
  tcltk::tkbind(tlist.var, "<ButtonRelease>", .SelectVarList)
  tcltk::tkbind(tlist.var, "<KeyRelease>", .SelectVarList)
  tcltk::tkbind(tlist.var, "<Double-1>", .BtnSelect)
  
  .PopulateListBox(.VarNames())
  
  # build GUI
  tcltk::tkgrid(content, column=0, row=0, sticky = "nwes")
  tcltk::tkgrid(frmVar, padx = 5, pady = 5, row = 0, column = 0,
                rowspan = 20, columnspan = 1, sticky = "ns")
  
  tcltk::tkgrid(frmButtons, padx = 5, pady = 5, row = 0, column = 2,
                rowspan = 20, columnspan = 1, sticky = "ns")
  
  tcltk::tkgrid(tfButOK, column=2, row=30, ipadx=15, padx=5, sticky="es")
  
  tcltk::tkfocus(tlist.var)
  tcltk::tclServiceMode(on = TRUE)
  
  tcltk::tcl("wm", "attributes", root, topmost=TRUE)
  
  tcltk::tkwait.window(root)
  
  invisible()
  
}



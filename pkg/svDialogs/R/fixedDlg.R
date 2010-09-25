guiDlgAssistant <- function (...)
{
    ## This is a non modal assistant dialog box... could also display tips
    ## TODO...
    stop("Not yet implemented!")
}

guiDlgColor <- function (...)
{
    ## A color selection dialog box
    ## TODO: a color range selector?
    stop("Not yet implemented!")
}

guiDlgDir <- function (title = "Select a directory", dir = getwd(), new = TRUE,
parent = 0, GUI = getOption("guiWidgets"))
{
    ## A 'choose a directory' dialog box
    ## It almost follows the conventions of tkchooseDirectory()
    ## The argument dir indicates the initial directory
    ## The argument new indicates if a new file name can be given
    ## parent determines which is the parent window... if 0 then system modal
    ## If cancelled, then return character(0)
    ## This dialog box is always modal

    ## Check arguments
    if (!inherits(title, "character") && length(title) < 1)
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    if (!is.null(new) && !is.na(new)) new <- (new == TRUE) else new <- FALSE
    if (!inherits(dir, "character"))
        stop("'dir' must be a character string!")
    dir <- dir[1]  # Keep only first one, if several are provided
    ## Check this is a directory (if it exists)
    if (file.exists(dir)) {
        if (!file.info(dir)$isdir)
            stop("'dir' must be a directory, not a file!")
    } else {
        if (!new)
            stop("'dir' must be an existing directory if 'new' == TRUE!")
    }
###TO DO: expand abbreviated directories under windows!
###TO DO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
        ## Look for a guiDlgDir.<GUI> function
        fun <- paste("guiDlgDir", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                title = title, dir = dir, new = new, parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## Use tkmessageBox()
    ## parent argument is defined, but not used yet here...
    ## should look how to implement it!
    res <- tclvalue(tkchooseDirectory(initialdir = dir, mustexist = !new,
        title = title))
    ## Bug: if new == FALSE and the user indicated a new dir, and then clicked
    ## 'Cancel', the name of the new dir is returned! => recheck
    if (!new && !file.exists(res)) res <- character(0)
    res <- as.character(res)
    if (res == "") res <- character(0)  # tkchooseDirectory returns "" if cancelled
    return(as.character(res))
}

guiDlgDoubleList <- function (list1, list2, title = "Select", default1 = "",
default2 = "", multi = c(TRUE, TRUE), new = c(FALSE, FALSE), sort = c(TRUE, TRUE),
transfer = FALSE, parent = 0, GUI = getOption("guiWidgets"))
{
    ## A 'dual list' dialog box. This list serves two purposes:
    ## 1) select elements in the first list and place them in the second list
    ##    (transfer = TRUE)
    ## 2) make a double selection in two separate lists
    ## This dialog box is always modal
    stop("Not yet implemented!")
}

guiDlgFont <- function (...)
{
    ## A font selector dialog box
    ## TODO...
    stop("Not yet implemented!")
}

guiDlgFormula <- function (...)
{
    ## This dialog box helps to create S language formulas
    ## R Commander has something like that in glm dialog box. Look with John Fox
    ## for permission to reuse it
    ## TODO...
    stop("Not yet implemented!")
}

guiDlgGraphOptions <- function (...)
{
    ## A graph options dialog box
    ## Idem as guiDlgOptions, but specific to graph parameters? Or is it possible
    ## to reuse guiDlgOptions?
    ## TODO...
    stop("Not yet implemented!")
}

guiDlgGrid <- function (table, title = deparse(substitute(table)), edit = TRUE,
edit.vars = TRUE, add.vars = TRUE, add.rows = TRUE, parent = -1,
GUI = getOption("guiWidgets"))
{
    ## A 'grid' display of a one or two dimensional table (vector, matrix,
    ## data.frame)
    ## It is similar to the data editor in Rgui, but can be non modal (parent = -1)
    ## and can be used just to display the content of a table
    ## TODO: possibly tabbed presentation?
    stop("Not yet implemented!")
}

guiDlgInput <- function (message = "Enter a value", title = "Input",
default = "", parent = 0, GUI = getOption("guiWidgets"))
{
    ## A simple text input box
    ## parent determines which is the parent window... if 0 then it is system modal
    ## This dialog box is always modal
    ## Return either a string, or character(0) if 'Cancel' clicked
    ## TODO: drop down list with previous selections + '...' button

    ## Check arguments
    if (!inherits(message, "character") && length(message) < 1)
        stop("'message' must be a non empty character string!")
    message <- message[1]  # Only keep first item for message
    if (!inherits(title, "character") && length(title) < 1)
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    if (is.null(default)) default <- "" else {
        if (!inherits(default, "character") && length(default) < 1)
            stop("'default' must be a character string or NULL!")
        default <- default[1]  # Only keep first item for default
    }
### TODO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    ## Do we need to use a different widget than Tcl/Tk?
    if (!is.null(GUI) && GUI != "tcltk") {  ## Custom GUI widgets
        ## Look for a guiDlgInput.<GUI> function
        fun <- paste("guiDlgInput", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                message = message, title = title, default = default,
                parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## We construct the input box with tcltk commands
    assignTemp(".res.inbox", character(0))  # Result is temporary stored in this variable
    inbox <- tktoplevel()
    tktitle(inbox) <- title
    wlabel <- tklabel(inbox, text = message)
    varText <- tclVar(default)
    wtext <- tkentry(inbox, width = "50", textvariable = varText)
    onOk <- function () {
        assignTemp(".res.inbox", tclvalue(varText))
        tkdestroy(inbox)
    }
    butFrame <- tkframe(inbox)
    wbutOK <- tkbutton(butFrame, text = "OK", width = "12", command = onOk,
        default = "active")
    wlabSep <- tklabel(butFrame, text = " ")
    wbutCancel <- tkbutton(butFrame, text = "Cancel", width = "12",
        command = function () tkdestroy(inbox))
    tkgrid(wlabel, sticky = "w", padx = 5, pady = 5)
    tkgrid(wtext, padx = 5, pady = 5)
    tkgrid(wbutOK, wlabSep, wbutCancel, sticky = "w")
    tkgrid(butFrame, pady = 5)
    for (row in 0:2) tkgrid.rowconfigure(inbox, row, weight = 0)
    for (col in 0:0) tkgrid.columnconfigure(inbox, col, weight = 0)
    .Tcl("update idletasks")
    tkwm.resizable(inbox, 0, 0)
    tkbind(inbox, "<Return>", onOk)
    tkwm.deiconify(inbox)
    tkfocus(wtext)
    tkselection.from(wtext, "0")
    tkselection.to(wtext, as.character(nchar(default)))
    tkicursor(wtext, as.character(nchar(default)))
    tkwait.window(inbox)
    ## Retrieve result
    res <- getTemp(".res.inbox", default = character(0))
    rmTemp(".res.inbox")
    return(res)
}

guiDlgItemSel <- function (list, classes = NULL, title = "Select items",
default = "", default.items = "",  all.names = FALSE, multi = FALSE,
sort = TRUE, sort.items = FALSE, subset = FALSE, save.restore = FALSE,
parent = 0, GUI = getOption("guiWidgets"))
{
    ## Idem than guiDlgVarSel, but allows also to select items in lists,
    ## data.frames, S4 objects, ...
    ## This is the most advanced var selection dialog box
    ## The argument subset allows to also subset rows
    ## The argument save.restore allows to save (on a file, or in variables?
    ## sel()...) and restore the given selected
    ## TODO: display a summary of the selected object
    stop("Not yet implemented!")
}

guiDlgList <- function (items, multi = FALSE, message = if (multi)
"Select item(s):" else "Select one item:", title = "Selection",
default = 1,  nsel = NULL, new = FALSE, sort = FALSE, width = 50,
parent = 0, GUI = getOption("guiWidgets"))
{
    ## This is a simple 'select in the list' dialog box
    ## It roughly follows the select.list() function under Windows
    ## This dialog box can be non modal (parent = -1). This way, it is a GUI
    ## substitute for 'menu()'
    ## If new = TRUE, an (other...) entry is appended to the list, and if
    ## selected, ask for a different string, or
    ## an entry box is added to the dialog box in most advanced versions

    ## Check arguments
    N <- length(items)
    if (!inherits(items, "character") && N < 1)
        stop("'list' must be a non empty vector of strings!")
    if (N == 1) return(items)  # No selection needed!
    if (!inherits(message, "character") && length(message) < 1)
        stop("'message' must be a non empty character string!")
    message <- paste(message, collapse = "\n")
    if (!inherits(title, "character") && length(title) < 1)
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    if (!is.null(default)) {
        if (!is.numeric(default))
            stop("'default' must be numeric or NULL!")
        default <- as.integer(default)
        if (min(default) < 0 || max(default) > N)
            stop("'default' is outside range!")
    }
    if (!is.null(multi) && !is.na(multi)) multi <- (multi == TRUE) else
        multi <- FALSE
    if (!is.null(nsel)) {
        if (!is.numeric(nsel))
            stop("'nsel' must be numeric or NULL!")
        nsel <- as.integer(nsel)
        if (length(nsel) > 2) nsel <- nsel[1:2]  # Keep only first two
        if (multi) {
            nsel <- sort(nsel)
            if (nsel[1] < 1)
                stop("'nsel' out of range!")
            if (max(nsel) > N)
                stop("'nsel' out of range!")
        }
    }
    if (!is.null(new) && !is.na(new)) new <- (new == TRUE) else
        new <- FALSE
    if (!is.null(sort) && !is.na(sort)) sort <- (sort == TRUE) else
        sort <- FALSE
    if (sort) {
        if (!is.null(default)) default <- (1:N)[match(default, order(items))]
        items <- sort(items)
    }
### TODO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    ## Do we need to use a different widget than Tcl/Tk?
    if (!is.null(GUI) && GUI != "tcltk") { # Custom GUI widgets
        ## Look for a guiDlgList.<GUI> function
        fun <- paste("guiDlgList", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                list = list, title = title, default = default, multi = multi,
                new = new, sort = sort, parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## We construct the list dialog box with tcltk commands
    assignTemp(".res.list", character(0))   # Result is temporary stored in this variable
    lbox <- tktoplevel()
### TODO: this does not work? tkwm.maxsize(lbox, width, -1)
    tktitle(lbox) <- title
    tkgrid(tklabel(lbox, text = message), sticky = "w", padx = 5)
    lstFrame <- tkframe(lbox, width = as.character(width))
    scr <- tkscrollbar(lstFrame, repeatinterval = 5,
           command = function (...) tkyview(tl, ...))
    SelMode <- if (multi) "extended" else "single"
    tl <- tklistbox(lstFrame, width = width - 2, height = 5, selectmode = SelMode,
          yscrollcommand = function (...) tkset(scr, ...), background = "white")
    tkgrid(tl, scr)
    tkgrid.configure(scr, rowspan = 5, sticky = "nsw")
    tkgrid(lstFrame, padx = 5, pady = 2, sticky = "w")
    for (i in 1:(length(items)))
        tkinsert(tl, "end", items[i])
    if (!is.null(default)) {
        for (i in 1:length(default))
        tkselection.set(tl, default[i] - 1)  # Default indexing starts at zero.
        tkyview(tl, default[1] - 1)  # Make sure first selected item is visible
    }
    sep <- tkcanvas(lbox, height = "0", relief = "groove", borderwidth = "1")
    tkgrid(sep)
    onOk <- function () {
        res <- items[as.numeric(tkcurselection(tl)) + 1]
        assignTemp(".res.list", res)
        tkdestroy(lbox)
        return(res)
    }
    butFrame <- tkframe(lbox)
    wbutOK <- tkbutton(butFrame, text = "OK", width = "12", command = onOk,
        default = "active")
    wlabSep <- tklabel(butFrame, text = " ")
    wbutCancel <- tkbutton(butFrame, text = "Cancel", width = "12",
        command = function () tkdestroy(lbox))
    tkgrid(wbutOK, wlabSep, wbutCancel, sticky = "w")
    tkgrid(butFrame, pady = 5)
    .Tcl("update idletasks")
    tkwm.resizable(lbox, 0, 0)
    tkbind(lbox, "<Return>", onOk)
    tkbind(lbox, "<Double-Button-1>", onOk)
    tkwm.deiconify(lbox)
    tkfocus(lbox)
    tkwait.window(lbox)
    ## Retrieve result
    res <- getTemp(".res.list")
    rmTemp(".res.list")
    return(res)
}

guiDlgMessage <- function (message, title = "Message", type = c("ok",
"okcancel", "yesno", "yesnocancel"), default = 1, icon = c("info",
"question", "error", "warning"), parent = 0, GUI = getOption("guiWidgets"))
{
    ## A simple message box
    ## type can be 'ok', 'okcancel', 'yesno', 'yesnocancel'
    ## default indicates which is the default button
    ## icon can be 'info', 'question', 'error', 'warning'
    ## parent determines which is the parent window... if 0 then system modal
    ## This dialog box is always modal
    ## Returns invisibly a character with the button that was pressed

    ## Check arguments
    if (missing(message) || !inherits(message, "character"))
        stop("'message' must be a character string!")
    message <- paste(message, collapse = "\n")
    if (!inherits(title, "character") && length(title) < 1)
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    type <- match.arg(type)
    icon <- match.arg(icon)
### TODO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    ## Do we need to use a different widget than Tcl/Tk?
    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
        ## Look for a guiDlgMessage.<GUI> function
        fun <- paste("guiDlgMessage", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                message = message, title = title, type = type,
                default = default, icon = icon, parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## In tkmessageBox, default is defined differently!
    tkdefault <- switch(type,
        "ok" = "ok",
        "cancel" = "cancel",
        "okcancel" = if (default > 1) "cancel" else "ok",
        "yesno" = if (default > 1) "no" else "yes",
        "yesnocancel" = if (default > 2) "cancel" else
        if (default == 2) "no" else "yes",
            stop("'type' must be \"ok\", \"okcancel\", \"yesno\" or \"yesnocancel\"")
    )
    ## Use tkmessageBox()
### TODO: parent argument is defined, but not used yet here...
### should look how to implement it!
    res <- tkmessageBox(message = message, title = title, type = type,
        default = tkdefault, icon = icon)
    return(tclvalue(res))
}

guiDlgOpen <- function (title = "Select file", defaultFile = "",
defaultDir = "", multi = FALSE, filters = c("All files (*.*)", "*.*"),
parent = 0, GUI = getOption("guiWidgets"))
{
    ## An 'open file(s)' dialog box
    ## title is used as caption of the dialog box
    ## defaultFile allows to preselect a file
    ## defaultDir opens the dialog box in that directory
    ## multi indicates if multiple selection is allowed
    ## filters is a n x 2 matrix of characters with description and filter
    ## for instance: "R or S files"       "*.R;*.q"
    ## unlike Filters in utils, extensions should not be repeated in the
    ## description, and index is always one (arrange the matrix so that
    ## the first entry is the one you like as default!)
    ## parent determines which is the parent window... if 0 then it is system modal
    ## This dialog box is always modal

    ## Check arguments
    if (!inherits(title, "character"))
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    if (!inherits(defaultFile, "character"))
        stop("'defaultFile' must be a non empty character string!")
    defaultFile <- defaultFile[1]  # Keep only first item for defaultFile
    if (!inherits(defaultDir, "character"))
        stop("'defaultDir' must be a non empty character string!")
    defaultDir <- defaultDir[1]  # Keep only first item for defaultDir
    ## If a directory is provided, it must exist
    if (defaultDir != "")
        if (!file.exists(defaultDir) || !file.info(defaultDir)$isdir)
            stop("'defaultDir' must be an existing directory!")
    if (!is.null(multi) && !is.na(multi)) multi <- (multi == TRUE) else
        multi <- FALSE
    ## filters is either a character vector of length 2 or a n * 2 matrix
    if (inherits(filters, "character"))
        filters <- matrix(filters, ncol = 2)
    if (!inherits(filters, "matrix") || mode(filters) != "character" ||
        ncol(filters) != 2)
        stop("'filters' must be a n*2 matrix of characters!")
### TODO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    ## Do we need to use a different widget than Tcl/Tk?
    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
        ## Look for a guiDlgOpen.<GUI> function
        fun <- paste("guiDlgOpen", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                title = title, defaultFile = defaultFile, defaultDir = defaultDir,
                multi = multi, filters = filters, parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## In tkgetOpenFile, filters are presented differently!
    filters <- paste("{\"", filters[, 1], "\" {\"", gsub(";", "\" \"",
        filters[, 2]), "\"}}", sep = "", collapse = " ")
    ## Use tkOpenFile()
### TODO: parent argument is defined, but not used yet here...
### should look how to implement it!
    res <- tclvalue(tkgetOpenFile(title = title, initialfile = defaultFile,
        initialdir = defaultDir, multiple = multi, filetypes = filters))
	if (length(res) == 1 && res == "") res <- character(0)
    return(res)
}

guiDlgOptions <- function (...)
{
    ## An option change dialog box
    ## At left, options are presented in a tree (if possible)
    ## corresponding to a list (or list of lists...)
    ## and at right, the user can define labels, entry boxes, check boxes,
    ## options, sliders, etc...
    ## TODO...
    stop("Not yet implemented!")
}

guiDlgProgress <- function (value, range = c(0, 100),
message = "Please wait...", title = "Progression", percent = TRUE,
cancel = TRUE, icon = "none", parent = -1, GUI = getOption("guiWidgets"))
{
    ## This is an (usually) non modal progression dialog box. It can also display
    ## the text online (or use another function progress()?)
    stop("Not yet implemented!")
}

guiDlgSave <- function (title = "Save As", defaultFile = "", defaultDir = "",
defaultExt = "", filters = c("All files (*.*)", "*.*"), parent = 0,
GUI = getOption("guiWidgets"))
{
    ## A 'save as file' dialog box
    ## It follows the convention of tkgetSaveFile() under Windows, except for
    ## filters, where it is similar to filters argument of choose.files()
    ## defaultFile is a suggested name (and possibly dir for the file)
    ## defaultDir is the initial directory of the dialog box
    ## defaultExt is the default extension (if non provided, automatically
    ## append it to the file name)
    ## filters is a n x 2 matrix of characters with description and filter
    ## for instance: "R or S files"       "*.R;*.q"
    ## unlike Filters in utils, extensions should not be repeated in the
    ## description, and index is always one (arrange the matrix so that
    ## the first entry is the one you like as default!)
    ## If the choosen file already exists, ask for confirmation to replace it!
    ## parent determines which is the parent window... if 0 then it is system modal
    ## This dialog box is always modal

    ## Check arguments
    if (!inherits(title, "character"))
        stop("'title' must be a non empty character string!")
    title <- title[1]  # Keep only first item for title
    if (!inherits(defaultFile, "character"))
        stop("'defaultFile' must be a non empty character string!")
    defaultFile <- defaultFile[1]  # Keep only first item for defaultFile
    if (!inherits(defaultDir, "character"))
        stop("'defaultDir' must be a non empty character string!")
    defaultDir <- defaultDir[1]  # Keep only first item for defaultDir
    ## If a directory is provided, it must exist
    if (defaultDir != "")
        if (!file.exists(defaultDir) || !file.info(defaultDir)$isdir)
        stop("'defaultDir' must be an existing directory!")
    if (!inherits(defaultExt, "character"))
        stop("'defaultExt' must be a character string!")
    defaultExt <- defaultExt[1]  # Keep only first item for defaultExt
    ## filters is either a character vector of length 2 or a n * 2 matrix
    if (inherits(filters, "character"))
        filters <- matrix(filters, ncol = 2)
    if (!inherits(filters, "matrix") || mode(filters) != "character" ||
        ncol(filters) != 2)
        stop("'filters' must be a n*2 matrix of characters!")
### TODO: check 'parent'!
    if (!inherits(GUI, "character") && !is.null(GUI))
        stop("'GUI' must be a character string or NULL!")

    ## Do we need to use a different widget than Tcl/Tk?
    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
        ## Look for a guiDlgSave.<GUI> function
        fun <- paste("guiDlgSave", GUI, sep=".")
        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
                title = title, defaultFile = defaultFile, defaultDir = defaultDir,
                defaultExt = defaultExt, filters = filters, parent = parent)
            if (!is.null(res)) {
                return(res)
            } else warning("Using default Tcl/tk dialog box instead!")
        }
    }
    ## Otherwise, use the default Tcl/Tk dialog box
    ## In tkgetSaveFile, filters are presented differently!
    filters <- paste("{\"", filters[, 1], "\" {\"", gsub(";", "\" \"",
        filters[, 2]), "\"}}", sep = "", collapse = " ")
    ## Use tkSaveFile()
### TODO: parent argument is defined, but not used yet here...
### should look how to implement it!
    res <- tclvalue(tkgetSaveFile(title = title, initialfile = defaultFile,
        initialdir = defaultDir, defaultextension = defaultExt,
        filetypes = filters))
    return(res)
}

guiDlgText <- function (text, file = NULL, title = deparse(substitute(text)),
edit = TRUE, submit = TRUE, parent = -1, GUI = getOption("guiWidgets"))
{
    ## A simple 'text' display/editor. It can display the content of a character
    ## variable, or of a file
    ## It can be used as simple script editor, and if submit = TRUE, it offers
    ## the possibility to submit its content to R
    ## It is similar to the script editor in Rgui 2.0.0, and of its pager at the
    ## same time
    ## It can be non modal (parent = -1)
    ## TODO: possibly tabbed presentation?
    stop("Not yet implemented!")
}

guiDlgVarSel <- function (list, classes = NULL, title = "Select a variable",
default = "", all.names = FALSE, multi = FALSE, new = FALSE, sort = TRUE,
parent = 0, GUI = getOption("guiWidgets"))
{
    ## This is similar to guiDlgList(), but it is specific for variable selection.
    ## If list is NULL, all variables of .GlobalEnv whose class belong to classes
    ## are indicated
    ## all.names indicates if hidden items should be also displayed
    ## This dialog box is always modal
    ## TO DO: display a summary of the selected object
    stop("Not yet implemented!")
}

guiDlgView <- function (file, CSSfile, title = "View", report = TRUE,
parent = -1, GUI = getOption("guiWidgets"))
{
    ## A 'view' dialog box (views are HTML presentation of R objects introduced
    ## in SciViews-R version 0.6-0)
    ## It can be non modal (parent = -1)
    ## TODO: possibly tabbed presentation?
    ## Possibly remove this, cf, SciViews specific!?
    stop("Not yet implemented!")
}

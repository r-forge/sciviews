#dlgOpen <- function (title = "Select file", defaultFile = "",
#defaultDir = "", multi = FALSE, filters = c("All files (*.*)", "*.*"),
#parent = 0, GUI = getOption("guiWidgets"))
#{
#    ## An 'open file(s)' dialog box
#    ## title is used as caption of the dialog box
#    ## defaultFile allows to preselect a file
#    ## defaultDir opens the dialog box in that directory
#    ## multi indicates if multiple selection is allowed
#    ## filters is a n x 2 matrix of characters with description and filter
#    ## for instance: "R or S files"       "*.R;*.q"
#    ## unlike Filters in utils, extensions should not be repeated in the
#    ## description, and index is always one (arrange the matrix so that
#    ## the first entry is the one you like as default!)
#    ## parent determines which is the parent window... if 0 then it is system modal
#    ## This dialog box is always modal
#
#    ## Check arguments
#    if (!inherits(title, "character"))
#        stop("'title' must be a non empty character string!")
#    title <- title[1]  # Keep only first item for title
#    if (!inherits(defaultFile, "character"))
#        stop("'defaultFile' must be a non empty character string!")
#    defaultFile <- defaultFile[1]  # Keep only first item for defaultFile
#    if (!inherits(defaultDir, "character"))
#        stop("'defaultDir' must be a non empty character string!")
#    defaultDir <- defaultDir[1]  # Keep only first item for defaultDir
#    ## If a directory is provided, it must exist
#    if (defaultDir != "")
#        if (!file.exists(defaultDir) || !file.info(defaultDir)$isdir)
#            stop("'defaultDir' must be an existing directory!")
#    if (!is.null(multi) && !is.na(multi)) multi <- (multi == TRUE) else
#        multi <- FALSE
#    ## filters is either a character vector of length 2 or a n * 2 matrix
#    if (inherits(filters, "character"))
#        filters <- matrix(filters, ncol = 2)
#    if (!inherits(filters, "matrix") || mode(filters) != "character" ||
#        ncol(filters) != 2)
#        stop("'filters' must be a n*2 matrix of characters!")
#### TODO: check 'parent'!
#    if (!inherits(GUI, "character") && !is.null(GUI))
#        stop("'GUI' must be a character string or NULL!")
#
#    ## Do we need to use a different widget than Tcl/Tk?
#    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
#        ## Look for a guiDlgOpen.<GUI> function
#        fun <- paste("guiDlgOpen", GUI, sep=".")
#        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
#            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
#                title = title, defaultFile = defaultFile, defaultDir = defaultDir,
#                multi = multi, filters = filters, parent = parent)
#            if (!is.null(res)) {
#                return(res)
#            } else warning("Using default Tcl/tk dialog box instead!")
#        }
#    }
#    ## Otherwise, use the default Tcl/Tk dialog box
#    ## In tkgetOpenFile, filters are presented differently!
#    filters <- paste("{\"", filters[, 1], "\" {\"", gsub(";", "\" \"",
#        filters[, 2]), "\"}}", sep = "", collapse = " ")
#    ## Use tkOpenFile()
#### TODO: parent argument is defined, but not used yet here...
#### should look how to implement it!
#    res <- tclvalue(tkgetOpenFile(title = title, initialfile = defaultFile,
#        initialdir = defaultDir, multiple = multi, filetypes = filters))
#	if (length(res) == 1 && res == "") res <- character(0)
#    return(res)
#}
#
#dlgSave <- function (title = "Save As", defaultFile = "", defaultDir = "",
#defaultExt = "", filters = c("All files (*.*)", "*.*"), parent = 0,
#GUI = getOption("guiWidgets"))
#{
#    ## A 'save as file' dialog box
#    ## It follows the convention of tkgetSaveFile() under Windows, except for
#    ## filters, where it is similar to filters argument of choose.files()
#    ## defaultFile is a suggested name (and possibly dir for the file)
#    ## defaultDir is the initial directory of the dialog box
#    ## defaultExt is the default extension (if non provided, automatically
#    ## append it to the file name)
#    ## filters is a n x 2 matrix of characters with description and filter
#    ## for instance: "R or S files"       "*.R;*.q"
#    ## unlike Filters in utils, extensions should not be repeated in the
#    ## description, and index is always one (arrange the matrix so that
#    ## the first entry is the one you like as default!)
#    ## If the choosen file already exists, ask for confirmation to replace it!
#    ## parent determines which is the parent window... if 0 then it is system modal
#    ## This dialog box is always modal
#
#    ## Check arguments
#    if (!inherits(title, "character"))
#        stop("'title' must be a non empty character string!")
#    title <- title[1]  # Keep only first item for title
#    if (!inherits(defaultFile, "character"))
#        stop("'defaultFile' must be a non empty character string!")
#    defaultFile <- defaultFile[1]  # Keep only first item for defaultFile
#    if (!inherits(defaultDir, "character"))
#        stop("'defaultDir' must be a non empty character string!")
#    defaultDir <- defaultDir[1]  # Keep only first item for defaultDir
#    ## If a directory is provided, it must exist
#    if (defaultDir != "")
#        if (!file.exists(defaultDir) || !file.info(defaultDir)$isdir)
#        stop("'defaultDir' must be an existing directory!")
#    if (!inherits(defaultExt, "character"))
#        stop("'defaultExt' must be a character string!")
#    defaultExt <- defaultExt[1]  # Keep only first item for defaultExt
#    ## filters is either a character vector of length 2 or a n * 2 matrix
#    if (inherits(filters, "character"))
#        filters <- matrix(filters, ncol = 2)
#    if (!inherits(filters, "matrix") || mode(filters) != "character" ||
#        ncol(filters) != 2)
#        stop("'filters' must be a n*2 matrix of characters!")
#### TODO: check 'parent'!
#    if (!inherits(GUI, "character") && !is.null(GUI))
#        stop("'GUI' must be a character string or NULL!")
#
#    ## Do we need to use a different widget than Tcl/Tk?
#    if (!is.null(GUI) && GUI != "tcltk") {  # Custom GUI widgets
#        ## Look for a guiDlgSave.<GUI> function
#        fun <- paste("guiDlgSave", GUI, sep=".")
#        if (exists(fun, where = 1, mode = "function", inherits = TRUE)) {
#            res <- get(fun, pos = 1, mode = "function", inherits = TRUE)(
#                title = title, defaultFile = defaultFile, defaultDir = defaultDir,
#                defaultExt = defaultExt, filters = filters, parent = parent)
#            if (!is.null(res)) {
#                return(res)
#            } else warning("Using default Tcl/tk dialog box instead!")
#        }
#    }
#    ## Otherwise, use the default Tcl/Tk dialog box
#    ## In tkgetSaveFile, filters are presented differently!
#    filters <- paste("{\"", filters[, 1], "\" {\"", gsub(";", "\" \"",
#        filters[, 2]), "\"}}", sep = "", collapse = " ")
#    ## Use tkSaveFile()
#### TODO: parent argument is defined, but not used yet here...
#### should look how to implement it!
#    res <- tclvalue(tkgetSaveFile(title = title, initialfile = defaultFile,
#        initialdir = defaultDir, defaultextension = defaultExt,
#        filetypes = filters))
#    return(res)
#}

## These items still need to be implemented!
#dlgAssistant <- function (...)
#{
#    ## This is a non modal assistant dialog box... could also display tips
#    ## TODO...
#    stop("Not yet implemented!")
#}

#dlgColor <- function (...)
#{
#    ## A color selection dialog box
#    ## TODO: a color range selector?
#    stop("Not yet implemented!")
#}

#dlgDoubleList <- function (list1, list2, title = "Select", default1 = "",
#default2 = "", multi = c(TRUE, TRUE), new = c(FALSE, FALSE), sort = c(TRUE, TRUE),
#transfer = FALSE, parent = 0, GUI = getOption("guiWidgets"))
#{
#    ## A 'dual list' dialog box. This list serves two purposes:
#    ## 1) select elements in the first list and place them in the second list
#    ##    (transfer = TRUE)
#    ## 2) make a double selection in two separate lists
#    ## This dialog box is always modal
#    stop("Not yet implemented!")
#}

#dlgFont <- function (...)
#{
#    ## A font selector dialog box
#    ## TODO...
#    stop("Not yet implemented!")
#}

#dlgFormula <- function (...)
#{
#    ## This dialog box helps to create S language formulas
#    ## R Commander has something like that in glm dialog box. Look with John Fox
#    ## for permission to reuse it
#    ## TODO...
#    stop("Not yet implemented!")
#}

#dlgGraphOptions <- function (...)
#{
#    ## A graph options dialog box
#    ## Idem as guiDlgOptions, but specific to graph parameters? Or is it possible
#    ## to reuse guiDlgOptions?
#    ## TODO...
#    stop("Not yet implemented!")
#}

#dlgGrid <- function (table, title = deparse(substitute(table)), edit = TRUE,
#edit.vars = TRUE, add.vars = TRUE, add.rows = TRUE, parent = -1,
#GUI = getOption("guiWidgets"))
#{
#    ## A 'grid' display of a one or two dimensional table (vector, matrix,
#    ## data.frame)
#    ## It is similar to the data editor in Rgui, but can be non modal (parent = -1)
#    ## and can be used just to display the content of a table
#    ## TODO: possibly tabbed presentation?
#    stop("Not yet implemented!")
#}

#dlgItemSel <- function (list, classes = NULL, title = "Select items",
#default = "", default.items = "",  all.names = FALSE, multi = FALSE,
#sort = TRUE, sort.items = FALSE, subset = FALSE, save.restore = FALSE,
#parent = 0, GUI = getOption("guiWidgets"))
#{
#    ## Idem than guiDlgVarSel, but allows also to select items in lists,
#    ## data.frames, S4 objects, ...
#    ## This is the most advanced var selection dialog box
#    ## The argument subset allows to also subset rows
#    ## The argument save.restore allows to save (on a file, or in variables?
#    ## sel()...) and restore the given selected
#    ## TODO: display a summary of the selected object
#    stop("Not yet implemented!")
#}

#dlgOptions <- function (...)
#{
#    ## An option change dialog box
#    ## At left, options are presented in a tree (if possible)
#    ## corresponding to a list (or list of lists...)
#    ## and at right, the user can define labels, entry boxes, check boxes,
#    ## options, sliders, etc...
#    ## TODO...
#    stop("Not yet implemented!")
#}

#dlgProgress <- function (value, range = c(0, 100),
#message = "Please wait...", title = "Progression", percent = TRUE,
#cancel = TRUE, icon = "none", parent = -1, GUI = getOption("guiWidgets"))
#{
#    ## This is an (usually) non modal progression dialog box. It can also display
#    ## the text online (or use another function progress()?)
#    stop("Not yet implemented!")
#}

#dlgText <- function (text, file = NULL, title = deparse(substitute(text)),
#edit = TRUE, submit = TRUE, parent = -1, GUI = getOption("guiWidgets"))
#{
#    ## A simple 'text' display/editor. It can display the content of a character
#    ## variable, or of a file
#    ## It can be used as simple script editor, and if submit = TRUE, it offers
#    ## the possibility to submit its content to R
#    ## It is similar to the script editor in Rgui 2.0.0, and of its pager at the
#    ## same time
#    ## It can be non modal (parent = -1)
#    ## TODO: possibly tabbed presentation?
#    stop("Not yet implemented!")
#}

#dlgVarSel <- function (list, classes = NULL, title = "Select a variable",
#default = "", all.names = FALSE, multi = FALSE, new = FALSE, sort = TRUE,
#parent = 0, GUI = getOption("guiWidgets"))
#{
#    ## This is similar to guiDlgList(), but it is specific for variable selection.
#    ## If list is NULL, all variables of .GlobalEnv whose class belong to classes
#    ## are indicated
#    ## all.names indicates if hidden items should be also displayed
#    ## This dialog box is always modal
#    ## TO DO: display a summary of the selected object
#    stop("Not yet implemented!")
#}

#dlgView <- function (file, CSSfile, title = "View", report = TRUE,
#parent = -1, GUI = getOption("guiWidgets"))
#{
#    ## A 'view' dialog box (views are HTML presentation of R objects introduced
#    ## in SciViews-R version 0.6-0)
#    ## It can be non modal (parent = -1)
#    ## TODO: possibly tabbed presentation?
#    ## Possibly remove this, cf, SciViews specific!?
#    stop("Not yet implemented!")
#}

"guiCmd" <-
function(command, ...) {
    # This function sends a command to the GUI client
    # The actual code is a custom function named .guiCmd in TempEnv
	CmdFun <- getTemp(".guiCmd", mode = "function")
    if (!is.null(CmdFun)) return(CmdFun(command, ...)) else return(NULL)
}

"guiLoad" <-
function(...) # Ask the GUI client to select a .Rdata file to load()
	return(guiCmd("load", ...))

"guiSource" <-
function(...) # Ask the GUI client to select a .R file to source()
	return(guiCmd("source", ...)) # Should use sys.source() here

"guiSave" <-
function(...) # Ask the client for a file where to save some data
	return(guiCmd("save", ...))

"guiImport" <-
function(...) # Ask the client to display a dialog for importing some data
	return(guiCmd("import", ...))

"guiExport" <-
function(...) # Ask the client to display a dialog for exporting some data
	return(guiCmd("export", ...))

"guiReport" <-
function(...) # Ask the client to display a dialog for reporting data (send a view...)
	return(guiCmd("report", ...))

"guiSetwd" <-
function(...) # Ask the GUI client to select a directory to set as active
	return(guiCmd("setwd", ...))

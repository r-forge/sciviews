## Menu functions
.menuClear <- function ()
{
	res <- switch(Sys.info()["sysname"],
		Windows = NULL,
		Darwin = .macMenuClear(),
		.unixMenuClear()
	)
	return(invisible(res))
}

menuAdd <- function (menuname)
{
	res <- switch(Sys.info()["sysname"],
		Windows = winMenuAdd(menuname),
		Darwin = .macMenuAdd(menuname),
		.unixMenuAdd(menuname)
	)
	return(invisible(res))
}

menuAddItem <- function (menuname, itemname, action)
{
	res <- switch(Sys.info()["sysname"],
		Windows = winMenuAddItem(menuname, itemname, action),
		Darwin = .macMenuAddItem(menuname, itemname, action),
		.unixMenuAddItem(menuname, itemname, action)
	)
	return(invisible(res))
}

menuDel <- function (menuname)
{
	res <- switch(Sys.info()["sysname"],
		Windows = try(winMenuDel(menuname), silent = TRUE),
		Darwin = .macMenuDel(menuname),
		.unixMenuDel(menuname)
	)
	return(invisible(res))
}

menuDelItem <- function (menuname, itemname)
{
	res <- switch(Sys.info()["sysname"],
		Windows = try(winMenuDelItem(menuname, itemname), silent = TRUE),
		Darwin = .macMenuDelItem(menuname, itemname),
		.unixMenuDelItem(menuname, itemname)
	)
	return(invisible(res))
}


## Windows version and standard winMenuXXX
## TODO: fallback system for Rterm???

## Mac OS X version
## Note, either we use AppleScript folder (by default) or the XMenu folder
## Install XMenu from http://xmenu.en.softonic.com/mac.
## You should use the custom commands only for R, because it will erase
## everything in it everytime the svDialogs package starts!
## Configure XMenu to display only User-Defined items, and name it R.
## Select folders before files, for icons: None, Big font
## and for menu titles: Text and then, Start at login
#options(useXMenu = TRUE)
.macMenuFolder <- function ()
{
	## Get the root folder for the R menus, depends on wether we use XMenu or not
	useXMenu <- getOption("useXMenu", default = NULL)
	if (is.null(useXMenu)) {
		## If not specified, look if a "R" file or folder exists
		useXMenu <- file.exists("~/Library/Application Support/XMenu/R")
	} else useXMenu <- isTRUE(useXMenu)	
	return(getOption("menuFolder", default = if (useXMenu)
		"~/Library/Application Support/XMenu/Custom" else
		"~/Library/Scripts/Applications/R"))
}

.macMenuClear <- function () {
    ## To be called when svDialogs package loads: make sure to zap all
    ## custom menu items that may have been previously defined
    ## (also call it when the package closes)
    odir <- getwd()
    on.exit(setwd(odir))
    setwd(.macMenuFolder())
	setwd("..")
    folder <- file.path(".", basename(.macMenuFolder()))
	unlink(folder, recursive = TRUE)
    dir.create(folder, recursive = TRUE)
    ## Now, I can assume that the dir is created and is empty
    return(invisible(NULL))
}

.macMenuAdd <- function (menuname)
{
    ## Menus are folders created in ~/Scripts/Applications/R/Custom
    ## I just need to create (recursively) the directories
    dir.create(file.path(.macMenuFolder(), menuname),
		showWarnings = FALSE, recursive = TRUE)
    return(invisible(NULL))
}

.macMenuAddItem <- function (menuname, itemname, action)
{
    ## Make sure that the dir is created
    .macMenuAdd(menuname)
    ## Switch to this folder
	odir <- getwd()
    on.exit(setwd(odir))
    setwd(file.path(.macMenuFolder(), menuname))
	## Add an executable file in it with 'itemname' name
	## that contains AppleScript code to run action in R
	## Determine if R is run in R.app or in a terminal window
	if (.Platform$GUI == "AQUA") {
		## Can be R or R64 or SciViews R or SciViews R64!
		app <- paste('"', system("osascript -e 'name of application \"R\"'",
			intern = TRUE), '"', sep = "")
	} else app <- "\"Terminal\""
	## Define action accordingly
	if (action == "none") {
		cmd <- "to activate"
	} else {
		## Make sure to quote "
		action <- gsub('"', '\\\\"', action)
		## Also replace \n, \r and \t
		action <- gsub('\n', '\\\\\\\\n', action)
		action <- gsub('\r', '\\\\\\\\r', action)
		action <- gsub('\t', '\\\\\\\\t', action)
		if (app == "\"Terminal\"") {
			cmd <- paste("to do script \"", action, "\" in window 1", sep = "")	
		} else {
			cmd <- paste("to cmd \"", action, "\"", sep = "")
		}
	}
	## Compile applescript item
	system(paste("osacompile -e 'tell application ", app, " ", cmd,
		"' -o \"", itemname, ".app\"", sep = ""), ignore.stdout = TRUE,
		ignore.stderr = TRUE)
    return(invisible(NULL))
}

.macMenuDel <- function (menuname)
{
    ## Unlink does not like ~ => change working dir first
    odir <- getwd()
    on.exit(setwd(odir))
    setwd(.macMenuFolder())
    unlink(menuname, recursive = TRUE)
    return(invisible(NULL))
}

.macMenuDelItem <- function (menuname, itemname)
{
    ## Unlink does not like ~ => change working dir first
    odir <- getwd()
    on.exit(setwd(odir))
    setwd(file.path(.macMenuFolder()))
	unlink(file.path(".", menuname, paste(itemname, "app", sep = ".")),
		recursive = TRUE) 
    return(invisible(NULL))    
}


## Linux/Unix version
## Explanation: to run this, you need to install xvkbd and file-browser-applet
## for Gnome. Under Ubuntu, you make:
## sudo apt-get install file-browser-apple
## sudo apt-get install xvkbd
## You need to log out and in again to make the applet available
## Then, you need to install and configure a file browser applet in a panel
## right-click in a panel, select 'add to Panel...' and drag&drop a 'File Browser'
## Right-click on the file browser and select 'Preferences'. In the preference
## box, eleminate the default entry (Home) and add all subdirectories from
## ~/Scripts/Applications/R. You can access R menus from there, and it sends
## corresponding commands to the focused window (e.g., a terminal running R)
## TODO: find a similar item for KDE and new Ubuntu unity interface!
## winMenuAdd(), winMenuAddItem(), winMenuDel() and winMenuDelItem() already
## defined for windows RGui, but need a substitution for Rterm!
.unixMenuFolder <- function ()
{
	## Get the root folder for the R menus
	return(getOption("menuFolder", default = "~/R/R menu"))
}

.unixMenuClear <- function () {
    ## To be called when svDialogs package loads: make sure to zap all
    ## custom menu items that may have been previously defined
    ## (also call it when the package closes)
    odir <- getwd()
    on.exit(setwd(odir))
    res <- try(setwd(.unixMenuFolder()), silent = TRUE)
	if (inherits(res, "try-error")) {
		## The directory does not exists yet... create it!
		dir.create(.uniMenuFolder(), recursive = TRUE)
	} else {
		## The directory already exists... clear it now
		setwd("..")
		folder <- file.path(".", basename(.unixMenuFolder()))
		unlink(folder, recursive = TRUE)
	}
	dir.create(folder, recursive = TRUE)
    ## Now, I can assume that the dir is created and is empty
    return(invisible(NULL))
}

.unixMenuAdd <- function (menuname) {
    ## I just need to create (recursively) the directories
    dir.create(file.path(.unixMenuFolder(), menuname),
		showWarnings = FALSE, recursive = TRUE)
    return(invisible(NULL))
}

.unixMenuAddItem <- function (menuname, itemname, action) {
    ## Make sure that the dir is created
    .unixMenuAdd(menuname)
    ## Add an executable file in it with 'itemname' name
    ## and containing: xvkbd -text "action\r" except if action is "none"
    cmdFile <- file.path(.unixMenuFolder(), menuname, itemname)
	if (action == "none") {
		cat("\n", file = cmdFile)
    } else {
		## Make sure to quote "
		action <- gsub('"', '\\\\"', action)
		## Also replace \n, \r and \t (and wait 200ms between lines)
		action <- gsub('\n', '\\\\r\\\\D2', action)
		action <- gsub('\r', '\\\\r\\\\D2', action)
		action <- gsub('\t', '    ', action)
		cat("xvkbd -text \"", action, "\\r\"\n", sep = "", file = cmdFile)
    }
    ## Make this file executable
    Sys.chmod(cmdFile, mode = "755")
    return(invisible(NULL))
}

.unixMenuDel <- function (menuname) {
    ## Unlink does not like ~ => change working dir first
    odir <- getwd()
    on.exit(setwd(odir))
    setwd(.unixMenuFolder())
    unlink(menuname, recursive = TRUE)
    return(invisible(NULL))
}

.unixMenuDelItem <- function (menuname, itemname) {
    ## Unlink does not like ~ => change working dir first
    path <- file.path(.unixMenuFolder(), menuname)
    if (file.exists(path) && file.info(path)$isdir) {
		odir <- getwd()
		on.exit(setwd(odir))
		setwd(path)
		unlink(itemname)
    }
    return(invisible(NULL))    
}

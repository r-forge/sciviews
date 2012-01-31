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

.menuFileInit <- function ()
{
		res <- switch(Sys.info()["sysname"],
		Windows = NULL,
		Darwin = NULL, # TODO: should we have a default menu?
		.unixMenuFileInit()
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

## This holds the custom menu structure in an R object
.Rmenu <- function ()
{
	## The custom R menu is cached in a Rmenu object in TempEnv
	return(getTemp("Rmenu", default = list(), mode = "list"))
}

## Linux/Unix version
## To use R custom context menu, you have to install xvkbd and xdotool
## You need also to compile and install myGtkmenu
## On Ubuntu:
## sudo apt-get install xvkbd xdotool
## Warning, you need to insqtall the English (US) keymap, even if you don't use
## it. Otherwise, xvkbd will issue strange things in your R console!
## TODO: install and configure ctxmenu... + add shortcut keys!
## Use xbindkeys to bind shell commands to keyboard and mouse keys
## chmod +x ctxmenu
##
## THIS IS THE OLD VERSION (COMMENTED CODE BELLOW!)
## Explanation: to run this, you need to install xvkbd and file-browser-applet
## for Gnome. Under Ubuntu, you make:
## sudo apt-get install file-browser-apple
## sudo apt-get install xvkbd
## You need to log out and in again to make the applet available
## Then, you need to install and configure a file browser applet in a panel
## right-click in a panel, select 'add to Panel...' and drag&drop a 'File Browser'
## Right-click on the file browser and select 'Preferences'. In the preference
## box, eliminate the default entry (Home) and add all subdirectories from
## ~/Scripts/Applications/R. You can access R menus from there, and it sends
## corresponding commands to the focused window (e.g., a terminal running R)
## TODO: find a similar item for KDE and new Ubuntu unity interface!
## winMenuAdd(), winMenuAddItem(), winMenuDel() and winMenuDelItem() already
## defined for windows RGui, but need a substitution for Rterm!
.unixMenuFolder <- function ()
{
	## Get the root folder for the R menus
	return(getOption("menuFolder", default = "/tmp"))
}

.unixMenuFile <- function ()
{
	## Get the name of the file that contains the R menu
	return(file.path(.unixMenuFolder(), paste(Sys.getenv("WINDOWID"),
		"Menu.txt", sep = "")))
}

.unixMenuFileInit <- function ()
{
	## Initialize the R menu file with default items
	fil <- .unixMenuFile()
	## Get the default R menu and start from there
	def <- getOption("RMenuFile",
		default = file.path("~", ".ctxmenu", "RMenu.txt"))
	if (file.exists(def)) {
		file.copy(def, fil, overwrite = TRUE)
	} else file.copy(system.file("gui", "RMenu.txt", package = "svDialogs"),
		fil, overwrite = TRUE)
	return(invisible(NULL))
}

.unixMenuSave <- function (mnu, file = TRUE)
{
	## Save the menu structure in both Rmenu object in TempEnv and in a file
	## mnu is either a list of lists with menu entries, or NULL to delete all
	## custom menus
	assignTemp("Rmenu", mnu)
	if (!isTRUE(file)) return(invisible(NULL))
	## The menu file is:
	fil <- .unixMenuFile()
	if (is.null(mnu)) {
		## Clear the file
		unlink(fil)
	} else {
		## Populate the file with the content of the Rmenu object
		makeMenu <- function (lst, indent = 0, file = fil) {
			l <- length(lst)
			if (l < 1) return()
			nms <- names(lst)
			for (i in 1:l) {
				item <- nms[i]
				if (is.list(lst[[i]])) {
					## Create a new menu
					cat("\n", rep("\t", indent), "submenu=", item, "\n",
						sep = "", file = file, append = TRUE)
					makeMenu(lst[[i]], indent = indent + 1)
				} else {
					## Is this a separator?
					if (grepl("^-",  item)) {
						cat("\n", rep("\t", indent), "separator\n",
							sep = "", file = file, append = TRUE)
					} else { # Add an item in current menu
						ind <- rep("\t", indent)
						## Rework commands using xvkbd -text "cmd\r"
						cmd <- as.character(lst[[i]])[1]
						if (cmd == "none") {
							cmd <- "NULL" # This is the "no cmd" for ctxmenu
						} else {
							cmd <- paste(cmd, "\\r", sep = "")
							cmd <- paste("xvkbd -text", shQuote(cmd))
						}
						cat("\n", ind, "item=", item, "\n", ind, "cmd=", cmd,
							"\n", sep = "", file = file, append = TRUE)
					}
				}
			}
		}
		## Initialize the menu with default items
		.unixMenuFileInit()
		## Add custom menus to it...
		cat("\nseparator # Here starts the custom R menus\n\n",
			file = fil, append = TRUE)
		makeMenu(mnu)
	}
	return(invisible(fil))
}

.unixMenuClear <- function ()
{
    ## To be called when svDialogs package loads: make sure to zap all
    ## custom menu items that may have been previously defined
    ## (also call it when the package closes)
#    odir <- getwd()
#    on.exit(setwd(odir))
#    res <- try(setwd(.unixMenuFolder()), silent = TRUE)
#	if (inherits(res, "try-error")) {
#		## The directory does not exists yet... create it!
#		dir.create(.unixMenuFolder(), recursive = TRUE)
#		## TODO: put the default R menu there...
#	} else {
#		## The directory already exists... clear it now
#		setwd("..")
#		folder <- file.path(".", basename(.unixMenuFolder()))
#		unlink(folder, recursive = TRUE)
#		dir.create(folder, recursive = TRUE)
#		## TODO: a different procedure that does not delete the default R menu
#	}
    ## Now, I can assume that the dir is created and is empty

	## Make also sure that 'Rmenu' application is installed
	## TODO...

	## Also clear the local object
	.unixMenuSave(NULL)
	unlink(.unixMenuFile())
    return(invisible(NULL))
}

.unixMenuAdd <- function (menuname, itemname = NULL, action = "none") {
#    ## I just need to create (recursively) the directories
#    dir.create(file.path(.unixMenuFolder(), menuname),
#		showWarnings = FALSE, recursive = TRUE)

	## Add this menu to our Rmenu object
	mnu <- .Rmenu()
	items <- strsplit(as.character(menuname), "/", fixed = TRUE)[[1]]
	## allow for a maximum of 5 sublevels (should be largely enough!)
	l <- length(items)
	if (l == 1) {
		if (!is.null(mnu[[items[1]]])) {
			## If this is not a list, we got an error
			if (!is.list(mnu[[items[1]]]))
				stop(menuname, " is already defined and is not a menu")
		} else { # Create it
			mnu[[items[1]]] <- list()
		}
		## Do we create an menu item there too?
		if (!is.null(itemname))
			mnu[[items[1]]][[itemname]] <- action
	} else if (l == 2) {
		if (!is.null(mnu[[items[1]]][[items[2]]])) {
			## If this is not a list, we got an error
			if (!is.list(mnu[[items[1]]][[items[2]]]))
				stop(menuname, " is already defined and is not a menu")
		} else { # Create it
			mnu[[items[1]]][[items[2]]] <- list()
		}
		## Do we create an menu item there too?
		if (!is.null(itemname))
			mnu[[items[1]]][[items[2]]][[itemname]] <- action
	} else if (l == 3) {
				if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]])) {
			## If this is not a list, we got an error
			if (!is.list(mnu[[items[1]]][[items[2]]][[items[3]]]))
				stop(menuname, " is already defined and is not a menu")
		} else { # Create it
			mnu[[items[1]]][[items[2]]][[items[3]]] <- list()
		}
		## Do we create an menu item there too?
		if (!is.null(itemname))
			mnu[[items[1]]][[items[2]]][[items[3]]][[itemname]] <- action
	} else if (l == 4) {
		if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]])) {
			## If this is not a list, we got an error
			if (!is.list(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]]))
				stop(menuname, " is already defined and is not a menu")
		} else { # Create it
			mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]] <- list()
		}
		## Do we create an menu item there too?
		if (!is.null(itemname))
			mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[itemname]] <- action
	} else if (l == 5) {
		if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]])) {
			## If this is not a list, we got an error
			if (!is.list(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]]))
				stop(menuname, " is already defined and is not a menu")
		} else { # Create it
			mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]] <- list()
		}
		## Do we create an menu item there too?
		if (!is.null(itemname))
			mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]][[itemname]] <- action
	} else if (l > 5) {
		stop("You cannot use more than 5 menu levels")
	}
	## Save these changes
	.unixMenuSave(mnu)
	return(invisible(NULL))
}

.unixMenuAddItem <- function (menuname, itemname, action) {
	return(.unixMenuAdd(menuname, itemname, action))
#    ## Make sure that the dir is created
#    .unixMenuAdd(menuname)
#    ## Add an executable file in it with 'itemname' name
#    ## and containing: xvkbd -text "action\r" except if action is "none"
#    cmdFile <- file.path(.unixMenuFolder(), menuname, itemname)
#	if (action == "none") {
#		cat("\n", file = cmdFile)
#    } else {
#		## Make sure to quote "
#		action <- gsub('"', '\\\\"', action)
#		## Also replace \n, \r and \t (and wait 200ms between lines)
#		action <- gsub('\n', '\\\\r\\\\D2', action)
#		action <- gsub('\r', '\\\\r\\\\D2', action)
#		action <- gsub('\t', '    ', action)
#		cat("xvkbd -text \"", action, "\\r\"\n", sep = "", file = cmdFile)
#    }
#    ## Make this file executable
#    Sys.chmod(cmdFile, mode = "755")
#    return(invisible(NULL))
}

.unixMenuDel <- function (menuname) {
	mnu <- .Rmenu()
	items <- strsplit(as.character(menuname), "/", fixed = TRUE)[[1]]
	## Allow for a maximum of 5 sublevels (should be largely enough!)
	l <- length(items)
	if (l == 1 && !is.null(mnu[[items[1]]])) {
		mnu[[items[1]]] <- NULL
	} else if (l == 2 && !is.null(mnu[[items[1]]][[items[2]]])) {
		mnu[[items[1]]][[items[2]]] <- NULL
	} else if (l == 3 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]] <- NULL
	} else if (l == 4 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]] <- NULL
	} else if (l == 5 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]] <- NULL
	} else return(invisible(NULL))
	## Save these changes
	.unixMenuSave(mnu)
	return(invisible(NULL))	
		
#    ## Unlink does not like ~ => change working dir first
#    odir <- getwd()
#    on.exit(setwd(odir))
#    setwd(.unixMenuFolder())
#    unlink(menuname, recursive = TRUE)
#    return(invisible(NULL))
}

.unixMenuDelItem <- function (menuname, itemname) {
	mnu <- .Rmenu()
	items <- strsplit(as.character(menuname), "/", fixed = TRUE)[[1]]
	## Allow for a maximum of 5 sublevels (should be largely enough!)
	l <- length(items)
	if (l == 1 && !is.null(mnu[[items[1]]][[itemname]])) {
		mnu[[items[1]]][[itemname]] <- NULL
	} else if (l == 2 && !is.null(mnu[[items[1]]][[items[2]]][[itemname]])) {
		mnu[[items[1]]][[items[2]]][[itemname]] <- NULL
	} else if (l == 3 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[itemname]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]][[itemname]] <- NULL
	} else if (l == 4 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[itemname]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[itemname]] <- NULL
	} else if (l == 5 && !is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]][[itemname]])) {
		mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]][[itemname]] <- NULL
	} else return(invisible(NULL))
	## Save these changes
	.unixMenuSave(mnu)
	return(invisible(NULL))	
	
#    ## Unlink does not like ~ => change working dir first
#    path <- file.path(.unixMenuFolder(), menuname)
#    if (file.exists(path) && file.info(path)$isdir) {
#		odir <- getwd()
#		on.exit(setwd(odir))
#		setwd(path)
#		unlink(itemname)
#    }
#    return(invisible(NULL))    
}

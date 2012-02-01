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

.ctxMenuFileInit <- function ()
{
		res <- switch(Sys.info()["sysname"],
		Windows = NULL,
		Darwin = NULL, # TODO: should we have a default menu?
		.unixCtxMenuFileInit()
	)
	return(invisible(res))
}

.checkMenuName <- function (menuname)
{
	## Make sure menuname is correct...
	menuname <- as.character(menuname)
	if (length(menuname) != 1)
		stop("'menuname' must be a single character string")
	
	## $ConsoleMain/<menu> is equivalent, and thus, transformed into <menu>
	menuname <- sub("^\\$ConsoleMain/", "", menuname)
	
	if (menuname == "")
		stop("You cannot use an empty menuname")
	## Do not accept $ConsoleMain, $ConsolePopup, $Graph<n>Main,
	## or $Graph<n>Popup alone: need a / after the name of a special menu
	if (grepl("^\\$Console(Main|Popup)", menuname) &&
		!grepl("^\\$Console(Main|Popup)/.+", menuname))
		stop("You must define a submenu after the name of a special menu")
	if (grepl("^\\$Graph[0-9]+(Main|Popup)", menuname) &&
		!grepl("^\\$Graph[0-9]+(Main|Popup)/.+", menuname))
		stop("You must define a submenu after the name of a special menu")
	## Return the (possibly arranged) menuname
	return(menuname)
}

menuNames <- function ()
{
	res <- switch(Sys.info()["sysname"],
		Windows = winMenuNames(),
		Darwin = .macMenuNames(),
		.unixMenuNames()
	)
	return(res)
}

menuItems <- function (menuname)
{
	menuname <- .checkMenuName(menuname)
	
	res <- switch(Sys.info()["sysname"],
		Windows = winMenuItems(menuname),
		Darwin = .macMenuItems(menuname),
		.unixMenuItems(menuname)
	)
	return(res)
}

menuAdd <- function (menuname)
{
	menuname <- .checkMenuName(menuname)
	
	res <- switch(Sys.info()["sysname"],
		Windows = winMenuAdd(menuname),
		Darwin = .macMenuAdd(menuname),
		.unixMenuAdd(menuname)
	)
	return(invisible(res))
}

menuAddItem <- function (menuname, itemname, action)
{
	menuname <- .checkMenuName(menuname)
	
	res <- switch(Sys.info()["sysname"],
		Windows = .winMenuAddItem(menuname, itemname, action),
		Darwin = .macMenuAddItem(menuname, itemname, action),
		.unixMenuAddItem(menuname, itemname, action)
	)
	return(invisible(res))
}

menuDel <- function (menuname)
{
	menuname <- .checkMenuName(menuname)
	
	res <- switch(Sys.info()["sysname"],
		Windows = try(winMenuDel(menuname), silent = TRUE),
		Darwin = .macMenuDel(menuname),
		.unixMenuDel(menuname)
	)
	return(invisible(res))
}

menuDelItem <- function (menuname, itemname)
{
	menuname <- .checkMenuName(menuname)
	
	res <- switch(Sys.info()["sysname"],
		Windows = try(winMenuDelItem(menuname, itemname), silent = TRUE),
		Darwin = .macMenuDelItem(menuname, itemname),
		.unixMenuDelItem(menuname, itemname)
	)
	return(invisible(res))
}


## Windows version and standard winMenuXXX
## TODO: fallback system for Rterm???
.winMenuAddItem <- function (menuname, itemname, action)
{
	## As in R 2.14.1, the original winMenuAddItem() does things I don't like
	## much when usin 'enable' or 'disable' for action, on a non existing menu:
	## it creates it with the action being 'enable' or 'disable'... I suppose
	## if is a feature, but I want a different behaviour here: to ignore such
	## a command applied to a non-existing menu item!
	if (action %in% c("enable", "disable")) {
		menus <- winMenuItems(menuname)
		if (!is.null(menus) && itemname %in% names(menus)) {
			## The menu exists... enable or disable it!
			return(winMenuAddItem(menuname, itemname, action))
		} else return(invisible(NULL))
	} else return(winMenuAddItem(menuname, itemname, action))
}

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

.macMenuNames <- function ()
{
	stop("Not implemented yet!")
}

.macMenuItems <- function (menuname)
{
	stop("Not implemented yet!")
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
    ## TODO: manage 'enable' and 'disable'!!!
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

.unixCtxMenuFile <- function ()
{
	## Get the name of the file that contains the R context menu
	return(file.path(.unixMenuFolder(), paste(Sys.getenv("WINDOWID"),
		"CtxMenu.txt", sep = "")))
}

.unixCtxMenuFileInit <- function ()
{
	## Initialize the R context menu file with default items
	fil <- .unixCtxMenuFile()
	## Get the default R context menu and start from there
	def <- getOption("RCtxMenuFile",
		default = file.path("~", ".ctxmenu", "RCtxMenu.txt"))
	if (file.exists(def)) {
		file.copy(def, fil, overwrite = TRUE)
	} else file.copy(system.file("gui", "RCtxMenu.txt", package = "svDialogs"),
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
	ctxfil <- .unixCtxMenuFile()
	if (is.null(mnu)) {
		## Clear the file
		unlink(fil)
	} else {
		## Populate the file with the content of the Rmenu object
		makeMenu <- function (lst, indent = 0, file = fil, ctxfile = ctxfil) {
			l <- length(lst)
			if (l < 1) return()
			nms <- names(lst)
			for (i in 1:l) {
				item <- nms[i]
				if (is.list(lst[[i]])) {
					## Special case for '$ConsolePopup'
					if (item == "$ConsolePopup" && !is.null(ctxfile)) {
						makeMenu(lst[[i]], indent = 0, file = ctxfile, ctxfile = NULL)
					} else {
						## Create a new menu
						cat("\n", rep("\t", indent), "submenu=", item, "\n",
							sep = "", file = file, append = TRUE)
						makeMenu(lst[[i]], indent = indent + 1, file = file, ctxfile = NULL)
					}
				} else {
					## Is this a separator?
					if (grepl("^-",  item)) {
						cat("\n", rep("\t", indent), "separator\n",
							sep = "", file = file, append = TRUE)
					} else { # Add an item in current menu
						ind <- rep("\t", indent)
						## Rework commands using xvkbd -text "cmd\r"
						cmd <- as.character(lst[[i]])[1]
						if (cmd == "none" || !is.null(attr(lst[[i]], "state"))) {
							cmd <- "NULL" # This is the "no cmd" or "disabled" for ctxmenu
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
		.unixCtxMenuFileInit()
		## Add custom menus to it...
		cat("\nseparator # Here starts the custom R menus\n\n",
			file = fil, append = TRUE)
		cat("\nseparator # Here starts the custom R context menus\n\n",
			file = ctxfil, append = TRUE)
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
	unlink(.unixCtxMenuFile())
    return(invisible(NULL))
}

.unixMenuNames <- function (mnu = .Rmenu(), parent = character(0))
{
	if (!length(mnu)) return(character(0))
	## List all custom menu and (sub)menu
	## Iteratively traverse the list and enumerate all sublists (= submenus)
	items <- names(mnu)
	submnus <- character(0)
	for (item in items)
		if (is.list(mnu[[item]]))
			submnus <- c(submnus, paste(parent, item, sep = ""),
				.unixMenuNames(mnu[[item]],
					parent = paste(parent, item, "/", sep = "")))
	names(submnus) <- NULL
	## Eliminate $ConsolePopup, $Graph<n>Main & $Graph<n>Popup
	submnus <- submnus[submnus != "$ConsolePopup"]
	isGraphMenu <- grepl("^\\$Graph[0-9]+(Main|Popup)$", submnus)
	submnus <- submnus[!isGraphMenu]
	return(submnus)
}

.unixMenuItems <- function (menuname)
{
	## List all menu items in a given (sub)menu
	mnu <- .Rmenu()
	items <- strsplit(as.character(menuname), "/", fixed = TRUE)[[1]]
	## Traverse the menu hierarchy
	for (i in items) {
		mnu <- mnu[[i]]
		if (is.null(mnu) || !is.list(mnu))
			stop("unable to retrieve items for ", menuname,
				" (menu does not exist)")
	}
	if (length(mnu) == 0) return(character(0))
	## Set all submenu items to NULL
	for (i in 1:length(mnu))
		if (is.list(mnu[[i]])) mnu[[i]] <- NULL
	if (length(mnu) == 0) return(character(0)) else return(unlist(mnu))
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
	if (action %in% c("enable", "disable")) {
		## Enable or disable an existing menu item
		if (action == "enable") action <- NULL # To eliminate the attribute
		mnu <- .Rmenu()
		items <- strsplit(as.character(menuname), "/", fixed = TRUE)[[1]]
		## allow for a maximum of 5 sublevels (should be largely enough!)
		l <- length(items)
		if (l == 1) {
			if (!is.null(mnu[[items[1]]][[itemname]]))
				attr(mnu[[items[1]]][[itemname]], "state") <- action
		} else if (l == 2) {
			if (!is.null(mnu[[items[1]]][[items[2]]][[itemname]]))
				attr(mnu[[items[1]]][[items[2]]][[itemname]], "state") <- action
		} else if (l == 3) {
			if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[itemname]]))
				attr(mnu[[items[1]]][[items[2]]][[items[3]]][[itemname]], "state") <- action
		} else if (l == 4) {
			if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[itemname]]))
				attr(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[itemname]], "state") <- action
		} else if (l == 5) {
			if (!is.null(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]][[itemname]]))
				attr(mnu[[items[1]]][[items[2]]][[items[3]]][[items[4]]][[items[5]]][[itemname]], "state") <- action
		} else if (l > 5) {
			stop("You cannot use more than 5 menu levels")
		}
		## Save these changes
		.unixMenuSave(mnu)
		return(invisible(NULL))
	} else return(.unixMenuAdd(menuname, itemname, action))
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

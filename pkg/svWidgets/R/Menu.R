"print.guiMenu" <-
function (x, ...)
{
	cat("A SciViews GUI menu object:", "\n")
	print(unclass(x))
	return(invisible(x))
}

"MenuAdd" <-
function (menu, ...)
{
	res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuAdd(menu),
		tkMenu = tkMenuAdd(menu, ...))
	return(invisible(res))
}

"MenuAddItem" <-
function (menu, item, action, image = "", accel = "", options = "")
{
	res <- switch(MenuType(menu),
		winMenu = if (isRgui()) {
			winMenuAddItem(menu, item, action);
			if (options == 'state = "disable"')
				winMenuStateItem(menu, item, FALSE) },
		tkMenu = tkMenuAddItem(menu, item, action, image, accel, options))
	return(invisible(res))
}

"MenuDel" <-
function (menu)
{
    res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuDel(menu),
		tkMenu = tkMenuDel(menu))
	return(invisible(res))
}

"MenuDelItem" <-
function (menu, item)
{
    res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuDelItem(menu, item),
		tkMenu = tkMenuDelItem(menu, item))
	return(invisible(res))
}

"MenuNames" <-
function ()
{
	res <- character(0)
	if (isRgui()) res <- winMenuNames()
	# Eliminate menu names not correctly created (not starting with $...)
	if (length(res) > 0) res <- res[regexpr("^[$]", res) > 0]
	# retrieve menu names from tk menus as well
	res <- c(res, names(getTemp(".guiMenus")))
	# eliminate toplevel entries
    if (length(res) > 0) res <- res[regexpr("/", res) > 0]
	return(res)
}

"MenuItems" <-
function (menu)
{
    res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuItems(menu),
		tkMenu = tkMenuItems(menu))
	return(res)
}

"MenuType" <-
function (menu, warn = TRUE)
{
	# Given a menu, return its type ("winMenu", "tkMenu", NA)
	if (regexpr("^[$]Console(Main|Popup)/", menu) > 0) return("winMenu") else
	if (regexpr("^[$]Graph[0-9]+(Main|Popup)/", menu) > 0) return("winMenu") else
	if (regexpr("^[$]Tk[.].+/", menu) > 0) return("tkMenu") else {
        if (warn) warning("Unrecognized menu type for ", menu)
		return(NA)
	}
}

"MenuChangeItem" <-
function (menu, item, action = "", options = "")
{
	# Change action or options for menu entries
	res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuChangeItem(menu, item, action, options),
		tkMenu = tkMenuChangeItem(menu, item, action, options))
	return(invisible(res))
}

"MenuStateItem" <-
function (menu, item, active = TRUE)
{
	# Activate/inactivate menu entries
	res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuStateItem(menu, item, active),
		tkMenu = tkMenuStateItem(menu, item, active))
	return(invisible(res))
}

"MenuInvoke" <-
function (menu, item)
{
	# Trigger a menu entry by code
	res <- switch(MenuType(menu),
		winMenu = if (isRgui()) winMenuInvoke(menu, item),
		tkMenu = tkMenuInvoke(menu, item))
	return(invisible(res))
}

"MenuRead" <-
function (file = "Menus.txt")
{
	# Read a menu from a file
    M <- scan(file, character(0), sep = "\n", comment.char = "#", quiet = TRUE)
	# Split the lines into item, command, options
    M <- strsplit(M, "~~")
	# Strip leading and trailing spaces/tabs (used to align items in the file)
    M <- lapply(M, function(x) sub("[ \t]+$", "", sub("^[ \t]+", "", x)))
	# Move line after line and replace '|' by values
    N <- length(M)
	# Must have at least two entries
	if (N < 2) return(invisible())
	# First entry must be a toplevel, thus, it must start with '$'
	if (regexpr("^[$]", M[[1]][1]) < 0)
		stop("first entry is not a toplevel menu!")
    menuLevels <- M[[1]][1]
	# Initialize a data frame to contain decrypted info
	dat <- rep("", N)
	L <- data.frame(menu = I(dat), item = I(dat), image = I(dat),
		accel = I(dat), action = I(dat), options = I(dat))
	Litem <- data.frame(menu = I(menuLevels), item = I(""), image = I(""),
		accel = I(""), action = I("[top]"), options = I(""))
	L[1, ] <- Litem
	for (i in 2:N) {
		entry <- M[[i]][1]
		# Split on '|'
		split <- strsplit(entry, "[|]")[[1]]
		# Combine menuLevels & split
		last <- length(split)
		menuLevels[last] <- split[last]
		menuLevels <- menuLevels[1:last]
		# Recombine menuLevels for getting recalculated entry
		entry <- paste(menuLevels, collapse = "/")
		# Is this just a menu, or a menu/item?
		lastentry <- basename(entry)
		if (regexpr("^[$]", lastentry) > 0) { # This is a menu
			# Remove '$' before menu entries
			menu <- gsub("/[$]", "/", entry)
			item <- ""      	# No item
			image <- ""     	# No image
			accel <- ""     	# No accel
			action <- if (last == 1) "[top]" else "[menu]"
			options <- ""       # No options (currently)
		} else {    # This is an entry
			# menu = entry minus last item (remove '$' before menu entries)
			menu <- gsub("/[$]", "/", dirname(entry))
			# Decrypt lastentry to get image, item & accel ([image]item\taccel)
			lastentry <- strsplit(lastentry, "\t")[[1]]
			item <- sub("^[[][a-zA-Z0-9 ._-]+[]]", "", lastentry[1])
			if (item == lastentry[1]) image <- "" else {
				image <- sub("^[[]([a-zA-Z0-9 ._-]+)[]].+$", "\\1", lastentry[1])
				# Since these are Tk images resources, I have to prefix '$Tk.'
				image <- paste("$Tk.", image, sep = "")
			}
			accel <- lastentry[2]
			if (is.na(accel)) accel <- ""
			action <- M[[i]][2]
			if (is.na(action)) action <- ""
			options <- M[[i]][3]
            if (is.na(options)) options <- ""
		}
        Litem <- data.frame(menu = I(menu), item = I(item), image = I(image),
			accel = I(accel), action = I(action), options = I(options))
		# add it to the data.frame
		L[i, ] <- Litem
	}
	# The [top] entries are not needed
	L <- L[L$action != "[top]", ]

	# Execute this line-by-line to create the various menus
	N <- nrow(L)
	for (i in 1:N) {
		action <- L$action[i]
		if (action == "[menu]") { # Create a menu
			MenuAdd(menu = L$menu[i])
		} else {    # Create a menu entry
			MenuAddItem(menu = L$menu[i], item = L$item[i], action = L$action[i],
				image = L$image[i], accel = L$accel[i], options = L$options[i])
		}
	}

	# Return L invisibly
	return(invisible(L))
}

"MenuReadPackage" <-
function (package, subdir = "gui", file = "Menus.txt")
{
	# Create menus using a menu definition file located in a R package
	dir <- system.file(subdir, package = package)
	# Check that the dir exists
	if (!file.exists(dir) || !file.info(dir)$isdir)
		stop("'", dir, "' does not exist, or is not a directory!")
	# Check that the file exists
	File <- file.path(dir, file)
	if (!file.exists(File))
		stop("'", file, "' not found in '", dir, "'!")
	# Read the menu file
	res <- MenuRead(File)
	return(invisible(res))
}
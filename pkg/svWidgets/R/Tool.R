print.guiTool <- function (x, ...)
{
	cat("A SciViews GUI tool object:", "\n")
	print(unclass(x))
	return(invisible(x))
}

ToolAdd <- function (toolbar, side = "top")
{
	res <- switch(ToolType(toolbar),
		tkTool = tkToolAdd(toolbar = toolbar, side = side))
	return(invisible(res))
}

ToolAddItem <- function (toolbar, item, action, image = "", options = "")
{
	res <- switch(ToolType(toolbar),
		tkTool = tkToolAddItem(toolbar = toolbar, item = item, action = action,
			image = image, options = options))
	return(invisible(res))
}

ToolDel <- function (toolbar)
{
    res <- switch(ToolType(toolbar),
		tkTool = tkToolDel(toolbar = toolbar))
	return(invisible(res))
}

ToolDelItem <- function (toolbar, item)
{
    res <- switch(ToolType(toolbar),
		tkTool = tkToolDelItem(toolbar = toolbar, item = item))
	return(invisible(res))
}

ToolNames <- function ()
{
	res <- character(0)
	## Retrieve toolbar names from tk toolbars
	res <- c(res, names(getTemp(".guiTools")))
	## Eliminate toplevel entries
    if (length(res) > 0) res <- res[regexpr("/", res) > 0]
	return(res)
}

ToolItems <- function (toolbar)
{
    res <- switch(ToolType(toolbar),
		tkTool = tkToolItems(toolbar = toolbar))
	return(res)
}

ToolType <- function (toolbar, warn = TRUE)
{
	## Given a toolbar, return its type ("tkTool", NA)
	if (regexpr("^[$]Tk[.].+/", toolbar) > 0) return("tkTool") else {
        if (warn) warning("Unrecognized toolbar type for ", toolbar)
		return(NA)
	}
}

ToolChangeItem <- function (toolbar, item, action = "", options = "")
{
	## Change action or options for toolbar entries
	res <- switch(ToolType(toolbar),
		tkTool = tkToolChangeItem(toolbar, item, action, options))
	return(invisible(res))
}

ToolStateItem <- function (toolbar, item, active = TRUE)
{
	## Activate/inactivate toolbar entries
	res <- switch(ToolType(toolbar),
		tkTool = tkToolStateItem(toolbar, item, active))
	return(invisible(res))
}

ToolInvoke <- function (toolbar, item)
{
	## Invoke a toolbutton
	res <- switch(ToolType(toolbar),
		tkTool = tkToolInvoke(toolbar, item))
	return(invisible(res))
}

ToolRead <- function (file = "Tools.txt")
{
	## Read toolbars from a file
    T <- scan(file, character(0), sep = "\n", comment.char = "#", quiet = TRUE)
	## Split the lines into item, command, options
    T <- strsplit(T, "~~")
	## Strip leading and trailing spaces/tabs (used to align items in the file)
    T <- lapply(T, function(x) sub("[ \t]+$", "", sub("^[ \t]+", "", x)))
	## Move line after line and replace '|' by values
    N <- length(T)
	## Must have at least two entries
	if (N < 2) return(invisible())
	## First entry must be a toplevel, thus, it must start with '$'
	if (regexpr("^[$]", T[[1]][1]) < 0)
		stop("first entry is not a toolbar!")
    toolLevels <- T[[1]][1]
	## Initialize a data frame to contain decrypted info
	dat <- rep("", N)
	L <- data.frame(tool = I(dat), item = I(dat), image = I(dat),
		action = I(dat), options = I(dat))
	Litem <- data.frame(tool = I(toolLevels), item = I(""), image = I(""),
		action = I("[toolbar]"), options = I(""))
	L[1, ] <- Litem
	for (i in 2:N) {
		entry <- T[[i]][1]
		## Split on '|'
		split <- strsplit(entry, "[|]")[[1]]
		## Combine toolLevels & split
		last <- length(split)
		toolLevels[last] <- split[last]
		toolLevels <- toolLevels[1:last]
		## Recombine toolLevels for getting recalculated entry
		entry <- paste(toolLevels, collapse = "/")
		## Is this just a tool button, or a menu tool button/menu item?
		lastentry <- basename(entry)
		if (regexpr("^[$]", lastentry) > 0) { # This is a tool button
			## Remove '$' before tool button entries
			tool <- gsub("/[$]", "/", entry)
			item <- ""      	# No item
			image <- ""     	# No image
			action <- if (last == 1) "[toolbar]" else "[tool]"
			options <- ""       # No options (currently)
		} else {  # This is an menu entry in a tool button menu
			## tool = entry minus last item (remove '$' before tool entries)
			tool <- gsub("/[$]", "/", dirname(entry))
			## Decrypt lastentry to get image & item ([image]item)
   			item <- sub("^[[][a-zA-Z0-9 ._-]+[]]", "", lastentry)
			if (item == lastentry) image <- "" else {
				image <- sub("^[[]([a-zA-Z0-9 ._-]+)[]].+$", "\\1", lastentry)
				## Since these are Tk images resources, I have to prefix '$Tk.'
				image <- paste("$Tk.", image, sep = "")
			}
   			action <- T[[i]][2]
			if (is.na(action)) action <- ""
			options <- T[[i]][3]
            if (is.na(options)) options <- ""
		}
        Litem <- data.frame(tool = I(tool), item = I(item), image = I(image),
			action = I(action), options = I(options))
		## Add it to the data.frame
		L[i, ] <- Litem
	}
	
	## The [toolbar] entries are not needed
	L <- subset( L, action != "[toolbar]" )

	## Execute this line-by-line to create the various tools 
	N <- nrow(L)
	for (i in 1:N) {
		action <- L$action[i]
		if (action == "[tool]") { 	# Create a toolbar
            ToolAdd(toolbar = L$tool[i])
#		} else if (action == "[tool]") {  # Create a tool button
#			### TODO: determine which type of tool button it is!
#			ToolAddItem(toolbar = L$menu[i])
#		} else {    # Create a menu entry for a menu tool button
#			MenuAddItem(menu = L$tool[i], item = L$item[i], action = L$action[i],
#				image = L$image[i], options = L$options[i])
#		}
		} else {  # Create a tool in the toolbar
            ToolAddItem(toolbar = L$tool[i], item = L$item[i],
				action = L$action[i], image = L$image[i],
				options = L$options[i])
		}
	}

	return(invisible(L))
}

ToolReadPackage <- function (package, subdir = "gui", file = "Tools.txt")
{
	## Create toolbars using a toolbar definition file located in a R package
	dir <- system.file(subdir, package = package)
	## Check that the dir exists
	if (!file.exists(dir) || !file.info(dir)$isdir)
		stop("'", dir, "' does not exist, or is not a directory!")
	## Check that the file exists
	File <- file.path(dir, file)
	if (!file.exists(File))
		stop("'", file, "' not found in '", dir, "'!")
	## Read the toolbar file
	res <- ToolRead(File)
	return(invisible(res))
}

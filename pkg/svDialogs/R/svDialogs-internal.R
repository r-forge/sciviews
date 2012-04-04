.onLoad <- function (lib, pkg)
{
	if (.tmpfilesAllowed()) {
		## Clear menus
		.menuClear()
		## ... and create the default one
		.menuFileInit()
		.ctxMenuFileInit()	
	}
}

.onUnload <- function (libpath)
{
	## Clear menus
	if (interactive()) try(.menuClear())
}

.Last.lib <- function (libpath)
{
	## Clear menus
	if (interactive()) try(.menuClear())
}

.packageName <- "svDialogs"

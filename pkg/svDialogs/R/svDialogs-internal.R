.onLoad <- function (lib, pkg)
{
	## Clear menus
	.menuClear()
	## ... and create the default one
	.menuFileInit()
	.ctxMenuFileInit()
}

.onUnload <- function (libpath)
{
	## Clear menus again
	.menuClear()
}

.packageName <- "svDialogs"

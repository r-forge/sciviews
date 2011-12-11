.onLoad <- function (lib, pkg)
{
	## Clear menus
	.menuClear()
}

.onUnload <- function (libpath)
{
	## Clear menus again
	.menuClear()
}

.packageName <- "svDialogs"

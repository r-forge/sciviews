print.guiWin <- function (x, ...)
{
	cat("A SciViews GUI window object:", "\n")
	print(unclass(x))
	return(invisible(x))
}

WinAdd <- function (name = "win1", type = "tkWin", parent = .TkRoot,
title = NULL, pos = NULL, bind.delete = TRUE, ...)
{
	## Add a window. This mechanism should be able to use different kinds of
	## graphical widgets, but currently, only Tcl/Tk is supported.
	res <- switch(type,
		tkWin = tkWinAdd(name = name, parent = parent, title = title, pos = pos,
			bind.delete = bind.delete, ...),
		stop("Only type = \"tkWin\" is currently supported"))
	return(invisible(res))
}

WinDel <- function (window)
{
	## Process depends on the kind of window to delete
	## Currently, only Tk windows are supported
	if (inherits(WinGet(window), "tkguiWin")) {
		return(invisible(tkWinDel(window)))
	} else stop("Unsupported window type")
}

WinGet <- function (window)
{
	## Retrieve a "guiWin" object from .guiWins, given its name
	return(getTemp(".guiWins")[[window]])
}

WinNames <- function ()
{
	## List all recorded windows in .guiWins
### TODO: if Rgui, list also console, graph, editors and pagers!
	res <- names(getTemp(".guiWins"))
	if (is.null(res)) res <- character(0)
	return(res)
}

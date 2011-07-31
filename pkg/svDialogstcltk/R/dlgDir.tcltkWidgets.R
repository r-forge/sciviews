## A Tcl/Tk version of the directory selection dialog box
dlgDir.tcltkWidgets <- function (default = getwd(), message, ..., gui = .GUI)
{
    gui$setUI(widgets = "tcltkWidgets")
	## TODO: we don't display multiline message here! => what to do?
    res <- tclvalue(tkchooseDirectory(initialdir = gui$args$default,
		mustexist = FALSE, title = gui$args$message))
    if (res == "") res <- character(0)  # tkchooseDirectory returns "" if cancelled
    gui$setUI(res = res, status = NULL)
	return(invisible(gui))
}

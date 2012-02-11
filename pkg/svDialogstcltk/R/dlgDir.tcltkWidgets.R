## A Tcl/Tk version of the directory selection dialog box
dlgDir.tcltkWidgets <- function (default = getwd(), title, ..., gui = .GUI)
{
    gui$setUI(widgets = "tcltkWidgets")
	## TODO: we don't display multiline title here! => what to do?
    res <- tclvalue(tkchooseDirectory(initialdir = gui$args$default,
		mustexist = FALSE, title = gui$args$title))
    if (res == "") res <- character(0)  # tkchooseDirectory returns "" if cancelled
    gui$setUI(res = res, status = NULL)
	return(invisible(gui))
}

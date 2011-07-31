.onLoad <- function (lib, pkg)
{
	## Add a dispatch to 'tcltkWidgets' in the .GUI object
	guiWidgets(.GUI) <- "tcltkWidgets"
}

#.onUnload <- function (libpath)
#{
#	## We do nothing, because other packages may also use the 'tcltkWidgets' dispatch
#}

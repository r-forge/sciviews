.onLoad <- function (lib, pkg)
{
	#serve <- getOption("ko.serve")
	#if (!is.null(serve)) {
	#	startSocketServer(port = as.integer(serve)[1])
		guiInstall()
	#}
}

.onUnload <- function (libpath)
{
	#serve <- getOption("ko.serve")
	#if (!is.null(serve) && "package:svSocket" %in% search())
	#	stopSocketServer(port = as.integer(serve)[1])
	guiUninstall()
}

.packageName <- "svGUI"

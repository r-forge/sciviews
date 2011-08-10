.onLoad <- function (lib, pkg)
{
	#serve <- getOption("ko.serve")
	#if (!is.null(serve)) {
	#	startSocketServer(port = as.integer(serve)[1])
	## Create our SciViews task callback manager
	assignTemp(".svTaskCallbackManager", svTaskCallbackManager())
	koInstall()
	
	#}
}

.onUnload <- function (libpath)
{
	#serve <- getOption("ko.serve")
	#if (!is.null(serve) && "package:svSocket" %in% search())
	#	stopSocketServer(port = as.integer(serve)[1])
	koUninstall()
	## Remove the SciViews tesk callback manager
	removeTaskCallback("SV-taskCallbackManager")
	rmTemp(".svTaskCallbackManager")
}

.packageName <- "svKomodo"

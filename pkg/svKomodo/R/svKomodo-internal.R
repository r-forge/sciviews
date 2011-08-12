.onLoad <- function (lib, pkg)
{
	#serve <- getOption("ko.serve")
	#if (!is.null(serve)) {
	#	startSocketServer(port = as.integer(serve)[1])
	## Create our SciViews task callback manager
	
	## PhG: inactivated for now, because it makes problems in R!!!
	#assignTemp(".svTaskCallbackManager", svTaskCallbackManager())
	koInstall()
	
	## Temporary change of a few R options that make problem with SciViews
	## Do not use fancy quotes
	assignTemp(".useFancyQuotes", getOption("useFancyQuotes"))
	options(useFancyQuotes = FALSE)
	## Limit output to 999 items
	assignTemp(".max.print", getOption("max.print"))
	options(max.print = 999)
	#}
}

.onUnload <- function (libpath)
{
	## Restore R options that preexisted
	try(options(useFancyQuotes = getTemp(".useFancyQuotes", TRUE)),
		silent = TRUE)
	try(options(max.print = getTemp(".max.print", 99999)),
		silent = TRUE)
	
	#serve <- getOption("ko.serve")
	#if (!is.null(serve) && "package:svSocket" %in% search())
	#	stopSocketServer(port = as.integer(serve)[1])
	koUninstall()
	## Remove the SciViews tesk callback manager
	try(removeTaskCallback("SV-taskCallbackManager"), silent = TRUE)
	try(rmTemp(".svTaskCallbackManager"), silent = TRUE)
}

.packageName <- "svKomodo"

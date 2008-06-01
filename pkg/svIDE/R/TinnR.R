# Specific functions for Tinn-R (adapted by J.-C. Faria from functions in svGUI
# made by Ph. Grosjean)
# Note: to avoid duplication in code, core process is now moved into objSearch()
# and objList() in the svMisc package

"trObjSearch" <-
function (path = NULL) {
	return(objSearch(path, compare = FALSE))
}

"trObjList" <-
function(id = "default", envir = .GlobalEnv, all.names = FALSE,
pattern = "", group = "", path = NULL) {
	oWidth <- getOption("width")
	options(width = 100)
	on.exit(options(width = oWidth))

	return(objList(id = id, envir = envir, all.names = all.names,
		pattern = pattern, group = group, path = path, compare = FALSE))
}

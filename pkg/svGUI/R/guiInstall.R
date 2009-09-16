"guiInstall" <-
function ()
{
	assignTemp(".guiCmd", function(command, ...) {
		command <- switch(command, ## TODO: define these commands
			load = "",
			source = "",
			save = "",
			import = "",
			export = "",
			report = "",
			setwd = "",
			"")
	})
	assignTemp(".guiObjBrowse", function(id, data) {
		koCmd('sv.objBrowse("<<<id>>>", "<<<dat>>>");', list(id = id, dat = data))
	})
	assignTemp(".guiObjInfo", function(id, data) {
		koCmd('sv.objInfo("<<<id>>>", "<<<dat>>>");', list(id = id, dat = data))
	})
	assignTemp(".guiObjMenu", function(id, data) {
		koCmd('sv.objMenu("<<<id>>>", "<<<dat>>>");', list(id = id, dat = data))
	})

	# Functions specific to Komodo as a GUI client
	assignTemp(".koCmd", function(command, ...) {
		# This mechanism avoids dependence on svGUI for packages that provide
		# functionalities that work with or without Komodo (like svUnit)
		# Instead of calling koCmd() directly, we look if .koCmd is defined
		# in tempenv and we run it.
		# This allows also redefining koCmd() without changing code in the
		# packages that depend on .koCmd()
		koCmd(command, ...)
	})

	# Register a TaskCallback to generate automatically informations for an object browser
	# Use  getTaskCallbackNames() to know if some tasks are registered
#	assignTemp(".guiObjCallback", function(...) {
#	    ob <- names(getTemp(".guiObjListCache", default = NULL))
#	    if (!is.null(ob)) for (i in 1:length(ob)) objBrowse(id = ob[i])
#		return(TRUE)   # Required to keep it in the TaskCallback list
#	})
	Callback <- getTemp(".guiObjCallbackId", default = NULL)
	if (is.null(Callback)) {
#	    n <- addTaskCallback(getTemp(".guiObjCallback"))
		n <- addTaskCallback(guiAutoRefresh)
	    if (!is.null(n)) assignTemp(".guiObjCallbackId", as.character(n))
	}
}

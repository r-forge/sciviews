"guiInstall" <-
function() {
	assignTemp(".guiCmd", function(command, ...) {
		switch(command,	### TODO: create these commands!
			load = "",
			source = "",
			save = "",
			import = "",
			export = "",
			report = "",
			setwd = "",
			""
		)
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

	# Register a TaskCallback to generate automatically informations for an object browser
	# Use  getTaskCallbackNames() to know if some tasks are registered
	assignTemp(".guiObjCallback", function(...) {
	    ob <- names(getTemp(".guiObjListCache", default = NULL))
	    if (!is.null(ob)) for (i in 1:length(ob)) objBrowse(id = ob[i])
		return(TRUE)   # Required to keep it in the TaskCallback list
	})
	Callback <- getTemp(".guiObjCallbackId", default = NULL)
	if (is.null(Callback)) {
	    n <- addTaskCallback(getTemp(".guiObjCallback"))
	    if (!is.null(n)) assignTemp(".guiObjCallbackId", as.character(n))
	}
}

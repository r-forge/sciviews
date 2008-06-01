"guiUninstall" <-
function() {
	# Eliminate .guiCmd
	rmTemp(".guiCmd")
	rmTemp(".guiObjBrowse")
	rmTemp(".guiObjInfo")
	rmTemp(".guiObjMenu")
	
	# Unregister the TaskCallback
	# Use getTaskCallbackNames() to know if some tasks are registered
	Callback.Id <- getTemp(".guiObjCallbackId", default = NULL)
	if (!is.null(Callback.Id)) {
	    if (removeTaskCallback(Callback.Id)) assignTemp(".guiObjCallbackId", NULL)
	}
}

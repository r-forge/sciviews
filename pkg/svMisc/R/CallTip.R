CallTip <- function (code, only.args = FALSE, location = FALSE)
{
	code <- attr(Complete(code, types = NA), "fguess")
	if (is.null(code) || !length(code) || code == "")
		return("")

	## Get the corresponding calltip
	ctip <- ""  # Default value, in case the function does not exist
	if (code != "") ctip <- Args(code, only.args = only.args)
	if (is.null(ctip)) return("")
	## Do we need to append an indication of where this function is located?
	if (location == TRUE) {
		## TODO: use getAnywhere() instead
 		pkg <- sub("^package:", "", find(code, mode = "function"))
	    if (length(pkg) > 0 && pkg != ".GlobalEnv")
			ctip <- paste(ctip, " [", pkg, "]", sep = "")
	}
	return(ctip)
}

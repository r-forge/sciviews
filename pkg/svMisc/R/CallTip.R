"CallTip" <-
function (code, only.args = FALSE, location = FALSE)
{
	# This is the old treatment!
	# Get a call tip, given a part of the code
	# Extract the last variable name, given it is either at the end,
	# or terminated by '('
	#code <- sub(" *\\($", "", code[1])
	#pos <- regexpr("[a-zA-Z0-9_\\.]+$", code)
	#code <- substring(code, pos)
	# Now, we use a more exhaustive search, using complete
	code <- attr(Complete(code, types = NA), "fguess")
	if (is.null(code) || !length(code) || code == "")
		return("")

	# Get the corresponding Call Tip
	ctip <- "" # Default value, in case the function does not exist
	if (code != "") ctip <- Args(code, only.args = only.args)
	if (is.null(ctip)) return("")
	# Do we need to append an indication of where this function is located?
	if (location == TRUE) {
		### TODO: use getAnywhere() instead
 		pkg <- sub("^package:", "", find(code, mode = "function"))
	    if (length(pkg) > 0 && pkg != ".GlobalEnv")
			ctip <- paste(ctip, " [", pkg, "]", sep = "")
	}
	return(ctip)
}

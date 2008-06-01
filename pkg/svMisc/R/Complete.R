"Complete" <-
function(code, givetype = FALSE, sep = "\t") {
	### TODO: implement 'givetype'!
	
	# Get a completion list, given a part of the code
	code <- paste(as.character(code), collapse = "\n")
	if (is.null(code) || length(code) == 0 || code == "") return("")
		
	# Use the internal win32consoleCompletion function in utils package
	res <- utils:::.win32consoleCompletion(code, nchar(code))
	
	# Is there a single addition?
	if (res$addition != "") {
		res <- paste(sep, gsub("=", " = ", res$addition), sep = "")
	} else if (res$comps != "") { # Is there a list of possible tokens?
		# Replace space by fieldsep
		if (sep != " ") res <- gsub(" ", sep, res$comps)
		res <- gsub("=", " = ", res)
	} else return("")
	# Do we have to return something to complete?
	if (regexpr(paste("\\", sep, sep = ""), res) == -1) {
		return("")
	} else {
		return(res)
	}	
}

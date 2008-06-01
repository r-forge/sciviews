"createCallTipFile" <-
function(file = "Rcalltips.txt", pos = 2:length(search()), field.sep = "=",
    only.args = FALSE, return.location = FALSE) {
	# Create a .txt file containing calltips for R functions.
	
	# Create the beginning of the file
	cat("", file = file) # Currently, needs nothing...
	
	# Get the list of keywords
	keys <- getKeywords(pos = pos)
	
	# For each keyword, write a line in the file with keyword=calltip
    for (i in 1:length(keys)) {
        ctip <- CallTip(keys[i], only.args = only.args)
        if (ctip != "") {
            if (return.location == TRUE) {
				# Get the package from where it is located and append it
				pkg <- sub("^package:", "", find(keys[i], mode = "function"))
				if (length(pkg) > 0 && pkg != ".GlobalEnv")
					pkg <- paste(" [", pkg, "]", sep = "") else pkg <- " []"
            } else pkg <- ""
            cat(keys[i], field.sep, ctip, pkg, "\n", sep = "", file = file,
				append = TRUE)
		}
    }
}

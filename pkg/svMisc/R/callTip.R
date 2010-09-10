CallTip <- function (code, only.args = FALSE, location = FALSE) {
	.Deprecated("callTip")
	return(callTip(code, only.args = only.args, location = location))
}

callTip <- function (code, only.args = FALSE, location = FALSE)
{
	code <- attr(completion(code, types = NA, describe = FALSE), "fguess")
	if (is.null(code) || !length(code) || code == "")
		return("")

	## Get the corresponding calltip
	ctip <- argsTip(code, only.args = only.args)
	if (is.null(ctip)) return("")
	## Do we need to append an indication of where this function is located?
	if (isTRUE(location)) {
 		where <- res <- eval(parse(text = paste("getAnywhere(", code, ")",
			sep = "")))$where[1]
		if (!is.na(where) && where != ".GlobalEnv")
			ctip <- paste(ctip, " [", sub("^package:", "", where), "]", sep = "")
	}
	return(ctip)
}

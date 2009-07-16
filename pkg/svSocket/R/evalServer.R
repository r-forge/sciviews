evalServer <- function (con, expr, send = NULL) {
	# Evaluate expr on the server, and return its value
	# expr may be quoted or not e.g. can pass a quoted "x=2" to send an assignment
	# send is optional. If supplied, expr must be a single object name (unquoted).
	# Then send is evaluated on the client and the result is assigned to that
	# object name on the server.
	x <- substitute(expr)
	if (!missing(send) && (!length(x) == 1 || mode(x) != "name"))
		stop("When send is supplied, expr must be an target variable name (unquoted) on the server to assign the result of the send expr to.")
	if (!is.character(x)) x <- deparse(x)
	# Flush the input stream just in case previous calls failed to clean up
	scan(con, "", quiet = TRUE)
	if (missing(send)) {
		writeLines(paste('.Last.value = try(eval(parse(text = "', x, '"))); dump(".Last.value", file = ""); cat("<<<endflag>>>")', sep = ""), con)
	} else {
		.Last.value <- send
		sendtxtcon <- textConnection("tmptxt", open = "w", local = TRUE)
		dump(".Last.value", sendtxtcon)
		on.exit(close(sendtxtcon))
		writeLines(paste(paste(tmptxt, collapse = ""), ';', x, ' = .Last.value; cat("<<<endflag>>>")', sep = ""), con)
	}
	# The explicit .Last.value is required to suppress the output of the value
	# of expression back to the client e.g. "[1] 2" being sent back
	# We use .Last.value as its a safe temporary variable to overwrite.
	# The evaluate and dump must be sent as a single string
	# using a single call to writeLines, to ensure multiple clients
	# do not get mixed up results.
	objdump <- ""
	while (regexpr("<<<endflag>>>", objdump) < 0)
		objdump <- paste(objdump, readLines(con), sep = "", collapse = "\n")
	objdump <- sub("<<<endflag>>>", "", objdump)
	if (!missing(send)) {
		if (!identical(objdump, "")) stop(objdump)
		return(TRUE)
	}
	# Source the content of objdump, locally in this frame
	objcon <- textConnection(objdump)
	on.exit(close(objcon))
	source(objcon, local = TRUE, echo = FALSE, verbose = FALSE)
	.Last.value
}

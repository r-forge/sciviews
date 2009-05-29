"Parse" <-
function (text)
{
	# Parse R instructions provided as a string and return the expression if it
	# is correct, or try-error if it is an incorrect code, or NA if the (last)
	# instruction is incomplete
    text <- paste(text, collapse = "\n")
    msgcon <- textConnection(text)
    expr <- try(parse(msgcon), silent = TRUE)
    close(msgcon)

    # Determine if this code is correctly parsed
	if (inherits(expr, "try-error")) {
		# Determine if it is incorrect code, or incomplete line!
		# Code is different before and after R 2.9.0
		if (compareRVersion("2.9.0") < 0) {
			toSearch <- paste("\n", length(strsplit(text, "\n")[[1]]) +
			    1, ":", sep = "")
		} else {
			toSearch <- paste(": ", length(strsplit(text, "\n")[[1]]) +
			    1, ":0:", sep = "")
		}
        if (length(grep(toSearch, expr)) == 1) return(NA) else return(expr)
    }
    # There is still a case of incomplete code not catch: incomplete strings
    dp <- deparse(expr)
    # Is it an incomplete string (like "my string)?
    if (regexpr("\\n\")$", dp) > 0 &&
        regexpr("\n[\"'][ \t\r\n\v\f]*($|#.*$)", text) < 0)
		return(NA)

    # Is it an incomplete variable name (like `name)?
    if (regexpr("\n`)$", dp) > 0  &&
        regexpr("\n`[ \t\r\n\v\f]*($|#.*$)", text) < 0)
		return(NA)

    # Everything is fine, just return parsed expression
    return(expr)
}

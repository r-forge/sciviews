`Parse` <- function (text)
{
	## Deprecated, in favor of parseText()
	.Deprecated("parseText")
	return(parseText(text))
}

`parseText` <- function (text) {
	## Parse R instructions provided as a string and return the expression if it
	## is correct, or a 'try-error' object if it is an incorrect code, or NA if
	## the (last) instruction is incomplete
  	res <- tryCatch(parse(text=text), error=identity)

	if(inherits(res, "error")) {

		# Check if this is incomplete code
		rxUEOI <- paste("<text>:\\d:\\d:", gettextf("unexpected %s",
			gettext("end of input", domain="R"), domain="R"))
		if(regexpr(rxUEOI, res$message) == 1) return(NA)

		res$message <- substring(res$message, 7)
		res$call <- NULL
		e <- res

		# for legacy uses
		res <- .makeMessage(res)
		class(res) <- "try-error"
		attr(res, 'error') <- e
	}

    return(res)
}

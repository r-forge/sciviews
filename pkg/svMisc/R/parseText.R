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
		msg <- conditionMessage(res)
		rxUEOI <- sprintf(gsub("%d", "\\\\d", gettext("%s%d:%d: %s", domain="R")),
			if(getOption("keep.source")) "<text>:" else "",
			gettextf("unexpected %s", gettext("end of input", domain="R"),
			domain="R"))


		if(regexpr(rxUEOI, res$message) == 1) return(NA)

		
		# This reformats the message as it would appear in the CLI:
		#mess <- conditionMessage(res)
		#errinfo <- strsplit(sub("(\\d+):(\\d+): +([^\n]+)[\\s\\S]*$", "\\1\n\\2\n\\3", mess, perl=T), "\n", fixed=TRUE)[[1]]
		#errpos <- as.numeric(errinfo[1:2])
		#errcode <- substr(strsplit(x, "(\r?\n|\r)")[[1]][errpos[1]], start = 0, stop = errpos[2])
		#res <- simpleError(sprintf("%s in \"%s\"", errinfo[3], errcode))

		e <- res <- simpleError(mess, NULL)

		# for legacy uses, make it a try-error
		res <- .makeMessage(res)
		class(res) <- "try-error"
		attr(res, 'error') <- e
	}

    return(res)
}

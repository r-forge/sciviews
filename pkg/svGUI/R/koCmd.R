"koCmd" <-
function(cmd, data = NULL, async = FALSE, host = getOption("ko.host"),
port = getOption("ko.port")) {
    if (is.null(host)) host <- "localhost"	# Default value
	if (is.null(port)) port <- 7052			# Idem
	cmd <- gsub("\n", "\\\\n", cmd)
	cmd <- paste(cmd, collapse = " ")
    if (is.na(cmd) || is.null(cmd) || length(cmd) == 0) {
		warning("No command supplied in cmd argument")
		return("")
    }
    # Do we need to paste data in the command?
	if (!is.null(data)) {	
		"rework" <- function(data) {
			data <- as.character(data)
			data <- gsub("\n", "\\\\\\\\n", data)
			data <- paste(data, collapse = "\\\\n")
			return(data)
		}
		
		n <- names(data)
		if (is.null(n)) {
			# We assume that we replace '<<<data>>>'
			cmd <- gsub("<<<data>>>", rework(data), cmd)
		} else {	# Named data
			# We replace each <<<name>>> in turn
			for (i in 1:length(n))
				cmd <- gsub(paste("<<<", n[i], ">>>", sep = ""),
					rework(data[[n[i]]]), cmd)
		}
	}
	con <- socketConnection(host = host, port = port, blocking = TRUE)
    writeLines(cmd, con)
    res <- readLines(con)
    close(con)
	# Did Komodo returned an error?
	getError <- function(data) {
		if (length(data) == 2 && data[1] == "" &&
			substring(data[2], 0, 6) == "Error:") {
			Err <- substring(data[2], 8)
			# One can also add clear messages for other errors
			data <- switch(Err,
				"2147500037" = "Error: incorrect JavaScript code",
				paste("Error: an unknown error", Err, "was returned by Komodo")
			)
			class(data) <- "try-error"
		}
		return(data)
	}
    return(getError(res))
}

"koCmd" <-
function (cmd, data = NULL, async = FALSE, host = getOption("ko.host"),
	port = getOption("ko.port"), timeout = 1, type = c("js", "rjsonp", "output"),
	pad = NULL, ...)
{

    type <- match.arg(type)
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
	# What type of data do we send?
	cmd <- switch(type,
		js = paste("<<<js>>>", cmd, sep = ""),
		rjsonp = paste("<<<rjsonp>>>", pad, "(",
			paste(toRjson(cmd, ...), collapse = " "), ")", sep = ""),
		cmd)
		
	otimeout <- getOption("timeout")
	options(timeout = timeout) # Default timeout is 60 seconds
	tryCatch(con <- socketConnection(host = host, port = port, blocking = TRUE),
			 warning = function(e) {
				stop(simpleError("Komodo socket server is not available!", quote(koCmd)))
				})
    writeLines(cmd, con)
    res <- readLines(con)
    close(con)
	options(timeout = otimeout)
    return(res)
}

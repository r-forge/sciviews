getServerObj <-
function (x, local = TRUE, server.envir = .GlobalEnv, con = NULL,
host = "localhost", port = 8888, ...)
{
	# Copy an R object from the server to the client
	objname <- as.character(substitute(x))
	servenv <- deparse(substitute(server.envir))
	if (is.null(con)) {
		# Use sendSocketServer() to open a connection to the serve, request the
		# object, and close the connection
		objdump <- sendSocketServer(paste('suppressWarnings(dump("', objname,
			'", file = "", envir = ', servenv,
			'))', sep = ""), host = host, port = port, ...)
	} else {
		# otherwise, use con to exchange data with the server, with a flag
		# to indicate where the returned dumped version of the R object ends
		writeLines(paste('suppressWarnings(dump("', objname,
			'", file = "", envir = ', servenv,
			')); cat("<<<endflag>>>")', sep = ""), con)
		objdump <- ""
		while (regexpr("<<<endflag>>>", objdump) < 0)
			objdump <- paste(objdump, readLines(con), sep = "", collapse = "\n")
		objdump <- sub("<<<endflag>>>", "", objdump)
	}
	# Source the content of objdump, locally, or in .GlobalEnv on the client R
	objcon <- textConnection(objdump)
	on.exit(close(objcon))
	res <- eval(source(objcon, local = local, echo = FALSE,
		verbose = FALSE), envir = envir)
}

setServerObj <-
function (x, envir = .GlobalEnv, con = NULL,
host = "localhost", port = 8888, ...)
{
	# Copy an R object from the client to the server
	objname <- as.character(substitute(x))
	# Get a dump of the local object
	objdump <- suppressWarnings(dump(objname, file = "", envir = envir))

	servenv <- deparse(substitute(server.envir))
	if (is.null(con)) {
		# Use sendSocketServer() to open a connection to the serve, request the
		# object, and close the connection
		objdump <- sendSocketServer(paste('suppressWarnings(dump("', objname,
			'", file = "", envir = ', servenv,
			'))', sep = ""), host = host, port = port, ...)
	} else {
		# otherwise, use con to exchange data with the server, with a flag
		# to indicate where the returned dumped version of the R object ends
		writeLines(paste('suppressWarnings(dump("', objname,
			'", file = "", envir = ', servenv,
			')); cat("<<<endflag>>>")', sep = ""), con)
		objdump <- ""
		while (regexpr("<<<endflag>>>", objdump) < 0)
			objdump <- paste(objdump, readLines(con), sep = "", collapse = "\n")
		objdump <- sub("<<<endflag>>>", "", objdump)
	}
	# Source the content of objdump, locally, or in .GlobalEnv on the client R
	objcon <- textConnection(objdump)
	on.exit(close(objcon))
	source(objcon, local = FALSE, echo = FALSE, verbose = FALSE)
}
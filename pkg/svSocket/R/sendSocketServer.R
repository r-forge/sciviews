"sendSocketServer" <-
function (text, serverhost = "localhost", serverport = 8888, ...)
{
	# This function connects to a R socket server, evaluates a command in it
	# get results and closes the connection. See example for a client that
	# connects for a longer time and sends several commands to the server
	if (!capabilities("sockets"))
		stop("R must support socket connections")
	con <- socketConnection(host = serverhost, port = serverport,
		blocking = FALSE, ...)
	on.exit(close(con))
	# <<<q>>> tells the R socket server to close the connection once results
	# are send back to the client
	writeLines(paste("<<<q>>>", text, sep = ""), con)
	res <- ""
	while(regexpr("\n\f", res) < 0)
		res <- paste(res, readLines(con), sep = "", collapse = "\n")
	return(sub("\n\f", "", res))
}

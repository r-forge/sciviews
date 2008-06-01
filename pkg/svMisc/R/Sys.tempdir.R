"Sys.tempdir" <-
function() {
	# On the contrary to tempdir(), this function returns the temporary
	# directory used by the system. It is assumed to be
	# the parent directory of tempdir()
	return(dirname(tempdir()))
}

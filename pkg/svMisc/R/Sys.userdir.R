"Sys.userdir" <-
function() {
	if (isWin()) {
		# Return the user directory ("My Documents" under Windows)
		udir <- Sys.getenv("R_User")
		udir <- normalizePath(udir)
	} else { # Just expand ~
	    udir <- normalizePath("~")
	    # For reasons I ignore /~ is appended at the end of the path (on MacOS)
	    udir <- sub("/~$", "", udir)
	}
	return(udir)
}

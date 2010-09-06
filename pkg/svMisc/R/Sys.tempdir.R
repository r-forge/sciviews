Sys.tempdir <- function ()
{
	## On the contrary to tempdir(), this function returns the temporary
	## directory used by the system. It is assumed to be
	## the parent directory of tempdir()
	## TODO: shouldn't we return /tmp on Mac OS X???
	return(dirname(tempdir()))
}

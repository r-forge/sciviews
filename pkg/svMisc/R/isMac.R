isMac <- function ()
    grepl("darwin", R.version$os) # According to what's done in R sources
	#(grepl("^mac", .Platform$pkgType))

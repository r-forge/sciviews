"getFunctions" <-
function(pos) {
	# Get a list of all R functions in a certain position
	lst <- objects(pos = pos, all.names = TRUE)
	l <- length(lst)
	if (l == 0) return(NULL) else {
		isFun <- rep(FALSE, l)
		for (i in 1:l)
			if (exists(lst[i], where = pos, mode = "function", inherits = FALSE))
				isFun[i] <- TRUE
		# Keep only functions
		lst <- lst[isFun]
		return(lst)
	}
}

"objSearch" <-
function(sep = "\t", path = NULL, compare = TRUE) {
    Search <- as.matrix(data.frame(Workspace = search()))
	if (compare) {
		oldSearch <- getTemp(".guiObjSearchCache", default = "")
		# Compare both versions
		if (!(all.equal(Search, oldSearch)[1] == TRUE)) {
			# Keep a copy of the last version in TempEnv
			assignTemp(".guiObjSearchCache", Search) 
			Changed <- TRUE
		} else Changed <- FALSE
	} else Changed <- TRUE
    if (is.null(path)) { # Simply return result
		if (Changed) return(Search) else return("")
	} else { # Write to a file called 'Search.txt' in this path
		file <- file.path(path, "Search.txt")	
		if (Changed)
			write.table(Search, file = file, row.names = FALSE, quote = FALSE,
				sep = sep)
		return(Changed)
	}
}


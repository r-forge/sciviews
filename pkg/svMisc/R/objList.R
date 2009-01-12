`objList` <- function(id = "default", envir = .GlobalEnv, object = "", all.names = FALSE,
pattern = "", group = "", all.info = FALSE, sep = "\t", path = NULL, compare = TRUE) {

	# Empty result. Change back to data frame?
	Nothing <- structure(NULL, class = c("objList", "NULL"))

	#Nothing <- structure(list(character(0), character(0), character(0), character(0), character(0), logical(0)), .Names = c("Envir",  "Name", "Dims", "Group", "Class", "Recursive"), class = c("objList", "NULL","data.frame"))
	#
	#if (!all.info)
	#	Nothing <- Nothing[,-1]




	# Make sure that id is character
	id <- as.character(id)[1]
	if (id == "") id <- "default"

	# Format envir as character (use only first item provided!)
	if (!is.environment(envir)){
		envir <- envir[1]
		if( is.numeric(envir) ){
			ename <- search( )[envir]
			envir <- as.environment( envir )
		} else if( is.character( envir ) ){
			envir <- as.environment( match( ename <- envir, search() ) )
		} else {
			return(Nothing)
		}
	} else{
		ename <- deparse( substitute( envir ) )
	}

	# Get the list of objects in this environment
	Items <- ls(envir=envir, all.names = all.names, pattern = pattern)
	if (length(Items) == 0) {
		return(Nothing)
	}

	# Get characteristics of all objects
	`describe` <- function(name, all.info = FALSE) {
		# get a vector with five items:
		# Name, Dims, Group, Class and Recursive
		obj <- envir[[ name ]]
		res <- c(
			Name = name,
			Dims = if (is.null(Dim <- dim(obj))) length(obj) else paste(Dim, collapse = "x"),
			Group = typeof(obj),
			Class = class(obj)[1],
			Recursive = !inherits(obj, "function") && is.recursive(obj))
		if (all.info) res <- c(Envir = ename, res)
		return(res)
	}
	res <- data.frame(t(sapply(Items, describe, all.info = all.info)), stringsAsFactors = FALSE)

	# Recalculate groups into meaningful ones for the object explorer
	# 1) Correspondance of typeof() and group depicted in the browser
	GrpTable <- c(
		"NULL", 	"language", "list",		  "function",   "language",
		"language",	"language", "function",   "function",	"language",
		"logical",	"numeric",	"numeric",	  "complex",	"character",
		"language", "language",	"language",	  "list",		"language",
		"S4",		"language", "raw",		  "language")
	names(GrpTable) <- c(
		"NULL", 	"symbol", 	"pairlist",	  "closure", 	"environment",
		"promise",	"language",	"special", 	  "builtin", 	"char",
		"logical", 	"integer",	"double", 	  "complex", 	"character",
		"...",		"any", 		"expression", "list", 		"bytecode",
		"S4", 		"weakref", 	"raw", 	  	  "externalptr")
	Groups <- GrpTable[res$Group]

	# 2) All Groups not being language, function or S4 whose class is
	#    different than typeof are flagged as S3 objects
	Filter <- !(Groups %in% c("language", "function", "S4"))
	Groups[Filter][res$Group[Filter] != res$Class[Filter]] <- "S3"

	# 3) Special case for typeof = double and class = numeric
	Groups[res$Group == "double"] <- "numeric"

	# 4) integers of class factor become factor in group
	Groups[res$Class == "factor"] <- "factor"

	# 5) Objects of class 'data.frame' are also group 'data.frame'
	Groups[res$Class == "data.frame"] <- "data.frame"

	# 6) Objects of class 'Date' or 'POSIXt' are of group 'DateTime'
	Groups[res$Class == "Date"] <- "DateTime"
	Groups[res$Class == "POSIXt"] <- "DateTime"

	# Reaffect groups
	res$Group <- Groups

	# Possibly filter according to group
	if (!is.null(group) && group != "") res <- res[Groups == group, ]

	class( res ) <- c( "objList", "data.frame" )

	# Determine if it is required to refresh something
	Changed <- TRUE
	if (compare) {
		allList <- getTemp(".guiObjListCache", default = list())
		if (identical(res, allList[[id]])) Changed <- FALSE else {
			# Keep a copy of the last version in TempEnv
			allList[[id]] <- res
			assignTemp(".guiObjListCache", allList)
		}
	}

	if (is.null(path)) { # Return results or "" if not changed
		if (Changed)
			return(res)
		else
			return(Nothing)
	} else if (Changed) { # Write to files in this path
		# Create file names
		ListF <- file.path(path, paste("List_", id, ".txt", sep = ""))
		ParsF <- file.path(path, paste("Pars_", id, ".txt", sep = ""))
		cat(res, file = ListF, sep = "\n")
		# Write also in the Pars_<id>.txt file in the same directory
		cat("envir=", ename , "\n", sep = "", file = ParsF, append = TRUE)
		cat("all.names=", all.names, "\n", sep = "", file = ParsF, append = TRUE)
		cat("pattern=", pattern, "\n", sep = "", file = ParsF, append = TRUE)
		cat("group=", group, "\n", sep = "", file = ParsF, append = TRUE)
		return(invisible(ListF))
	} else
		return(Nothing) # Not changed
}



`print.objList` <- function(x, sep = "\t", sep2 = "\n", ...){
	if (!is.null(x)) {
		if( is.null(sep) ) {
			NextMethod( "print" )
		} else if( !is.null(nrow(x)) && nrow(x) > 0 ){
			out <- apply(x, 1, paste, collapse=sep)
			cat(out, sep = sep2)
		}
	} else {
		cat()
	}
}


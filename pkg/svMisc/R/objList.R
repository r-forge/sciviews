
NOTHING <- data.frame( Envir=character(), Name=character(), Dims=character(), 
	Group=character(), Class = character(), Recursive = logical(), 
	stringsAsFactors=FALSE)
class( NOTHING ) <- c( "objList", "data.frame" ) 

"objList" <- function(id = "default", envir = .GlobalEnv, object = "", all.names = FALSE,
pattern = "", group = "", all.info = FALSE, path = NULL, compare = TRUE) {

  # Make sure that id is character
  id <- as.character(id)[1]
  if (id == "") id <- "default"
	
	# Format envir as character (use only first item provided!)
	if (!is.environment(envir)){
		if( is.numeric(envir) ){
			ename <- search( envir[1] )
			envir <- as.environment( envir[1] )
		} else if( is.character( envir ) ){
			envir <- as.environment( match( ename <- envir[1], search() ) )
		} else {
			return( NOTHING )
		}
	} else{
		ename <- deparse( substitute( envir ) )
	}
	
	# Get the list of objects in this environment
	Items <- ls(envir=envir, all.names = all.names, pattern = pattern)
	if (length(Items) == 0) {
		if (all.info) {
			return(NOTHING)
		} else {
			return(NOTHING[,-1])				
		}
	}
	
	# Get characteristics of all objects
	"describe" <- function(name, envir=.GlobalEnv, all.info = FALSE) {
		# get a vector with five items:
		# Name, Dims, Group, Class and Recursive
		obj <- envir[[ name ]]
		res <- c(
			Name = name,
			Dims = if (is.null(Dim <- dim(obj))) length(obj) else paste(Dim, collapse = "x"),
			Group = typeof(obj),
			Class = class(obj)[1],
			Recursive = !inherits(obj, "function") && is.recursive(obj))
		if (all.info) res <- c(Envir = as.character(envir), res)	
		return(res)
	}
	res <- data.frame(t(sapply(Items, describe, envir = envir,
		all.info = all.info)), stringsAsFactors = FALSE)
	
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
		if (Changed) return(invisible(res)) else return(invisible(NOTHING))
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
	} else return(invisible(FALSE))	# Not changed
}

print.objList <- function( x, sep="\t", ...){
	if( is.null(sep) ){
		NextMethod( "print" )
	} else {
		if( !is.null(nrow(x)) && nrow(x) > 0 ){
			out <- apply( x, 1, paste, collapse = sep )
			out
		} else{
			""
		}
	}
}


"objList" <-
function(id = "default", envir = .GlobalEnv, object = "", all.names = FALSE,
pattern = "", group = "", all.info = FALSE, sep = "\t", path = NULL,
compare = TRUE) {

    # Make sure that id is character
    id <- as.character(id)[1]
    if (id == "") id <- "default"
    
	# Format envir as character (use only first item provided!)
	if (is.environment(envir)) envir <- deparse(substitute(envir))
	if (is.numeric(envir)) envir <- search()[envir[1]]
	envir <- as.character(envir)[1]
	# Get the current position in the search path for envir
	pos <- match(envir, search(), nomatch = -1)
	if (pos < 1) {
		pos <- 1		# NOT FOUND, return nothing
		Changed <- FALSE
	} else {			# Environment found
		if (object == "") {
		# Get the list of objects in this environment
			Items <- ls(pos = pos, all.names = all.names, pattern = pattern)
			if (length(Items) == 0) if (all.info) {
				return(invisible(data.frame(Name = character(), Dims = character(),
					Group = character(), Class = character(),
					Recusive = logical(), stringsAsFactors = FALSE)))
			} else {
				return(data.frame(Envir = character(), Name = character(),
					Dims = character(), Group = character(), Class = character(),
					Recusive = logical(), stringsAsFactors = FALSE))				
			}
			
			# Get characteristics of all objects
			"describe" <- function(name, pos = ".GlobalEnv", all.info = FALSE) {
				# get a vector with five items:
				# Name, Dims, Group, Class and Recursive
				obj <- get(name, pos = pos)
				res <- c(
					Name = name,
					Dims = if (is.null(Dim <- dim(obj))) length(obj) else
						paste(Dim, collapse = "x"),
					Group = typeof(obj),
					Class = class(obj)[1],
					Recursive = !inherits(obj, "function") && is.recursive(obj))
				if (all.info) res <- c(Envir = pos, res)	
				return(res)
			}
			res <- data.frame(t(sapply(Items, describe, pos = envir,
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
			
			# Transform into a character vector
			res <- apply(res, 1, paste, collapse = sep)
			
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
		} else {
			# Get components of object (first level only for the moment)
			### TODO: report components of objects...
			Changed <- FALSE
		}
	}
		
	if (is.null(path)) { # Return results or "" if not changed
		if (Changed) return(invisible(res)) else return(invisible(""))
	} else if (Changed) { # Write to files in this path
		# Create file names
		ListF <- file.path(path, paste("List_", id, ".txt", sep = ""))
		ParsF <- file.path(path, paste("Pars_", id, ".txt", sep = ""))
		cat(res, file = ListF, sep = "\n")
		# Write also in the Pars_<id>.txt file in the same directory
		cat("pos=", pos, "\n", sep = "", file = ParsF)
		cat("envir=", search()[pos], "\n", sep = "", file = ParsF, append = TRUE)
		cat("all.names=", all.names, "\n", sep = "", file = ParsF, append = TRUE)
		cat("pattern=", pattern, "\n", sep = "", file = ParsF, append = TRUE)
		cat("group=", group, "\n", sep = "", file = ParsF, append = TRUE)
		return(invisible(ListF))
	} else return(invisible(FALSE))	# Not changed
}

`objList` <- function(id = "default", envir = .GlobalEnv, object = NULL, all.names = FALSE,
pattern = "", group = "", all.info = FALSE, path = NULL, compare = TRUE, ...) {

	#Nothing <- structure(list(character(0), character(0), character(0), character(0), character(0), logical(0)), .Names = c("Envir",  "Name", "Dims", "Group", "Class", "Recursive"), class = c("objList", "NULL","data.frame"))
	#
	#if (!all.info)
	#	Nothing <- Nothing[,-1]


	# Make sure that id is character
	id <- as.character(id)[1]
	if (id == "") id <- "default"

	# Format envir as character (use only first item provided!)
	if (!is.environment(envir[1])){
		envir <- tryCatch(as.environment(envir[1]), error = function(e) NULL)

		if(is.null(envir) ){
			return(Nothing)
		} else {
			ename <- if (is.null(attr(envir, "name"))) ".GlobalEnv" else attr(envir, "name")
		}
	} else {
		ename <- deparse( substitute( envir ) )
	}


	#cat("ename:", ename, "\n")

	# Empty result. Change back to data frame?
	Nothing <- structure(NULL, class = c("objList", "NULL"),
				   all.info = all.info, envir = ename, object = object)

	if (!missing(object) && is.character(object) && object != "") {
		res <- lsObj(envir = envir, objname = object)
	} else {
		# Get the list of objects in this environment
		Items <- ls(envir = envir, all.names = all.names, pattern = pattern)
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
				Group = mode(obj),
				Class = class(obj)[1],
				Recursive = is.recursive(obj) || mode(obj) == "S4"
			)
			return(res)

		}
		res <- data.frame(t(sapply(Items, describe, all.info = all.info)), stringsAsFactors = FALSE)

	}

	if (is.null(res))
		return(Nothing)

	if (isTRUE(all.info))
		res <- cbind(Environment = ename, res)

	vMode <- Groups <- res$Group
	vClass <- res$Class

	# Recalculate groups into meaningful ones for the object explorer
	# 1) Correspondance of typeof() and group depicted in the browser
	#{{
	Groups[Groups %in% c("name", "environment", "promise", "language", "char", "...", "any",
	  "(", "call", "expression", "bytecode", "weakref", "externalptr")] <- "language"

	Groups[Groups == "pairlist"] <- "list"


	# 2) All Groups not being language, function or S4 whose class is
	#    different than typeof are flagged as S3 objects
	Groups[!(Groups %in% c("language", "function", "S4")) & vMode != vClass] <- "S3"

	# 4) integers of class factor become factor in group
	Groups[vClass == "factor"] <- "factor"

	# 5) Objects of class 'data.frame' are also group 'data.frame'
	Groups[vClass == "data.frame"] <- "data.frame"

	# 6) Objects of class 'Date' or 'POSIXt' are of group 'DateTime'
	Groups[vClass == "Date" | vClass == "POSIXt"] <- "DateTime"

	# Reaffect groups
	res$Group <- Groups

	# Possibly filter according to group
	if (!is.null(group) && group != "")
		res <- res[Groups == group, ]

	#}}


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

	res <- structure(
		.Data = res,
		class = c( "objList", "data.frame" ), id = id, envir = ename,
		all.names = all.names, all.info = all.info, pattern = pattern,
		group = group, object = if (!is.null(object)) object else NULL
	)

	if (is.null(path)) { # Return results or "" if not changed
		return(if (Changed) res else Nothing)
	} else if (Changed) { # Write to files in this path
		write.objList(res, path, ...)
	} else
		return(Nothing) # Not changed
}



`write.objList` <- function(x, path, sep = "\t", ...) {

	id <- attr(x, "id")
	ListF <- file.path(path, sprintf("List_%s.txt", id))
	ParsF <- file.path(path, sprintf("Pars_%s.txt", id))

	write.table(x, row.names = FALSE, col.names = FALSE, sep =",", quote = FALSE,  file = ListF)

	# Write also in the Pars_<id>.txt file in the same directory
	cat(sprintf("envir=%s\nall.names=%s\npattern=%s\ngroup=%s",
		attr(x, "envir"), attr(x, "all.names"), attr(x, "pattern"),
		attr(x, "group")), file = ParsF, append = FALSE
	    )

	return(invisible(ListF))

}


`print.objList` <- function(x, sep = "\t", eol = "\n", header = !attr(x, "all.info"), ...){
	if (!is.null(x)) {
		if (header) {
			cat("#Environment=",attr(x, "envir"), "\n", sep = "")
			cat("#Object=", if (is.null(attr(x, "object"))) "" else attr(x, "object"), "\n", sep = "")
		}

		if(is.na(sep) ) {
			print.data.frame(x)
		} else if( !is.null(nrow(x)) && nrow(x) > 0 ){
			write.table(x, row.names = FALSE, col.names = FALSE,
				sep = sep, eol = eol, quote = FALSE)
			return(invisible(x))
		}
	} else {
		cat()
	}
}

# called by objList when object is provided
#TODO: simplify, possilby merge lsObj.S4 into lsObj
`lsObj` <- function(objname, envir, ...) {

	obj <- try(eval(parse(text = objname)), silent = TRUE)
	if (inherits(obj, "try-error")) {
		return (NULL);
	}

	if (mode(obj) == "S4") {
		ret <- lsObj.S4(obj, objname)
	} else if (is.function(obj)){
		ret <- lsObj.function(obj, objname)
	} else {	#S3:

#{{
		if (!(mode(obj) %in% c("list", "pairlist")) || length(obj) == 0)
			return(NULL);

		itemnames <- fullnames <- names(obj)
		if (is.null(itemnames)) {
			itemnames <- seq_along(obj)
			fullnames <- paste(objname, "[[", seq_along(obj), "]]", sep = "")
		} else {
			w.names <- itemnames != ""
			.names <- itemnames[w.names]
			nsx <- .names != make.names(.names) # non-syntactic names
			.names[nsx] <- paste("`", .names[nsx], "`", sep = "")
			fullnames[w.names] <- paste (objname, "$", .names, sep = "")
			fullnames[!w.names] <- paste(objname, "[[", seq_along(itemnames)[!w.names], "]]", sep = "")
		}


		ret <- t(sapply (seq_along(obj), function(i) {
			x <- obj[[i]]

			d <- dim(x)
			if (is.null(d)) d <- length(x)

			ret <- c(paste(d, collapse="x"),
					mode(x),
					class(x)[1],
					is.function(x) || (is.recursive(x) && !is.language(x) && sum(d) != 0)
			)
			return (ret)
		}))


		ret <- data.frame(itemnames, fullnames, ret, stringsAsFactors = FALSE)
#}}
	}

	if (!is.null(ret))
		names(ret) <- c("Name", "Full.name", "Dims/default", "Group", "Class", "Recursive")




	return (ret)
}

# called by lsObj
`lsObj.function` <- function(obj, objname = deparse(substitute(obj))) {
	#   formals(obj) returns NULL if only arg is ..., try: formals(expression)
	obj <- formals(args(obj))
	objname <- paste("formals(args(", objname, "))", sep = "")

	if(length(obj) == 0)
		return(NULL);

	itemnames <- fullnames <- names(obj)
	nsx <- itemnames != make.names(itemnames) # non-syntactic names
	itemnames[nsx] <- paste("`", itemnames[nsx], "`", sep = "")
	fullnames <- paste (objname, "$", itemnames, sep = "")

	ret <- t(sapply (seq_along(obj), function(i) {
		x <- obj[[i]]
		lang <- is.language(obj[[i]])
		o.class <- class(obj[[i]])[1]
		o.mode <- mode(obj[[i]])

		d <- deparse(obj[[i]]);
		if (lang && o.class == "name") {
			o.class <- ""
			o.mode <- ""
		}

		ret <- c(paste(d, collapse="x"), o.class,	o.mode, FALSE)

		return (ret)

	}))

	ret <- data.frame(itemnames, fullnames, ret, stringsAsFactors = FALSE)

	return (ret)
}


# called by lsObj in S4 case
`lsObj.S4` <- function(obj, objname = deparse(substitute(obj)))  {
	itemnames <- fullnames <- slotNames(obj);
	nsx <- itemnames != make.names(itemnames)
	itemnames[nsx] <- paste("`", itemnames[nsx], "`", sep = "")
	fullnames <- paste (objname, "@", itemnames, sep = "")


	ret <- t(sapply (itemnames, function(i) {
		x <- slot(obj, i)

		d <- dim(x)
		if (is.null(d)) d <- length(x)

			ret <- c(paste(d, collapse="x"),
					mode(x),
					class(x)[1],
					is.function(x) || (is.recursive(x) && !is.language(x) && sum(d) != 0)
			)
	}))

	ret <- data.frame(itemnames, fullnames, ret, stringsAsFactors = FALSE)
	return(ret)
}

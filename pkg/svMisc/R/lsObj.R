lsObj <- function(objname, envir = .GlobalEnv, sep = ",") {


	if (!is.environment(envir)){
		envir <- envir[1]
		if( is.numeric(envir) ){
			ename <- search()[envir]
			envir <- as.environment( envir )
		} else if( is.character( envir ) ){
			envir <- as.environment( match( ename <- envir, search() ) )
		} else {
			return("")
		}
	} else{
		ename <- deparse( substitute( envir ) )
	}

	obj <- try(eval(parse(text = objname)), silent = TRUE)
	if (inherits(obj, "try-error")) {
		return ("");
	}

	if (mode(obj) == "S4") {
		return (lsSlots(obj, objname, ename, sep = sep));
	}

	if (is.function(obj)) {
		obj <- formals(obj)
		objname <- paste("formals(", objname, ")")
		fun <- TRUE
	} else {
		fun <- FALSE
		if (!(mode(obj) %in% c("list", "pairlist")))
			return("");
	}

	if(length(obj) == 0)
		return("");

	itemnames <- fullnames <- names(obj)
	if (is.null(itemnames)) {
		fullnames <- paste(objname, "[[", seq_along(obj), "]]", sep = "")
	} else {
		w.names <- itemnames != ""
		.names <- itemnames[w.names]
		nsx <- .names != make.names(.names) # non-syntactic names
		.names[nsx] <- paste("`", .names[nsx], "`", sep = "")
		fullnames[w.names] <- paste (objname, "$", .names, sep = "")
		fullnames[!w.names] <- paste(objname, "[[", seq_along(itemnames)[!w.names], "]]", sep = "")
	}

	ret <- c()
	for (i in seq_along(obj)) {
		x <- obj[[i]]
		lang <- is.language(obj[[i]])
		o.class <- class(obj[[i]])[1]
		o.mode <- mode(obj[[i]])

		if (fun) {
			if (o.class == "logical") {
				d <- if(isTRUE(obj[[i]])) "TRUE" else "FALSE";
			} else {
				d <- deparse(obj[[i]]);
				if (lang) {

					if (o.class == "name") {
						o.class <- ""
						o.mode <- ""
					}
				}
			}

		} else {
			d <- dim(x)
			if (is.null(d)) d <- length(x)
			pos.length <- sum(d) != 0
		}

		ret <- rbind(ret,
			list(paste(d, collapse="x"),
				o.class,
				o.mode,
				is.function(obj[[i]]) || (is.recursive(obj[[i]]) && !lang && pos.length))
		)
	}
	if (is.na(sep)) {
		ret <- data.frame(ename, itemnames, fullnames, ret)
		names(ret) <- c("Environment", "Name", "Full name", "Dims/default value", "Class", "Mode", "Recursive")
	} else {
		ret <- apply(ret, 1, paste, collapse = sep)
		ret <- paste(ename, itemnames, fullnames, ret, sep = sep)
	}

	return (ret)
}


# called by lsObj in S4 case
lsSlots <- function(obj, objname = deparse(substitute(obj)), ename, sep = ",")  {
	itemnames <- fullnames <- slotNames(obj);
	nsx <- itemnames != make.names(itemnames)
	itemnames[nsx] <- paste("`", itemnames[nsx], "`", sep = "")
	fullnames <- paste (objname, "@", itemnames, sep = "")
	ret <- c()

	for (i in itemnames) {
		x <- slot(obj, i)
		lang <- is.language(x)
		o.class <- class(x)[1]
		o.mode <- mode(x)

		d <- dim(x)
		if (is.null(d)) d <- length(x)
		pos.length <- sum(d) != 0

		ret <- append(ret,
			paste(paste(d, collapse="x"),
				o.class,
				o.mode,
				is.function(x) || (is.recursive(x) && !lang && pos.length),
			sep = sep)
		)
	}

	if (is.na(sep)) {
		ret <- data.frame(ename, itemnames, fullnames, ret)
		names(ret) <- c("Environment", "Name", "Full name", "Dims/default value", "Class", "Mode", "Recursive")
	} else {
		ret <- apply(ret, 1, paste, collapse = sep)
		ret <- paste(ename, itemnames, fullnames, ret, sep = sep)
	}
	return(ret)
}

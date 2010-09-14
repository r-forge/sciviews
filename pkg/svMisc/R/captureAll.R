captureAll <- function (expr, split = FALSE, file = NULL)
{
	## If expr is NA, just return it
	if (!is.language(expr))
		if (identical(expr, NA))
			return(NA) else stop("'expr' must be an expression or NA")
	## Ensure split is always a boolean
	split <- isTRUE(split)

	## captureAll() is inspired from capture.output(), but it captures
	## both the output and the message streams (without redirecting
	## the message stream, but by using a withCallingHandlers() construct).
	rval <- NULL	# Just to avoid a note during code analysis
	if (is.null(file)) file <- textConnection("rval", "w", local = TRUE)
	sink(file, type = "output", split = split)

	## This is a hack to display warning(..., immediate.) correctly
	## (except from base objects) because there is no way to detect it
	## in our handler with the current warning() function
	assign("warning", function(..., call. = TRUE, immediate. = FALSE,
		domain = NULL) {
		args <- list(...)
		if (length(args) == 1 && inherits(args[[1]], "condition")) {
			base::warning(..., call. = call., immediate. = immediate.,
				domain = domain)
		} else {
			## Deal with immediate warnings
			oldwarn <- getOption("warn")
			if (immediate. && oldwarn < 1) {
				options(warn = 1)
				on.exit(options(warn = oldwarn))
			}
			.Internal(warning(as.logical(call.), as.logical(immediate.),
				.makeMessage(..., domain = domain)))
		}
	}, envir = TempEnv())
	on.exit({
		sink(type = "output")
		close(file)
		if (exists("warning", envir = TempEnv(), inherits = FALSE))
			rm("warning", envir = TempEnv())
	})

	evalVis <- function (Expr)
	{
		## We need to install our own warning handling
		## and also, we use a customized interrupt handler
		owarns <- getOption("warning.expression")
		## Inactivate current warning handler
		options(warning.expression = expression())
		## ... and make sure it is restored at the end
		on.exit({
			## Check that the warning.expression was not changed
			nwarns <- getOption("warning.expression")
			if (!is.null(nwarns) && length(as.character(nwarns)) == 0)
				options(warning.expression = owarns)
		})
		## Evaluate instruction(s) in the user workspace (.GlobalEnv)
		res <- try(withCallingHandlers(withVisible(eval(Expr, .GlobalEnv)),
			warning = function (e) {
				msg <- conditionMessage(e)
				call <- conditionCall(e)

				## Possibly truncate it
				wl <- getOption("warning.length")
				if (is.null(wl)) wl <- 1000 # Default value
				if (nchar(msg) > wl)
					msg <- paste(substr(msg, 1, wl), .gettext("[... truncated]"))

				## Result depends upon 'warn'
				Warn <- getOption("warn")

				## If warning generated in eval environment, make it NULL
				try(if (!is.null(call)  && !is.symbol(call) &&
					identical(call[[1L]], quote(eval)))
					e$call <- NULL, silent = TRUE)

				if (Warn < 0) { # Do nothing!
					return()
				} else if (Warn == 0) { # Delayed display of warnings
					if (exists("warns", envir = TempEnv())) {
						lwarn <- get("warns", envir = TempEnv())
					} else lwarn <- list()
					## Do not add more than 50 warnings
					if (length(lwarn) >= 50) return()

					## Add the warning to this list and save in TempEnv()
					assign("warns", append(lwarn, list(e)), envir = TempEnv())

					return()
				} else if (Warn > 1) { # Generate an error!
					msg <- .gettextf("(converted from warning) %s", msg)
					stop(simpleError(msg, call = call))
				} else {
					## warn = 1
					## Print the warning message immediately
					## Format the warning message

					## This is modified code from base::try
					if (!is.null(call)) {
						dcall <- deparse(call)[1L]
						prefix <- paste(.gettext("Warning in"), dcall, ": ")
						LONG <- 75L
						sm <- strsplit(msg, "\n")[[1L]]
						w <- 14L + nchar(dcall, type = "w") + nchar(sm[1L], type = "w")
						if (is.na(w)) 
							w <- 14L + nchar(dcall, type = "b") + nchar(sm[1L], type = "b")
						if (w > LONG)
							prefix <- paste(prefix, "\n  ", sep = "")
					} else prefix <- .gettext("Warning : ")

					msg <- paste(prefix, msg, "\n", sep="")
					cat(msg)
				}
			}
			, interrupt = function (i) cat(.gettext("<INTERRUPTED!>\n"))
			## This is modified code from base::try
			, error = function(e) {
				call <- conditionCall(e)
				msg <- conditionMessage(e)

				## Patch up the call to produce nicer result for testing as
				## try(stop(...)).  This will need adjusting if the
				## implementation of tryCatch changes.
				## Use identical() since call[[1]] can be non-atomic.
				try(if (!is.null(call) && !is.symbol(call) &&
					identical(call[[1L]], quote(eval)))
					call <- NULL, silent = TRUE)
				if (!is.null(call)) {
					dcall <- deparse(call)[1L]
					prefix <- paste(.gettext("Error in "), dcall, ": ")
					LONG <- 75L
					sm <- strsplit(msg, "\n")[[1L]]
					w <- 14L + nchar(dcall, type = "w") + nchar(sm[1L], type = "w")
					if (is.na(w)) 
						w <- 14L + nchar(dcall, type = "b") + nchar(sm[1L], type = "b")
					if (w > LONG) 
						prefix <- paste(prefix, "\n  ", sep = "")
				} else prefix <- .gettext("Error : ")

				msg <- paste(prefix, msg, "\n", sep = "")
				## Store the error message for legacy uses of try() with
				## geterrmessage().
				.Internal(seterrmessage(msg[1L]))
				if (identical(getOption("show.error.messages"), TRUE))
					cat(msg)
			}
			, message = function(e) {
				signalCondition(e)
				cat(conditionMessage(e))
			}
		), silent = TRUE)
		## Possibly add 'last.warning' as attribute to res
		if (exists("warns", envir = TempEnv())) {
			warns <- get("warns", envir = TempEnv())

			## Reshape the warning list
			last.warning <- lapply(warns, "[[", "call")
			names(last.warning) <- sapply(warns, "[[", "message")

			attr(res, "last.warning") <- last.warning
			rm("warns", envir = TempEnv())
		}
		return(res)
	}

	## This is my own function to display delayed warnings
	WarningMessage <- function (last.warning)
	{
		assign("last.warning", last.warning, envir = baseenv())
		n.warn <- length(last.warning)
		if (n.warn < 11) {	# If less than 11 warnings, print them
			## For reasons I don't know, R append a white space to the warning
			## messages... we replicate this behaviour here.
			print.warnings(warnings(" ", sep = ""))
		} else if (n.warn >= 50) {
			cat(.gettext("There were 50 or more warnings (use warnings() to see the first 50)\n"))
		} else {
			cat(.gettextf("There were %d warnings (use warnings() to see them)\n",
				n.warn))
		}
		return(invisible(n.warn))
	}

	for (i in 1:length(expr)) {
		tmp <- evalVis(expr[[i]])
		if (inherits(tmp, "try-error")) {
			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning)) {
				cat(.gettext("In addition : "))
				WarningMessage(last.warning)
			}
			break
	   	} else {	 # No error
			if (tmp$visible) print(tmp$value)
			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning))
				WarningMessage(last.warning)
		}
	}
	cat("\n")   # In case last line does not end with \n, I add it!
	return(rval)
}


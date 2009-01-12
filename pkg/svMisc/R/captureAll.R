"captureAll" <-
function (expr) {
	# capture.all() is inspired from capture.output(), but it captures
	# both the output and the message streams
	rval <- NULL	# Just to avoid a note during code analysis
	file <- textConnection("rval", "w", local = TRUE)
	sink(file, type = "output")
	#sink(file, type = "message")  # not necessarry anymore since there is custom error handler

	# This is a hack to display warning(..., immediate.) correctly
	# (except from base objects) because there is no way to detect it
	# in our handler with the current warning() function
	assign("warning", function(..., call. = TRUE, immediate. = FALSE,
		domain = NULL) {
		args <- list(...)
		if (length(args) == 1 && inherits(args[[1]], "condition")) {
			base::warning(..., call. = call., immediate. = immediate.,
				domain = domain)
		} else {
			# Deal with immediate warnings
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
		#sink(type = "message")
		close(file)
		if (exists("warning", envir = TempEnv()))
			rm("warning", envir = TempEnv())
	})

	"evalVis" <- function (Expr) {
		# We need to install our own warning handling
		# and also, we use a customized interrupt handler
		owarns <- getOption("warning.expression")
		# Inactivate current warning handler
		options(warning.expression = expression())
		# ... and make sure it is restored at the end
		on.exit({
			# Check that the warning.expression was not changed
			nwarns <- getOption("warning.expression")
			if (!is.null(nwarns) && length(as.character(nwarns)) == 0)
				options(warning.expression = owarns)
		})
		# Evaluate instruction(s) in the user workspace (.GlobalEnv)
		#myEvalEnv.. <- .GlobalEnv # << is this necessary?

		res <- try(withCallingHandlers(.Internal(eval.with.vis(Expr,
			.GlobalEnv, baseenv())),
			warning = function (e) {
				# changed some variable names to match corresponding ones in the error handler below

				msg <- conditionMessage(e)
				call <- conditionCall(e)

				# Possibly truncate it
				wl <- getOption("warning.length")
				if (is.null(wl)) wl <- 1000 # Default value
				if (nchar(msg) > wl)
					msg <- paste(substr(msg, 1, wl),
					.gettext("[... truncated]"))   #  [... truncated] not in it?

				# Result depends upon 'warn'
				Warn <- getOption("warn")

				# If warning generated in eval environment,  make it NULL
				if (!is.null(call) && identical(call[[1]], quote(eval.with.vis)))
					e$call <- NULL

				if (Warn < 0) { # Do nothing!
					return()
				} else if (Warn == 0) { # Delayed display of warnings
					if (exists("warns", envir = TempEnv())) {
						lwarn <- get("warns", envir = TempEnv())
					} else lwarn <- list()
					# Do not add more than 50 warnings
					if (length(lwarn) >= 50) return()

					# Add the warning to this list and save in TempEnv()
					assign("warns", append(lwarn, list(e)), envir = TempEnv())

					return()
				} else if (Warn > 1) { # Generate an error!
					msg <- .gettextf("(converted from warning) %s", msg)
					stop(simpleError(msg, call = call))
				} else {
					# warn = 1
					# Print the warning message immediately
					# Format the warning message

					# this is modified code from base::try
					if (!is.null(call)) {
						dcall <- deparse(call)[1]
						prefix <- paste(.gettext("Warning in"), dcall, ": ")
						sm <- strsplit(msg, "\n")[[1]]
						if (nchar(dcall, type="w") + nchar(sm[1], type="w") > 58) # to match value in errors.c
							prefix <- paste(prefix, "\n  ", sep = "")
					} else prefix <- .gettext("Warning : ")

					msg <- paste(prefix, msg, "\n", sep="")
					cat(msg)

				}
			},
			interrupt = function (i) cat(.gettext("<INTERRUPTED!>\n"))
			# this is modified code from base::try
			, error = function(e) {
				call <- conditionCall(e)
				msg <- conditionMessage(e)

				## Patch up the call to produce nicer result for testing as
				## try(stop(...)).  This will need adjusting if the
				## implementation of tryCatch changes.
				## Use identical() since call[[1]] can be non-atomic.
				if (!is.null(call) && identical(call[[1]], quote(eval.with.vis)))
					call <- NULL
				if (!is.null(call)) {
					dcall <- deparse(call)[1]
					prefix <- paste(.gettext("Error in"), dcall, ": ")
					sm <- strsplit(msg, "\n")[[1]]
					if (nchar(dcall, type="w") + nchar(sm[1], type="w") > 61) # to match value in errors.c
						prefix <- paste(prefix, "\n  ", sep = "")
				} else prefix <- .gettext("Error : ")

				msg <- paste(prefix, msg, "\n", sep="")
				## Store the error message for legacy uses of try() with
				## geterrmessage().
				.Internal(seterrmessage(msg[1]))
				if (identical(getOption("show.error.messages"), TRUE)) {
					cat(msg)
				}
			}
		), silent = TRUE)
		# Possibly add 'last.warning' as attribute to res
		if (exists("warns", envir = TempEnv())) {
			warns <- get("warns", envir = TempEnv())

			# reshape the warning list
			last.warning <- lapply(warns, "[[", "call")
			names(last.warning) <- sapply(warns, "[[", "message")

			attr(res, "last.warning") <- last.warning
			rm("warns", envir = TempEnv())
		}
		return(res)
	}

	# This is my function to display delayed warnings
	WarningMessage <- function (last.warning) {
		assign("last.warning", last.warning, envir = baseenv())
		n.warn <- length(last.warning)
		if (n.warn < 11) {	# If less than 11 warnings, print them
			# For reasons I don't know, R append a white space to the warning
			# messages... we replicate this behaviour here
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

	# This is not necessary anymore, since errors are printed by error handler:
	#{{
	#
	#   		# Rework the error message if occurring in calling env
	#		mess <- unclass(tmp)
	#		# if (regexpr("eval\\.with\\.vis[(]Expr, myEvalEnv\\.\\., baseenv[(][)][)]", # strange regexp?
	#		# this is simplier
	#		if (regexpr(callFromEvalEnv, mess, fixed = TRUE) > 0)
	#			mess <- sub("^[^:]+: *(\n *\t*| *\t*)", .gettext("Error: "), mess)
	#		cat(mess)
	#}}


			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning)) {
				cat(.gettext("In addition: "))
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

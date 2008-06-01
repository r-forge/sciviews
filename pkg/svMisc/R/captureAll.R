"captureAll" <-
function (expr) {
    # capture.all() is inspired from capture.output(), but it captures
	# both the output and the message streams
	rval <- NULL    # Just to avoid a note during code analysis
    file <- textConnection("rval", "w", local = TRUE)
    sink(file, type = "output")
    sink(file, type = "message")
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
        sink(type = "message")
        close(file)
        try(rm("warning", envir = TempEnv()), silent = TRUE)
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
		myEvalEnv.. <- .GlobalEnv
		res <- try(withCallingHandlers(.Internal(eval.with.vis(Expr,
			myEvalEnv.., baseenv())),
			warning = function (w) {
				Mes <- conditionMessage(w)
				# Possibly truncate it
				wl <- getOption("warning.length")
				if (is.null(wl)) wl <- 1000 # Default value
				if (nchar(Mes) > wl) Mes <- paste(substr(Mes, 1, wl),
					.gettext("[... truncated]"))   #  [... truncated] not in it?
				Call <- conditionCall(w)
				# Result depends upon 'warn'
				Warn <- getOption("warn")
				w <<- Warn
				if (Warn < 0) { # Do nothing!
					return()
				} else if (Warn == 0) { # Delayed display of warnings
					if (exists("warns", envir = TempEnv())) {
						lwarn <- get("warns", envir = TempEnv())
					} else lwarn <- list()
					# Do not add more than 50 warnings
					if (length(lwarn) >= 50) return()
					# Add the warning to this list
					nwarn <- length(lwarn)
					names.warn <- names(lwarn)
					# If warning generated in eval environment,
					# put it as character(0)
					if (Call == "eval.with.vis(Expr, myEvalEnv.., baseenv())")
						Call <- character(0)
					lwarn[[nwarn + 1]] <- Call
					names(lwarn) <- c(names.warn, Mes)
					# Save the modified version in TempEnv()
					assign("warns", lwarn, envir = TempEnv())
					return()
				} else if (Warn > 1) { # Generate an error!                    
					Mes <- .gettextf("(converted from warning) %s", Mes)
					stop(simpleError(Mes, call = Call))
				} else { # Print the warning message immediately
					# Format the warning message
					# If warning generated in eval environment do not print call	
					if (Call == "eval.with.vis(Expr, myEvalEnv.., baseenv())") {
						cat(.gettextf("Warning: %s\n", Mes))
					} else {
						if (nchar(Call) + nchar(Mes) < 58) {
							cat(.gettextf("Warning in %s : %s\n",
							as.character(Call), Mes))
						} else {
							cat(.gettextf("Warning in %s :\n  %s\n",
								as.character(Call), Mes))
						}
					}
				}
			},
			interrupt = function (i) cat(gettext("<INTERRUPTED!>\n"))
		), silent = TRUE)
		# Possibly add 'last.warning' as attribute to res
		if (exists("warns", envir = TempEnv())) {
			attr(res, "last.warning") <- get("warns", envir = TempEnv())
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
            print(warnings(" ", sep = ""))
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
       	    # Rework the error message if occurring in calling env
            mess <- unclass(tmp)
            if (regexpr("eval\\.with\\.vis[(]Expr, myEvalEnv\\.\\., baseenv[(][)][)]",
                mess) > 0)
				mess <- sub("^[^:]+: *(\n *\t*| *\t*)", .gettext("Error: "), mess)
            cat(mess)
			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning)) {
				cat(.gettext("In addition: "))
				WarningMessage(last.warning)
			}
            break
       	} else {	 # No error
            if (tmp$visible) print(tmp$value)
			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning)) WarningMessage(last.warning)
		}		
    }
    cat("\n")   # In case last line does not end with \n, I add it!
    return(rval)
}

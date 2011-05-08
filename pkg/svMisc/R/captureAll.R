# inspired by 'capture.output' and utils:::.try_silent
# Requires: R >= 2.13.0 [??]
`captureAll` <- function(expr, split = FALSE, file = NULL) {
	# TODO: support for 'file' and 'split'

	last.warning <- list()
	Traceback <- list()
	warnLevel <- getOption('warn')
	Nframe <- sys.nframe() # frame of reference (used in traceback)

	rval <- NULL
	tconn <- textConnection("rval", "w", local = TRUE)
	sink(tconn, type = "output"); sink(tconn, type = "message")
	on.exit({
		sink(type = "message"); sink(type = "output")
		close(tconn)
	})

	`evalVis` <- function(x) withVisible(eval(x, .GlobalEnv))

	`restartError` <- function(e, calls) {
		# remove call (eval(expr, envir, enclos)) from the message
		ncls <- length(calls)
		nn <- Nframe + 22
		if(isTRUE(all.equal(calls[[nn]], e$call, check.attributes=FALSE)))
			e$call <- NULL

		Traceback <<- rev(calls[-c(seq.int(nn), (ncls - 1L):ncls)])
		cat(.makeMessage(e))
		if(warnLevel == 0L && length(last.warning) > 0L)
			cat(gettext("In addition: ", domain="R"))
	}

	res <- tryCatch(withRestarts(withCallingHandlers({
			# TODO: allow for multiple expressions and calls (like in
			# 'capture.output'). The problem here is how to tell 'expression'
			# from 'call' without evaluating it?
			list(evalVis(expr))
		},

		error = function(e) invokeRestart("grmbl", e, sys.calls()),
		warning = function(e) {
			# remove call (eval(expr, envir, enclos)) from the message
			nn <- Nframe + 22
			if(isTRUE(all.equal(sys.call(nn), e$call, check.attributes=FALSE)))
				e$call <- NULL

			last.warning <<- c(last.warning, structure(list(e$call), names=e$message))

			if(warnLevel != 0L) {
				.Internal(.signalCondition(e, conditionMessage(e), conditionCall(e)))
				.Internal(.dfltWarn(conditionMessage(e), conditionCall(e)))
			}
			invokeRestart("muffleWarning")

		}),
	# Restarts:

	# Handling user interrupts. Currently it works only from within R.
	#TODO: how to trigger interrupt via socket connection?
	abort = function(...) {
		cat("<aborted!>\n") #DEBUG
	},

	interrupt = function(...) cat("<interrupted!>\n"), #DEBUG: this does not seem to be ever called.

	muffleWarning = function() NULL,
	grmbl = restartError),
	error = function(e) {
		#XXX: this is called by warnLevel=2
		cat(.makeMessage(e))
		e #identity
	},
	finally = {	}
	)

	lapply(res, function(x) {
		if(inherits(x, "list") && x$visible) {
			print(x$value)
		} #else { cat('<invisible>\n') }
	})

	if(warnLevel == 0) {
		nwarn <- length(last.warning)
		assign("last.warning", last.warning, envir=baseenv())
		if(nwarn <= 10) {
			print.warnings(last.warning)
		} else if (nwarn < 50) {
		   cat(gettextf("There were %d warnings (use warnings() to see them)\n", nwarn, domain="R"))
		} else {
			cat(gettext("There were 50 or more warnings (use warnings() to see the first 50)\n", domain="R"))
		}
	}

	sink(type = "message"); sink(type = "output")
	close(tconn)
	on.exit()

	# allow for tracebacks of this call stack:
	assign(".Traceback", lapply(Traceback, deparse), envir = baseenv())

	return(rval)
}

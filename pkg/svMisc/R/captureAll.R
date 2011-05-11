# inspired by 'capture.output' and utils:::.try_silent
# Requires: R >= 2.13.0 [??]
`captureAll` <- function(expr, split = FALSE, file = NULL, markStdErr=FALSE) {
	# TODO: support for 'file' and 'split'

	# markStdErr: if TRUE, stderr is separated from sddout by STX/ETX character

	last.warning <- list()
	Traceback <- list()
	NframeOffset <- sys.nframe() + 20L # frame of reference (used in traceback) +
								 # length of the call stack when a condition
								 # occurs
	# Note: if 'expr' is a call not expression, 'NframeOffset' is lower by 2
	# (i.e. 21): -1 for lapply, -1 for unwrapping 'expression()'

	getWarnLev <- function() options('warn')[[1L]] # this may change in course of
		# evaluation, so must be retrieved dynamically

	rval <- NULL
	tconn <- textConnection("rval", "w", local = TRUE)
	sink(tconn, type = "output"); sink(tconn, type = "message")
	on.exit({
		sink(type = "message"); sink(type = "output")
		close(tconn)
	})

	inStdOut <- TRUE

	if (markStdErr) {
		putMark <- function(to.stdout, id) {
			if (inStdOut) {
				if (!to.stdout) {
					cat("\x03")
					inStdOut <<- FALSE
			}} else { # in StdErr stream
				if (to.stdout) {
					cat("\x02")
					inStdOut <<- TRUE
			}}
			#cat("<", id, inStdOut, ">")
		}
	} else {
		putMark <- function(to.stdout, id) {}
	}

	`evalVis` <- function(x) withVisible(eval(x, .GlobalEnv))

	`restartError` <- function(e, calls) {
		# remove call (eval(expr, envir, enclos)) from the message
		ncls <- length(calls)

		cat("n calls: ", ncls, "NframeOffset: ", NframeOffset, "\n")


		if(isTRUE(all.equal(calls[[NframeOffset]], e$call, check.attributes=FALSE)))
			e$call <- NULL

		Traceback <<- rev(calls[-c(seq.int(NframeOffset), (ncls - 1L):ncls)])

#> cat(captureAll(expression(1:10, log(-1),log(""),1:10)), sep="\n")
#Error in calls[[NframeOffset]]: subscript out of bounds
#Warning message:
#In log(-1) : NaNs produced


		putMark(FALSE, 1)
		cat(.makeMessage(e))
		if(getWarnLev() == 0L && length(last.warning) > 0L)
			cat(gettext("In addition: ", domain="R"))
	}

	res <- tryCatch(withRestarts(withCallingHandlers({
			# TODO: allow for multiple expressions and calls (like in
			# 'capture.output'). The problem here is how to tell 'expression'
			# from 'call' without evaluating it?
			#list(evalVis(expr))
			lapply(expr, evalVis)
		},

		error = function(e) invokeRestart("grmbl", e, sys.calls()),
		warning = function(e) {
			# remove call (eval(expr, envir, enclos)) from the message
			if(isTRUE(all.equal(sys.call(NframeOffset), e$call, check.attributes=FALSE)))
				e$call <- NULL

			last.warning <<- c(last.warning, structure(list(e$call), names=e$message))

			if(getWarnLev() != 0L) {
				putMark(FALSE, 2)
				.Internal(.signalCondition(e, conditionMessage(e), conditionCall(e)))
				.Internal(.dfltWarn(conditionMessage(e), conditionCall(e)))
				putMark(TRUE, 3)
			}
			invokeRestart("muffleWarning")

		}),
	# Restarts:

	# Handling user interrupts. Currently it works only from within R.
	#TODO: how to trigger interrupt via socket connection?
	abort = function(...) {
		putMark(FALSE, 4)
		cat("<aborted!>\n") #DEBUG
	},

	#interrupt = function(...) cat("<interrupted!>\n"), #DEBUG: this does not seem to be ever called.

	muffleWarning = function() NULL,
	grmbl = restartError),
	error = function(e) { #XXX: this is called if warnLevel=2
		putMark(FALSE, 5)
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

	if(getWarnLev() == 0L) {
		nwarn <- length(last.warning)
		assign("last.warning", last.warning, envir=baseenv())

		if(nwarn > 0L) putMark(FALSE, 6)
		if(nwarn <= 10L) {
			print.warnings(last.warning)
		} else if (nwarn < 50L) {
		   cat(gettextf("There were %d warnings (use warnings() to see them)\n", nwarn, domain="R"))
		} else {
			cat(gettext("There were 50 or more warnings (use warnings() to see the first 50)\n", domain="R"))
		}
	}

	putMark(TRUE, 7)

	sink(type = "message"); sink(type = "output")
	close(tconn)
	on.exit()

	# allow for tracebacks of this call stack:
	assign(".Traceback", lapply(Traceback, deparse), envir = baseenv())

	return(rval)
}

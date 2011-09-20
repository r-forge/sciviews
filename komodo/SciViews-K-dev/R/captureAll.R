# replacement for 'base::as.character.error', which does not translate "Error"
`as.character.error` <- function (x, ...) {
    msg <- conditionMessage(x)
    call <- conditionCall(x)
    if (!is.null(call))
		paste(.gettextx("Error in "), deparse(call, control = NULL)[1L], ": ",
			msg, "\n", sep = "")
    else paste(.gettextx("Error: "), msg, "\n", sep = "")
}


# use ngettext instead of gettext, which fails to translate many strings in "R" domain
# bug in R or a weird feature?
`.gettextfx` <- function (fmt, ..., domain = "R")
sprintf(ngettext(1, fmt, "", domain = domain), ...)

`.gettextx` <- function (..., domain = "R") {
    args <- lapply(list(...), as.character)
	 unlist(lapply(unlist(args), function(x) .Internal(ngettext(1, x, "", domain))))
}

# inspired by 'capture.output' and utils:::.try_silent
# Requires: R >= 2.13.0 [??]
`captureAll` <- function(expr, split = FALSE, file = NULL, markStdErr=FALSE) {
	# TODO: support for 'file' and 'split'

	# markStdErr: if TRUE, stderr is separated from sddout by STX/ETX character

	last.warning <- list()
	Traceback <- NULL
	NframeOffset <- sys.nframe() + 19L # frame of reference (used in traceback) +
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
			do.mark <- FALSE
			if (inStdOut) {
				if (!to.stdout) {
					cat("\x03")
					inStdOut <<- FALSE
					do.mark <- TRUE
			}} else { # in StdErr stream
				if (to.stdout) {
					cat("\x02")
					inStdOut <<- TRUE
					do.mark <- TRUE
			}}

			#if(do.mark)
			#marks <<- c(marks, list(c(pos = sum(nchar(rval)), stream = to.stdout)))
			#cat("<", id, inStdOut, ">")
		}
	} else {
		putMark <- function(to.stdout, id) {}
	}

	`evalVis` <- function(x) withVisible(eval(x, .GlobalEnv))

	`restartError` <- function(e, calls, foffset) {
		# remove call (eval(expr, envir, enclos)) from the message
		ncls <- length(calls)

		#if(existsTemp("debugTest") && getTemp("debugTest"))		browser()
		#cat("frame offset =", foffset, "\n")

		if(isTRUE(all.equal(calls[[NframeOffset + foffset]], e$call, check.attributes=FALSE)))
			e$call <- NULL
		Traceback <<- rev(calls[-c(seq.int(NframeOffset + foffset), (ncls - 1L):ncls)])

		putMark(FALSE, 1L)
		#cat(.makeMessage(e, domain="R"))
		cat(as.character.error(e))
		if(getWarnLev() == 0L && length(last.warning) > 0L)
			cat(.gettextx("In addition: "))
	}

	res <- tryCatch(withRestarts(withCallingHandlers({
			# TODO: allow for multiple expressions and calls (like in
			# 'capture.output'). The problem here is how to tell 'expression'
			# from 'call' without evaluating it?
			off <- 0L

			for(i in expr) {
				# 'off' is passed to 'restartError'
				off <- 0L # TODO: better way to find the right sys.call...
				res1 <- evalVis(i)
				off <- -2L
				if(res1$visible) {
					#(if(isS4(res1$value)) show else print)(res1$value)
					# print/show should be evaluated also in .GlobalEnv
					do.call("eval", list(call(if(isS4(res1$value)) "show"
						else "print", res1$value)), envir=.GlobalEnv)
				}
			}
		},

		error = function(e) invokeRestart("grmbl", e, sys.calls(), off),
		warning = function(e) {
			# remove call (eval(expr, envir, enclos)) from the message
			if(isTRUE(all.equal(sys.call(NframeOffset), e$call, check.attributes=FALSE)))
				e$call <- NULL

			last.warning <<- c(last.warning, structure(list(e$call), names=e$message))

			if(getWarnLev() != 0L) {
				putMark(FALSE, 2L)
				.Internal(.signalCondition(e, conditionMessage(e), conditionCall(e)))
				.Internal(.dfltWarn(conditionMessage(e), conditionCall(e)))
				putMark(TRUE, 3L)
			}
			invokeRestart("muffleWarning")

		}),
	# Restarts:

	# Handling user interrupts. Currently it works only from within R.
	# TODO: how to trigger interrupt remotely?
	abort = function(...) {
		putMark(FALSE, 4L)
		cat("Execution aborted. \n") #DEBUG
	},

	muffleWarning = function() NULL,
	grmbl = restartError),
	error = function(e) { #XXX: this is called if warnLevel=2
		putMark(FALSE, 5L)
		cat(as.character.error(e))
		e #identity
	}, finally = {	}
	)

	if(getWarnLev() == 0L) {
		nwarn <- length(last.warning)
		assign("last.warning", last.warning, envir=baseenv())

		if(nwarn > 0L) putMark(FALSE, 6L)
		if(nwarn <= 10L) {
			print.warnings(last.warning)
		} else if (nwarn < 50L) {
		   cat(.gettextfx("There were %d warnings (use warnings() to see them)\n", nwarn))
		} else {
			cat(.gettextx("There were 50 or more warnings (use warnings() to see the first 50)\n"))
		}
	}
	putMark(TRUE, 7L)

	sink(type = "message"); sink(type = "output")
	close(tconn)
	on.exit()

	#filename <- attr(attr(sys.function(sys.parent()), "srcref"), "srcfile")$filename

	# allow for tracebacks of this call stack:
	if(!is.null(Traceback)) {
		assign(".Traceback",
			#if (is.null(filename)) {
				#lapply(Traceback, deparse, control=NULL)
				# keep only 'srcref' attribute
				lapply(Traceback,  function(x) structure(deparse(x, control=NULL), srcref=attr(x, "srcref")))

			#} else {
			#	lapply(Traceback, function(x) {
			#		srcref <- attr(x, "srcref")
			#		srcfile <- if(is.null(srcref)) NULL else attr(srcref, "srcfile")
			#		structure(deparse(x, control=NULL), srcref =
			#			if(is.null(srcfile) || srcfile$filename == filename) NULL else srcref)
			#	})
			#}
			, envir = baseenv())
	}
	return(rval)
}

attr(captureAll, "srcref") <- NULL


# TESTS:
# cat(captureAll(expression(1:10, log(-1),log(""),1:10)), sep="\n")

# foo <- structure(list(a=1, b=2), class="foo")
# print.foo <- function(x, ...) stop("Foo print error!")
# captureAll(expression(foo))
# traceback()
# captureAll(expression(print(foo)))
# traceback()
# foo
# print(foo)

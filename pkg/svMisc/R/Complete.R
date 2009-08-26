"Complete" <-
function (code, print = FALSE, types = c("default", "scintilla"),
addition = FALSE, skip.used.args = TRUE, sep = "\n", type.sep = "?") {
	ComplEnv <- utils:::.CompletionEnv

	finalize <- function (completions) {
		if (add.types) {
			tl <- numeric(length(completions))
			tl[grep(" = $", completions)] <- 4L
			tl[grep("::$", completions)] <- 3L
			tl[grep("<-$", completions)] <- 1L
			tl[completions %in% .reserved.words] <- 5L
			i <- !tl
			tl[i] <- ifelse(sapply(completions[i],
				function(x) existsFunction(x)), 1L, 2L)
			tl <- factor(tl, levels = 1:5, labels = types)
			ret <- data.frame(completion = completions, type = tl)
		} else {
			ret <- completions
		}

		attr(ret, "token") <- token
		attr(ret, "triggerPos") <- triggerPos
		attr(ret, "fguess") <- fguess
		attr(ret, "funargs") <- funargs
		attr(ret, "isFirstArg") <- isFirstArg

		if (print) {
			if (add.types)
				completions <- paste(completions, tl, sep = type.sep)
			cat(triggerPos, completions, sep = sep)
			if (sep != "\n") cat("\n")
			return(invisible(ret))
		} else {
			return(ret)
		}
	}

	if (is.character(types[1L])) {
		types <- switch(match.arg(types),
			default = .default.completion.types,
			scintilla = .scintilla.completion.types,
			.default.completion.types)
	}
	add.types <- !is.na(types[1L])

	# Default values for completion context
	token <- ""
	triggerPos <- 0L
	fguess <- ""
	funargs <- list()
	isFirstArg <- FALSE

	# Is there some code provided?
	code <- paste(as.character(code), collapse = "\n")
	if (is.null(code) || !length(code) || code == "") {
		# Just return a list of objects in .GlobalEnv
		return(finalize(ls(envir = .GlobalEnv)))
	}

	# If code ends with a single [, then nothing to return
	if (regexpr("[^[][[]$", code) > 0)
		return(invisible(""))

	# If code ends with a double [[, then, substitute $ instead and indicate
	# to quote returned arguments (otherwise, [[ is not correctly handled)!
	if (regexpr("[[][[]$", code) > 0) {
		code <- sub("[[][[]$", "$", code)
		dblBrackets <- TRUE
	} else dblBrackets <- FALSE

	# Save funarg.suffix and use " = " temporarily
	opts <- ComplEnv$options
	funarg.suffix <- opts$funarg.suffix
	on.exit({
		opts$funarg.suffix <- funarg.suffix
		ComplEnv$options <- opts
	})
	opts$funarg.suffix <- " = "
	ComplEnv$options <- opts

	utils:::.assignLinebuffer(code)
	pos <- nchar(code, type = "chars")
	utils:::.assignEnd(pos)
	utils:::.guessTokenFromLine()
	#utils:::.completeToken()
	.completeTokenExt()

	completions <- utils:::.retrieveCompletions()

	triggerPos <- pos - ComplEnv[["start"]]
	token <- ComplEnv[["token"]]

	# If token is empty, we complete by using objects in .GlobalEnv by default
	if (!length(completions) && token == "") {
		triggerPos <- nchar(code, type = "chars")
		return(finalize(ls(envir = .GlobalEnv)))
	}

    # From CompletePlus() for a similar behaviour
	# For tokens like "a[m", the actual token should be "m"
    # completions are modified accordingly
    rx <- regexpr("[[]+", ComplEnv$token)
    if (rx > 0) {
    	# then we need to trim out whatever is before the [ in the completion
    	# and the token
    	start <- rx + attr(rx, "match.length")
    	ComplEnv$token <- substring(ComplEnv$token, start)
    	completions <- substring(completions, start)
    }
	if (!length(completions)) return(invisible(""))

	# remove weird object names (useful when the token starts with ".")
    # line below causes error on ubuntu: could not find function "grepl". older R version?
	#completions <- completions[!grepl("^[.]__[[:alpha:]]__", completions)]
    i <- grep("^[.]__[[:alpha:]]__", completions)
	if (length(i) > 0)
		completions <- completions[-i]

    if (!length(completions)) return(invisible(""))

	fguess <- ComplEnv$fguess

	if (skip.used.args && length(fguess) && nchar(fguess))
		completions <- completions[!(completions %in% ComplEnv$funargs)]
	if (!length(completions)) return(invisible(""))

	i <- grep("<-.+$", completions)
	if (length(i) > 0)
		completions <- completions[-i]

	if (addition && triggerPos > 0L)
		completions <- substring(completions, triggerPos + 1)

	if (dblBrackets) {
		# Substitute var$name by var[["name"
		completions <- sub("[$](.+)$", '[["\\1"', completions)
		token <- sub("[$]$", "[[", token)
		triggerPos <- triggerPos + 1
	}
	fguess <- ComplEnv$fguess
	funargs <- ComplEnv$funargs
	isFirstArg <- ComplEnv$isFirstArg
	return(finalize(completions))
}

.reserved.words <- c("if", "else", "repeat", "while", "function", "for", "in",
					  "next", "break", "TRUE", "FALSE", "NULL", "Inf", "NaN",
					  "NA", "NA_integer_", "NA_real_", "NA_complex_",
					  "NA_character_")

.default.completion.types <- list(fun = "function",
								  var = "variable",
								  env = "environment",
								  args = "arg",
								  keyword = "keyword")

.scintilla.completion.types <- list(fun = "1",
									var = "3",
									env = "8",
									args = "11",
									keyword = "13")

# modified utils:::inFunction()
# The only difference is that it also gets current arguments list (if applicable).
# They are assigned to utils:::.CompletionEnv$funargs
.inFunctionExt <-
function (line = utils:::.CompletionEnv[["linebuffer"]],
cursor = utils:::.CompletionEnv[["start"]])
{
	parens <- sapply(c("(", ")"), function(s)
		gregexpr(s, substr(line, 1L, cursor), fixed = TRUE)[[1L]],
			simplify = FALSE)
	parens <- lapply(parens, function(x) x[x > 0])
	temp <- data.frame(i = c(parens[["("]], parens[[")"]]),
		c = rep(c(1, -1), sapply(parens, length)))
	if (nrow(temp) == 0)
		return(character(0L))
	temp <- temp[order(-temp$i), , drop = FALSE]
	wp <- which(cumsum(temp$c) > 0)
	if (length(wp)) {
		index <- temp$i[wp[1L]]
		prefix <- substr(line, 1L, index - 1L)
		suffix <- substr(line, index + 1L, cursor + 1L)
		if ((length(grep("=", suffix, fixed = TRUE)) == 0L) &&
			(length(grep(",", suffix, fixed = TRUE)) == 0L))
			utils:::setIsFirstArg(v = TRUE)
		if ((length(grep("=", suffix, fixed = TRUE))) && (length(grep(",",
			substr(suffix, tail(gregexpr("=", suffix, fixed = TRUE)[[1L]],
			1L), 1000000L), fixed = TRUE)) == 0L)) {
			return(character(0L))
		} else {

			# This is the code added to utils:::inFunction()
			wp2 <- rev(cumsum(temp$c[-(wp[1L]:nrow(temp))]))
			suffix <- sub("^\\s+", "", suffix, perl = TRUE)
			# TODO: simplify this:
			if (length(wp2)) {
				funargs <- strsplit(suffix,	"\\s*[\\(\\)][\\s,]*", perl = TRUE)[[1]]
				funargs <- paste(funargs[wp2 == 0], collapse = ",")
			} else {
				funargs <- suffix
			}
			funargs <- strsplit(funargs, "\\s*,\\s*", perl=TRUE)[[1]]
			funargs <- unname(sapply(funargs, sub, pattern = "\\s*=.*$",
				replacement = utils:::.CompletionEnv$options$funarg.suffix, perl=TRUE))
			assign("funargs", funargs, utils:::.CompletionEnv)
			# ... addition ends here

			possible <- suppressWarnings(strsplit(prefix, utils:::breakRE,
				perl = TRUE))[[1L]]
			possible <- possible[possible != ""]
			if (length(possible)) {
				return(tail(possible, 1))
			} else {
				return(character(0L))
			}
		}
	} else {
		return(character(0L))
	}
}

# modified utils:::.completeToken()
# main difference is that calls .inFunctionExt instead of utils:::inFunction.
.completeTokenExt <- function () {
	ComplEnv <- utils:::.CompletionEnv
	text <- ComplEnv$token
	linebuffer <- ComplEnv$linebuffer
	st <- ComplEnv$start

	if (utils:::isInsideQuotes()) {
		probablyNotFilename <- (st > 2L &&
			(substr(linebuffer, st - 1L, st - 1L) %in% c("[", ":", "$")))
		if (ComplEnv$settings[["files"]]) {
			if (probablyNotFilename) {
				ComplEnv[["comps"]] <- character(0L)
			} else {
				ComplEnv[["comps"]] <- utils:::fileCompletions(text)
			}
			utils:::.setFileComp(FALSE)
		} else {
			ComplEnv[["comps"]] <- character(0L)
			utils:::.setFileComp(TRUE)
		}
	} else {

		#Completion does not a good job when there are quoted strings,
		# e.g for linebuffer = "Complete2("anova(", )" would give arguments for anova
		# rather than for Complete2.
		# Code below replaces quoted strings with sequences of "_" of the same length.
		# This is a temporary solution though, there should be a better way...
		mt <- gregexpr('(?<!\\\\)(["\']).*?((?<!\\\\)\\1|$)', linebuffer,
			perl = TRUE)[[1]]
		if (mt[1L] != -1) {
			ml <- attr(mt, "match.length")
			y <- sapply(lapply(ml, rep, x = "a"), paste, collapse = "")
			for (i in seq_along(mt))
				substr(linebuffer, mt[i], mt[i] + ml[i]) <- y[i]
		}
		# ... additions until here

		utils:::.setFileComp(FALSE)
		utils:::setIsFirstArg(FALSE)
		guessedFunction <- ""
		if (ComplEnv$settings[["args"]]) {
			# Call of .inFunctionExt() instead of utils:::inFunction()
			guessedFunction <- .inFunctionExt(linebuffer, st)
		} else {
			guessedFunction <- ""
		}

		assign("fguess", guessedFunction, ComplEnv)
		fargComps <- utils:::functionArgs(guessedFunction, text)

		if (utils:::getIsFirstArg() && length(guessedFunction) &&
			guessedFunction %in% c("library", "require", "data")) {
			assign("comps", fargComps, ComplEnv)
			return()
		}
		lastArithOp <- tail(gregexpr("[\"'^/*+-]", text)[[1L]], 1)
		if (haveArithOp <- (lastArithOp > 0)) {
			prefix <- substr(text, 1L, lastArithOp)
			text <- substr(text, lastArithOp + 1L, 1000000L)
		}
		spl <- utils:::specialOpLocs(text)
		if (length(spl)) {
			comps <- utils:::specialCompletions(text, spl)
		} else {
			appendFunctionSuffix <- !any(guessedFunction %in%
				c("help", "args", "formals", "example", "do.call",
				"environment", "page", "apply", "sapply", "lapply",
				"tapply", "mapply", "methods", "fix", "edit"))
			comps <- utils:::normalCompletions(text,
				check.mode = appendFunctionSuffix)
		}
		if (haveArithOp && length(comps))
			comps <- paste(prefix, comps, sep = "")
		comps <- c(comps, fargComps)
		assign("comps", comps,  ComplEnv)
	}
}

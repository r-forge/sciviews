# 'getFunArgs': returns function argument names, if 'object' is provided and 'f'
#    is generic (either S3 or S4), returns only arguments for an appropriate
#    method and/or default method if not found.
# Usage:
#    getFunArgs("anova", fm1) # if fm1 is glm returns argument names for 'anova.glm'

# "imports":
tail <- utils::tail
getS3method <- utils::getS3method
findGeneric <- utils:::findGeneric

`getFunArgs` <- function(FUNC.NAME, ...) {
	rx <- regexpr("^([\\w\\.]+):{2,3}(`|)([\\w\\.]+)\\2$", FUNC.NAME, perl = TRUE)
	if (rx == 1L) {
		cs <- attr(rx,"capture.start")
		fn <- substring(FUNC.NAME, cs, cs - 1L + attr(rx,"capture.length"))[c(1,3)]
		FUNC.NAME <- fn[2L]
		envir <- asNamespace(fn[1L])
		inherit <- FALSE
	} else {
		envir <- .GlobalEnv
		inherit <- TRUE
	}

	if(exists(FUNC.NAME, envir = envir, mode = "function", inherits = inherit)) {
		fun <- get(FUNC.NAME, envir = envir, mode = "function", inherits = inherit)
	} else
		fun <- NULL

	if(is.null(fun) || mode(fun) != "function") return(NULL)
	if (findGeneric(FUNC.NAME, envir) != "" || is.primitive(fun)) {
		cl <- sys.call()
		cls <- NA_character_
		if(length(cl) > 2L){
			object <- cl[[3L]]
			if(mode(object) == "call") {
				if ("~" %in% all.names(object, functions = TRUE, max.names = 4L))
					cls <- "formula"
			} else {
				object <- tryCatch(eval(object), error = function(e) NULL)
				cls <- class(object)
			}
		}

		if(is.na(cls)) {
			ret <- names(formals(getS3method(FUNC.NAME, "default",
				optional = TRUE)))
		} else {
			ncls <- length(cls)
			ret <- vector(ncls + 2L, mode = "list")
			if(isS4(object)) ret[[1L]] <- formals(selectMethod(FUNC.NAME, cls,
				optional = TRUE))
			ret[seq_len(ncls)] <- lapply(cls, function(x)
				names(formals(getS3method(FUNC.NAME, x, optional = TRUE))))
			if(all(vapply(ret, is.null, TRUE)))
				ret <- names(formals(getS3method(FUNC.NAME, "default",
					optional = TRUE)))
			else
				ret <- unique(unlist(ret, FALSE, FALSE))
		}
	} else ret <- character(0L)
	ret <- unique(c(ret, names(formals(fun))))
	if (length(ret) > 1L && (FUNC.NAME == "[" || FUNC.NAME == "[["))
		ret <- ret[-1L]
	return(ret[ret != "..."])
}

# provide special completions
`completeSpecial` <- function(what) {
	res <- switch(what, search = {
			res <- search()
			res[!(res %in%  c(".GlobalEnv", "package:tcltk", "package:utils", "komodoConnection",
				"package:methods", "TempEnv", "Autoloads", "package:base"))]
	   }, library = {
			res <- unique(unlist(lapply(.libPaths(), dir), use.names = FALSE))
	   }, return(invisible(NULL)))
	cat(res, sep='\n')
	return(invisible(NULL))
}




# From svMisc::completion (simpllified)

`completion` <- function (code, field.sep = "\x1e", sep = "\n",
						  pos = nchar(code), min.length = 2,
						  addition = FALSE, max.fun = 100,
						  skip.used.args = FALSE) {

	types <- list(fun = "function", var = "variable",
		env = "environment", args = "argument", keyword = "keyword")
	finalize <- function (completions) {
		## Construct a data frame with completions
		ret <- data.frame(completion = completions,
			stringsAsFactors = FALSE)
			tl <- numeric(length(completions))
			tl[grep(" = $", completions)] <- 4L
			tl[grep("::$", completions)] <- 3L
			tl[grep("<-$", completions)] <- 1L
			tl[completions %in% .reserved.words] <- 5L
			tl[!tl] <- ifelse(sapply(completions[!tl],
				function(x) exists(x, where = .GlobalEnv, mode = "function")),
							  1L, 2L)
			tl <- factor(tl, levels = seq_len(5L), labels = types)
			ret <- cbind(ret, data.frame(type = tl, stringsAsFactors = FALSE))
			if (is.null(ret$desc)) cat(triggerPos, paste(ret$completion,
				ret$type, sep = field.sep), sep = sep)
			else cat(triggerPos, paste(ret$completion, ret$type, ret$desc,
					ret$context, sep = field.sep), sep = sep)
			invisible(NULL)
	}

	## Default values for completion context
	token <- ""
	triggerPos <- 0L
	fguess <- ""
	funargs <- list()
	isFirstArg <- FALSE

	## Is there some code provided?
	code <- paste(as.character(code), collapse = "\n")
	if (is.null(code) || !length(code) || code == "" ||
		nchar(code, type = "chars") < min.length) {
		## Just return a list of objects in .GlobalEnv
		## TODO: look if we are inside a function and list
		## local variables (code analysis is required!)
		return(finalize(ls(envir = .GlobalEnv)))
	}

	## If code ends with a single [, then look for names in the object
	if (regexpr("[^[][[]$", code) > 0) {
		## TODO: look for object names... currently, return nothing
		return(invisible(""))
	}

	## If code ends with a double [[, then, substitute $ instead and indicate
	## to quote returned arguments (otherwise, [[ is not correctly handled)!
	if (regexpr("[[][[]$", code) > 0) {
		code <- sub("[[][[]$", "$", code)
		dblBrackets <- TRUE
	} else dblBrackets <- FALSE

	## Save funarg.suffix and use " = " locally
	ComplEnv <- utils:::.CompletionEnv

	## Calculate completion with standard R completion tools
	utils:::.assignLinebuffer(code)
	utils:::.assignEnd(pos)
	utils:::.guessTokenFromLine()
	## The standard utils:::.completeToken() is replaced by our own version:
	.completeTokenExt()
	completions <- utils:::.retrieveCompletions()
	triggerPos <- pos - ComplEnv[["start"]]
	token <- ComplEnv[["token"]]

	## For tokens like "a[m", the actual token should be "m"
    ## completions are modified accordingly
    rx <- regexpr("[[]+", ComplEnv$token)
    if (rx > 0) {
    	## Then we need to trim out whatever is before the [ in the completion
    	## and the token
    	start <- rx + attr(rx, "match.length")
    	ComplEnv$token <- substring(ComplEnv$token, start)
    	completions <- substring(completions, start)
    }
	if (!length(completions)) return(invisible(""))

	## Remove weird object names (useful when the token starts with ".")
    i <- grep("^[.]__[[:alpha:]]__", completions)
	if (length(i) > 0) completions <- completions[-i]
    if (!length(completions)) return(invisible(""))

	## Eliminate function arguments that are already used
	fguess <- ComplEnv$fguess
	if (skip.used.args && length(fguess) && nchar(fguess))
		completions <- completions[!(completions %in% ComplEnv$funargs)]
	if (!length(completions)) return(invisible(""))

	## Eliminate function names like `names<-`
	i <- grep("<-.+$", completions)
	if (length(i) > 0L) completions <- completions[-i]

	## Do we return only additional strings for the completion?
	if (isTRUE(addition) && triggerPos > 0L)
		completions <- substring(completions, triggerPos + 1L)

	## In case of [[, restore original code
	if (dblBrackets) {  # Substitute var$name by var[["name"
		completions <- sub("\\$(.+)$", '[["\\1"', completions)
		token <- sub("\\$$", "[[", token)
		triggerPos <- triggerPos + 1L
	}

	## Finalize processing of the completion list
	funargs <- ComplEnv$funargs
	isFirstArg <- ComplEnv$isFirstArg
	return(finalize(completions))
}

.reserved.words <- c("if", "else", "repeat", "while", "function", "for", "in",
	"next", "break", "TRUE", "FALSE", "NULL", "Inf", "NaN", "NA", "NA_integer_",
	"NA_real_", "NA_complex_", "NA_character_")

## Modified utils:::inFunction()
## (checked equivalent with R 2.11.1)
## The only difference is that it also gets current arguments list (if applicable).
## They are assigned to utils:::.CompletionEnv$funargs
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
			## This is the code added to utils:::inFunction()
			wp2 <- rev(cumsum(temp$c[-(wp[1L]:nrow(temp))]))
			suffix <- sub("^\\s+", "", suffix, perl = TRUE)
			## TODO: simplify this:
			if (length(wp2)) {
				funargs <- strsplit(suffix,	"\\s*[\\(\\)][\\s,]*",
					perl = TRUE)[[1]]
				funargs <- paste(funargs[wp2 == 0], collapse = ",")
			} else {
				funargs <- suffix
			}
			funargs <- strsplit(funargs, "\\s*,\\s*", perl=TRUE)[[1]]
			funargs <- unname(sapply(funargs, sub, pattern = "\\s*=.*$",
				replacement = utils:::.CompletionEnv$options$funarg.suffix,
					perl=TRUE))
			assign("funargs", funargs, utils:::.CompletionEnv)
			## TODO: how to take non named arguments into account too?
			## ... addition ends here

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

## Modified utils:::.completeToken()
## (checked equivalent with R 2.11.1)
## Main difference is that calls .inFunctionExt instead of utils:::inFunction
## and it also makes sure completion is for Complete in 'Complete("anova(", )'!
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

		## Completion does not a good job when there are quoted strings,
		## e.g for linebuffer = "Complete("anova(", )" would give arguments for
		## anova rather than for Complete.
		# Replace quoted strings with sequences of "_" of the same length.
		# This is a temporary solution though, there should be a better way...
		mt <- gregexpr('(?<!\\\\)(["\']).*?((?<!\\\\)\\1|$)', linebuffer,
			perl = TRUE)[[1]]
		if (mt[1L] != -1) {
			ml <- attr(mt, "match.length")
			y <- sapply(lapply(ml, rep, x = "a"), paste, collapse = "")
			for (i in seq_along(mt))
				substr(linebuffer, mt[i], mt[i] + ml[i]) <- y[i]
		}
		## ... additions until here

		utils:::.setFileComp(FALSE)
		utils:::setIsFirstArg(FALSE)
		guessedFunction <- ""
		if (ComplEnv$settings[["args"]]) {
			## Call of .inFunctionExt() instead of utils:::inFunction()
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

## Similar to "find" but `what` can be a vector
## also, this one only searches in packages (position of the search path
## matching '^package:') and only gives one result per what
.find.multiple <- function (what)
{
    stopifnot(is.character(what))
    sp <- grep( "^package:", search(), value = TRUE)
    out <- rep( "" , length(what))
    for (i in sp) {
        ok <- what %in% ls(i, all.names = TRUE) & out == ""
        out[ok] <- i
        if (all(out != "")) break
    }
    names(out) <- what
    return(sub("^package:", "", out))
}

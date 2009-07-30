"CompletePlus" <-
function (linebuffer, cursorPosition = nchar(linebuffer), minlength = 2,
	simplify = FALSE, types = c("arguments", "functions", "packages"))
{
    # PhG: find.multiple() renamed .find.multiple() and moved to svMisc-internal

	# call the rcompgen API to get completions
    if (nchar(linebuffer, type = "chars") < minlength) return(invisible(NULL))
    utils:::.assignLinebuffer(linebuffer)
    utils:::.assignEnd(cursorPosition)
    utils:::.guessTokenFromLine()
    token <- utils:::.CompletionEnv[["token"]]
    utils:::.completeToken()
    comps <- utils:::.retrieveCompletions()
    if (!length(comps)) return(invisible(NULL))
    
    # For tokens like "a[m", the actual yoken should be "m"
    # completions are modified accordingly
    rx <- regexpr( "[[]+", token )
    if( rx > 0 ){
    	# then we need to trim out whatever is before the [ in the completion
    	# and the token
    	start <- rx + attr( rx, "match.length" )
    	token <- substring( token, start )
    	comps <- substring( comps, start )
    }
    
    # remove weird object names ( useful when the token starts with "." ) 
    comps <- comps[ !grepl( "^[.]__[[:alpha:]]__", comps ) ]
    if (!length(comps))
		return(invisible(NULL))

    # restrict the completion for which information is gathered (speed things up)
    if (!"arguments" %in% types)
		comps <- comps[regexpr("=$", comps) < 0]
    if (!length(comps))
		return(invisible(NULL))

    if (!"packages" %in% types)
		comps <- comps[regexpr("::$", comps) < 0]
    if (!length(comps))
		return(invisible(NULL))

    if (!"functions" %in% types)
		comps <- comps[regexpr("(::|=)$", comps) > 0]
    if (!length(comps))
		return(invisible(NULL))

    # build the output structure
    out <- matrix("", nrow = length(comps), ncol = 3)
    out[, 1] <- comps

    # deal with packages (completions ending with ::)
    if (length(test.pack <- grep("::", comps)))
		out[test.pack, 3] <- sapply(sub("::", "", comps[test.pack]),
			packageDescription, fields = "Description")

    # deal with argument completions (ending with =)
    if (length(test.arg <- grep("=", comps))) {
		arg <- sub("=$", "", comps[test.arg])
		fguess <- utils:::.CompletionEnv[["fguess"]]
		pack <- sub( "^package:", "", find(fguess)[1])
		if (pack == ".GlobalEnv") {
			out[test.arg, 3] <- ""
		} else {
			out[test.arg, 2] <- fguess
			out[test.arg, 3] <- descArgs(fguess, arg, pack)
		}
    }

		# deal with completions with "$"
		if (length(test.dollar <- grep("\\$", comps)) ) {
			elements <- comps[test.dollar]
			object <- gsub("\\$.*$", "", comps)[1]
			after <- gsub("^.*\\$", "", comps)
			pack <- .find.multiple(object)
			out[test.dollar, 2] <- pack
			out[test.dollar, 3] <- descData(object, after, package = pack)
		}

		# deal with completions with "@"
		if (length(test.slot <- grep("@", comps))) {
			elements <- comps[test.dollar]
			object <- gsub("@.*$", "", comps)[1]
			slots <- gsub("^.*@", "", comps)
			pack <- .find.multiple(object)
			out[test.dollar, 2] <- pack
			out[test.dollar, 3] <- descSlots(object, slots, package = pack)
		}

		# deal with completions with "["
		if (length(test.square <- grep("\\[", comps))) {
			elements <- comps[test.square]
			out[test.square, 2] <- ""
			out[test.square, 3] <- descSquare(elements, package = pack)
		}

    ### TODO: do not know what to do with these
    test.others <- grep(" ", comps)
    ### TODO: are there other kind of completions I miss here

    # deal with function completions
    test.fun <- setdiff(1:length(comps), c(test.arg, test.pack, test.others,
		test.dollar, test.slot, test.square))
    if (length(test.fun)) {
		funs <- comps[test.fun]
		packs <- .find.multiple(funs)
    	desc.fun <- rep("", length(packs))
		for (pack in unique(packs)) {
			if (!pack %in% c("", ".GlobalEnv")) {
				desc.fun[packs == pack] <- descFun(funs[packs == pack], pack)
			}
		}
		out[test.fun, 2] <- packs
		out[test.fun, 3] <- desc.fun
    }

    out[, 3] <- gsub("\t", "    ", out[, 3])
    out[, 3] <- gsub("\n", " ", out[, 3])

	# Make sure that arguments are witten 'arg = ', and not 'arg='
	out[, 1] <- sub("=$", " = ", out[, 1])
	
	attr( out, "token" ) <- token

	if (simplify) {
		cat(apply(out, 1, paste, collapse = "\t"), sep = "\n")
	} else {
		return(out)
	}
}

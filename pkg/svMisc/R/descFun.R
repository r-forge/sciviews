descFun <-
function (fun, package, lib.loc = NULL) {
	fun <- as.character(fun)
	if (length(fun) == 0) return("")
	# Get the description associated with this Topic
	AllTopics <- eval(parse(text = paste("library(help =", package, ")")))$info[[2]]
	if (length(AllTopics) == 0) return("")
	res <- character()
	for (i in 1:length(fun)) {
		paths <- sapply(.find.package(package, lib.loc, verbose = FALSE),
			function(p) index.search(fun[i], p, "AnIndex", type = "help"))
		# Topic is the entry that contains the description
		Topic <- basename(paths[paths != ""])[1]
		# Get the first line of the description
		FirstLine <- (1:length(AllTopics))[regexpr(paste("^", Topic, " ",
			sep = ""), AllTopics) > -1]
		# If not found, try with fun[i]
		if (length(FirstLine) == 0) {
			Topic <- fun[i]
			FirstLine <- (1:length(AllTopics))[regexpr(paste("^", Topic, " ",
				sep = ""), AllTopics) > -1]
		}
		if (length(FirstLine) == 0) {
			res[i] <- ""	# Not found (should never happen?)
		} else {
			# Eliminate everything before this line
			Topics <- AllTopics[FirstLine[1]:length(AllTopics)]
			# We may have several lines of description: keep them all
			isSpace <- (regexpr("^ ", Topics) == -1)
			isDesc <- (cumsum(isSpace) == 1)
			Topics[1] <- sub(paste("^", Topic, sep = ""), "", Topics[1])
			# Get the description and return it
			res[i] <- paste(sub("^ +", "", Topics[isDesc]), collapse = " ")
		}
	}
	# Add names to this vector and return it
	names(res) <- fun
	return(res)
}

descArgs <-
function (fun, args = NULL, package = NULL, lib.loc = NULL) {
	# Start from the text version of the online help instead of the .Rd file
	if (is.null(package)) {
		File <- as.character(help(fun,
			lib.loc = lib.loc, chmhelp = FALSE, htmlhelp = FALSE))
	} else {
		File <- as.character(help(fun, package = parse(text = package),
			lib.loc = lib.loc, chmhelp = FALSE, htmlhelp = FALSE))
	}
	if (length(File) == 0) return(rep("", length(args)))
	# Read content of the text file
	Data <- scan(File, what = character(), sep ="\n", quiet = TRUE)
	# Get the Arguments: section
	argsStart <- (1:length(Data))[Data == "_\bA_\br_\bg_\bu_\bm_\be_\bn_\bt_\bs:"]
	if (length(argsStart) == 0)	# Not found
		return(rep("", length(args)))
	# Eliminate everything before this section
	Data <- Data[(argsStart[1] + 1):length(Data)]
	# Check where next section starts
	nextSection <- (1:length(Data))[regexpr("^_\\b", Data) > -1]
	if (length(nextSection) > 0)	# Cut everything after this section
		Data <- Data[1:(nextSection[1] - 1)]
	# Split description by arguments. Looks like: "^ *argument[, argument]: " + desc
	argsFirstLine <- regexpr("^ *[a-zA-Z0-9_., ]+: .*$", Data) > -1
	argsNames <- sub("^ *([a-zA-Z0-9_., ]+): .*$", "\\1", Data[argsFirstLine])
	# Try to detect false argsNames, when ":" occurs in description
	isArgs <- (regexpr("[^,] ", argsNames) == -1)
	argsFirstLine[argsFirstLine] <- isArgs
	argsNames <- argsNames[isArgs]
	# Get the argument description
	argsDesc <- sub("^ *(.*)$", "\\1", Data)
	argsDesc[argsFirstLine] <- sub("^[a-zA-Z0-9_., ]+: (.*)$", "\\1",
		argsDesc[argsFirstLine])
	# Create a character vector with the successive argument descriptions
	res <- tapply(argsDesc, cumsum(argsFirstLine), paste, collapse = " ")
	res <- as.vector(res)
	# Create multiple entries for "arg1, arg2, ..."
	argsNames <- strsplit(argsNames, ", ")
	Times <- sapply(argsNames, length)
	res <- rep(res, Times)
	names(res) <- unlist(argsNames)
	# If args is not NULL, filter according to provided arguments
	if (!is.null(args)) {
		res <- res[as.character(args)]
		# If arg names do not exists, return NA -> replace by ""
		names(res) <- args
		res[is.na(res)] <- ""
	}
	return(res)
}

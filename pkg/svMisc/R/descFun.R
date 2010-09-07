descFun <- function (fun, package, lib.loc = NULL)
{
	if (missing(package)) package <- NULL
	
	## Use the new help system if this is R >= 2.10.0
	if (compareRVersion("2.10.0") >= 0)
		return(.descFunNew(fun = fun, package = package, lib.loc = lib.loc))
	
	## Otherwise, use the old version (that depends on text rendered help files)
	if (is.null(fun) || length(fun) == 0) return("")
	fun <- as.character(fun[1])
	## Get the description associated with this topic
	AllTopics <- eval(parse(text = paste("library(help =", package,
		")")))$info[[2]]
	if (length(AllTopics) == 0) return("")
	res <- character()
	for (i in 1:length(fun)) {
		## index.search() will not be visible any more and will have different
		## arguments in R 2.11... and it is DEPRECATED in R 2.10
		## => need to use a different code here!!!
		## This is a temporary hack for svMisc to pass R CMD check on these versions
		if (!exists("index.search", mode= "function"))
			index.search <- function (...) return("")
		paths <- sapply(.find.package(package, lib.loc, verbose = FALSE),
			function(p) index.search(fun[i], p, "AnIndex", type = "help"))
		## Topic is the entry that contains the description
		Topic <- basename(paths[paths != ""])[1]
		## Get the first line of the description
		FirstLine <- (1:length(AllTopics))[regexpr(paste("^", Topic, " ",
			sep = ""), AllTopics) > -1]
		## If not found, try with fun[i]
		if (length(FirstLine) == 0) {
			Topic <- fun[i]
			FirstLine <- (1:length(AllTopics))[regexpr(paste("^", Topic, " ",
				sep = ""), AllTopics) > -1]
		}
		if (length(FirstLine) == 0) {
			res[i] <- ""  # Not found (should never happen?)
		} else {
			## Eliminate everything before this line
			Topics <- AllTopics[FirstLine[1]:length(AllTopics)]
			## We may have several lines of description: keep them all
			isSpace <- (regexpr("^ ", Topics) == -1)
			isDesc <- (cumsum(isSpace) == 1)
			Topics[1] <- sub(paste("^", Topic, sep = ""), "", Topics[1])
			## Get the description and return it
			res[i] <- paste(sub("^ +", "", Topics[isDesc]), collapse = " ")
		}
	}
	## Add names to this vector and return it
	names(res) <- fun
	return(res)
}

.descFunNew <- function (fun, package, lib.loc = NULL)
{
	## Get the description of fun using the new (R >= 2.10.0) help system
	if (is.null(fun) || length(fun) == 0) return("")
	fun <- as.character(fun[1])
	## Get location of the help file
	## We cannot just call help normally because otherwise it thinks
	## we are looking for package "package" so we create a call and eval it
	help.call <- call("help", fun, lib.loc = lib.loc, help_type = "text")
	if (!is.null(package)) help.call[["package"]] <- package
	file <- eval(help.call)
	file <- as.character(file)
	if (length(file) == 0) return("")
	## Read the Rd file and get the title section out of it
	Rdoc <- utils:::.getHelpFile(file[1L])
	## Look for the \title tag
	i <- 0
	for (i in seq_along(Rdoc))
		if (attr(Rdoc[[i]], "Rd_tag") == "\\title") break
	if (i == 0) return("") else {
		desc <- as.character(Rdoc[[i]][[1]])
		desc <- sub("^[ \t]+", "", desc)
		desc <- sub("[ \t]+$", "", desc)
		return(desc)
	}
}

descArgs <- function (fun, args = NULL, package = NULL, lib.loc = NULL)
{
	## Use the new help system if this is R >= 2.10.0
	if (compareRVersion("2.10.0") >= 0)
		return(.descArgsNew(fun = fun, args = args, package = package,
			lib.loc = lib.loc))
	
	## Otherwise, use the old version (that depends on text rendered help files)
	
	## Start from the text version of the online help instead of the .Rd file
	## The next line is to avoid raising warnings in R CMD check in R >= 2.10
	hlp <- function (...) help(...)
	if (is.null(package)) {
		File <- as.character(hlp(fun,
			lib.loc = lib.loc, chmhelp = FALSE, htmlhelp = FALSE))
	} else {
		File <- as.character(hlp(fun, package = parse(text = package),
			lib.loc = lib.loc, chmhelp = FALSE, htmlhelp = FALSE))
	}
	if (length(File) == 0) return(character(length(args)))

	## Doing the same as help to extract the file if it is in a zip
	File <- zip.file.extract(File, "Rhelp.zip")

	## If the file could not be extracted, return empties
	if( !file.exists(File))
		return(rep("", length(args)))
	
	## Guess the encoding (from print.help_files_with_topic)
	first <- readLines(File, n = 1)
	enc <- if (length(grep("\\(.*\\)$", first)) > 0) {
		sub("[^(]*\\((.*)\\)$", "\\1", first)
	} else ""
	if (enc == "utf8") enc <- "UTF-8"
	if (.Platform$OS.type == "windows" && enc == "" &&
		l10n_info()$codepage < 1000)
		enc <- "CP1252"
	File. <- file(File, encoding = enc, open = "r")

	## Read content of the text file
	Data <- scan(File., what = character(), sep = "\n", quiet = TRUE)
	close(File.)

	## Get the Arguments: section
	argsStart <- (1:length(Data))[Data == "_\bA_\br_\bg_\bu_\bm_\be_\bn_\bt_\bs:"]
	if (length(argsStart) == 0)	 # Not found
		return(rep("", length(args)))
	## Eliminate everything before this section
	Data <- Data[(argsStart[1] + 1):length(Data)]
	## Check where next section starts
	nextSection <- suppressWarnings((1:length(Data))[regexpr("^_\\b", Data) > -1])
	if (length(nextSection) > 0)  # Cut everything after this section
		Data <- Data[1:(nextSection[1] - 1)]
	## Split description by arguments, like: "^ *argument[, argument]: " + desc
	argsFirstLine <- regexpr("^ *[a-zA-Z0-9_., ]+: .*$", Data) > -1
	argsNames <- sub("^ *([a-zA-Z0-9_., ]+): .*$", "\\1", Data[argsFirstLine])
	## Try to detect false argsNames, when ":" occurs in description
	isArgs <- (regexpr("[^,] ", argsNames) == -1)
	argsFirstLine[argsFirstLine] <- isArgs
	argsNames <- argsNames[isArgs]
	## Get the argument description
	argsDesc <- sub("^ *(.*)$", "\\1", Data)
	argsDesc[argsFirstLine] <- sub("^[a-zA-Z0-9_., ]+: (.*)$", "\\1",
		argsDesc[argsFirstLine])
	## Create a character vector with the successive argument descriptions
	res <- tapply(argsDesc, cumsum(argsFirstLine), paste, collapse = " ")
	res <- as.vector(res)
	## Create multiple entries for "arg1, arg2, ..."
	argsNames <- strsplit(argsNames, ", *")
	Times <- sapply(argsNames, length)
	res <- rep(res, Times)
	names(res) <- unlist(argsNames)
	## If args is not NULL, filter according to provided arguments
	if (!is.null(args)) {
		res <- res[as.character(args)]
		## If arg names do not exists, return NA -> replace by ""
		names(res) <- args
		res[is.na(res)] <- ""
	}
	return(res)
}

## Version of descArgs for R >= 2.10.0 and its new help system
.descArgsNew <- function (fun, args = NULL, package = NULL, lib.loc = NULL)
{	
	## We cannot just call help normally because otherwise it thinks
	## we are looking for package "package" so we create a call and eval it
	help.call <- call("help", fun, lib.loc = lib.loc, help_type = "text")
	if (!is.null(package)) help.call[["package"]] <- package
	file <- eval(help.call)
	
	## This is borrowed from utils::print.help_files_with_topic
	path <- dirname(file)
    dirpath <- dirname(path)
    pkgname <- basename(dirpath)
    RdDB <- file.path(path, pkgname)
    
    if (!file.exists(paste(RdDB, "rdx", sep=".")))
    	return(character(length(args)))
    
    rd <- tools:::fetchRdDB(RdDB, basename(file))
    
    ## This is not exported from tools
    RdTags <- function (Rd) {
    	res <- sapply(Rd, attr, "Rd_tag")
    	if (!length(res)) res <- character(0)
    	return(res)
    }
    tags <- gsub("\\", "", RdTags(rd), fixed = TRUE) 
    
    if (!any(tags == "arguments")) return(character(length(args)))
    
    arguments <- rd[[which(tags == "arguments")[1]]]
    items <- arguments[RdTags(arguments) == "\\item"]
    descriptions <- do.call(rbind, lapply(items, function (item) {
		names <- try(strsplit(item[[1]][[1]], "\\s*,\\s*", perl = TRUE)[[1]],
			silent = TRUE)
		if (inherits(names, "try-error")) {
			## This happens with the "..." argument
			names <- "..."
		}
    	content <- paste(rapply(item[-1], as.character), collapse = "")
    	cbind(names, rep.int(content, length(names)))
    }))
    
    if (is.null(args)) {
    	structure(descriptions[, 2], names = descriptions[, 1])
    } else {
    	sapply(args, function (a) {
    		if (a %in% descriptions[, 1]) {
    			descriptions[which(descriptions[, 1] == a)[1] , 2]
    		} else ""
    	})
    }
}

.descData <- function (data, columns, package = NULL, lib.loc = NULL)
	character(length(columns))

.descSlots <- function (object, slots, package = NULL, lib.loc = NULL)
	character(length(slots))

.descSquare <- function (completions, package = NULL)
	character(length(completions))

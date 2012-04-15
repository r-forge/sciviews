## Routines to manage and convert SciViews R script to asciidoc-sweave
## Copyright (c) 2012, Ph. Grosjean (phgrosjean@sciviews.org)
## Note: !"doc block" is managed by the SciViews version of `!`,
## otherwise it produces an error... So, you have to place require(SciViews)
## in the initialisation block (second line) of the SciViews R script!

RasciidocToRnw <- function (Rfile, RnwFile, encoding)
{
	## Converts a SciViews R script into an sweave document (.Rnw)
	
	## If Rfile is missing, try to get it from option or the command line
	if (missing(Rfile)) Rfile <- .Rfile()
	
	## Get RnwFile
	if (missing(RnwFile)) RnwFile <- getOption("sv.RnwFile",
		.fileExt(Rfile, "Rnw"))
	## Make sure it is not an old file at the end of the process that remains
	unlink(RnwFile)

	## Get encoding
	if (missing(encoding)) encoding <- getOption("sv.encoding", "UTF-8")
		
	## Read Rfile content
	Rscript <- readLines(Rfile, encoding = encoding)
	l <- length(Rscript)
	
	## Detect doc chunks
	start <- grepl('^!"@[ \t]*$', Rscript)
	end <- grepl('^<<.*>>="[ \t]*$', Rscript)
	## Must have at least one doc chunk and same number of starts and ends
	nstart <- sum(start)
	nend <- sum(end)
	if (nstart < 1)
		stop("Incorrect SciViews R script (it must contain at least one doc chunk)")
	if (sum(end) != nstart)
		stop("Incorrect SciViews R script (", nstart, " doc chunk starts but ",
			nend, " ends)")
	## Lines containing starts and ends
	lstart <- (1:l)[start]
	lend <- (1:l)[end]
	## All starts must occur, of course before ends
	cstart <- cumsum(start)
	cend <- cumsum(end)
	if (any(cend > cstart))
		stop("Incorrect SciViews R script (inversion of start and end in one or more doc chunks)")
	
	## Check that it is the SciViews R script file starts with #!
	if (!grepl("^#!", Rscript[1]))
		stop("Incorrect SciViews R script (it must start with #!)")
	
	## Locate the header, which is one or several lines of initialization R code
	inHeader <- 2:(lstart[1] - 1)
	
	## Doc chunks are lines where cstart > cend
	inDoc <- cstart > cend
	
	## Convert \" into " inside doc blocks
	Rscript[inDoc] <- gsub('\\\\"', '"', Rscript[inDoc])
	
	## Convert \\ into \ inside doc blocks
	Rscript[inDoc] <- gsub("\\\\\\\\", "\\\\", Rscript[inDoc])
	
	## Replace all doc chunk starters (!"@) by @
	Rscript[start] <- "@"
	
	## Replace all doc chunk ends (<<.*>>=") by the same without trailing "
	Rscript[end] <- sub('^(.*>>=)"[ \t]*$', "\\1", Rscript[end])
	
	## Polish the end of the document...
	lastDoc <- lend[length(lend)]
	## If there is no R code after last doc chunk...
	if (l == lastDoc || all(grepl("^[ \t]*$", Rscript[lastDoc:l]))) {
		## Nothing after last doc => eliminate last <<.*>>=
		Rscript[lastDoc] <- ""
	} else {
		## Some R code after last doc chunk... we have to add '@' at the end
		## of the .Rnw file to finish the last code chunk
		Rscript <- c(Rscript, "@")
	}
	
	## Now, rework the header lines to be compatible with a .Rnw file
	## Place initialization R code in a 'echo = FALSE' code chunk just before
	## the first current code chunck
	firstChunk <- lend[1]
	header <- paste(Rscript[inHeader], collapse = "\n")
	Rscript[firstChunk] <- paste("<<echo = FALSE>>=\n", header,
		"\n@\n\n", Rscript[firstChunk], sep = "")
	## Now eliminate the header from the script
	Rscript <- Rscript[-c(1, inHeader, max(inHeader) + 1)]

	## Write result to the RnwFile
	## TODO: check encoding of .Rnw file on all platforms
#	utf8conv <- function(x) gsub("<U\\+([0-9A-F]{4})>","\\\\u\\1", x)
#	Rscript <- utf8conv(Rscript)
	writeLines(Rscript, RnwFile, useBytes = TRUE)
#	writeLines(enc2utf8(Rscript), RnwFile, useBytes = TRUE)

	## ... and that's done!
	return(invisible(Rscript))
}

RasciidocToHtml <- function (Rfile, theme, show.it, figsDir, keepRnwFile,
keepTxtFile, encoding, asciidoc)
{
	## If Rfile is missing, try to get it from option or the command line
	if (missing(Rfile)) Rfile <- .Rfile()
	
	## RnwFile is either same place, same name as Rfile, or option sv.RnwFile
	RnwFile <- getOption("sv.RnwFile", .fileExt(Rfile, "Rnw"))

	## TxtFile is from option, or from SciViews session directory structure
	## or at the same location as the Rfile
	TxtFile <- getOption("sv.TxtFile", .fileExt(Rfile, "txt"))
	ReportDir <- .svSessionDirs(Rfile)$reportdir
	if (length(ReportDir)) {
		TxtFile <- file.path(ReportDir, basename(TxtFile))
	} else TxtFile <- TxtFile
	## Make sure this is not an old file
	unlink(TxtFile)
		
	## HtmlFile is always at same location as TxtFile
	HtmlFile <- .fileExt(TxtFile, "html")
	
	## If figsDir is defined (default to 'figures'), make sure it exists
	if (missing(figsDir)) figsDir <- getOption("sv.figsDir", "figures")
	if (length(figsDir)) dir.create(file.path(dirname(HtmlFile), figsDir),
		showWarnings = FALSE, recursive = TRUE)
	
	## If theme is missing, try getting it from options()
	if (missing(theme)) theme <- getOption("sv.theme", "sciviews")
	## If there is an initialization file for this theme, run it now
	## TODO...
		
	## Do we show the resulting Html file in the current browser at the end?
	## By default YES, unless in non-interactive mode
	if (missing(show.it)) show.it <- getOption("sv.show.it", interactive())
	
	## Do we keep intermediary .Rnw and .txt files? Default to FALSE
	if (missing(keepRnwFile)) keepRnwFile <- getOption("sv.keepRnwFile", FALSE)
	if (missing(keepTxtFile)) keepTxtFile <- getOption("sv.keepTxtFile", FALSE)
	
	## Get encoding... should be UTF-8 for SciViews R scripts
	## and make sure to configure the system as UTF-8 (except on Windows)
	if (missing(encoding)) encoding <- getOption("sv.encoding", "UTF-8")
	if (toupper(encoding) == "UTF-8") {
		if (.Platform$OS.type != "windows") {
			## Make sure current locale is UTF-8
			## It is not, for instance, if started from terminal in Mac OS X!
			## Also force 'en_US' for homogeneity of R behaviour across systems
			Sys.setlocale(, "en_US.UTF-8")
			on.exit(Sys.setlocale(, "")) # Reset default locale for the system
		}
	}
	
	## Get asciidoc Python script
	if (missing(asciidoc)) asciidoc <- getOption("asciidoc",
		system.file("asciidoc", "asciidoc.py", package = "svSweave",
		mustWork = TRUE))
	
	## We need also Python >= version 2.4
	python <- getOption("python", NULL)
	## Search (again)...
	if (is.null(python)) {
		python <- .python()
		options(python = python)
	}
	## Nothing to do... no Python found!
	if (is.null(python)) stop("Python >= 2.4 is required for asciidoc")
	
	## Convert from Rscript to .Rnw file
	cat("Creating R noweb file ", basename(RnwFile), "\n", sep = "")
	RasciidocToRnw(Rfile = Rfile, RnwFile = RnwFile, encoding = encoding)
	if (!file.exists(RnwFile))
		stop("Problems while creating the R noweb file(", RnwFile, ")")
	
	## Copy it to where the Txt file must be created...
	if (dirname(TxtFile) != dirname(RnwFile)) {
		RnwFile2 <- file.path(dirname(TxtFile), basename(RnwFile))
		file.copy(RnwFile, RnwFile2)
		if (!file.exists(RnwFile))
			stop("Problems while copying the R noweb file(", RnwFile, " to ",
				dirname(TxtFile), ")")
	} else RnwFile2 <- RnwFile
	
	## Sweave that document to .txt file
	## Note that the ascii package must be loaded first!
	require(ascii, quietly = TRUE, warn.conflicts = FALSE)
	odir <- setwd(dirname(RnwFile2)) # Work now relative to destination file
	
	## Make sure intermediary filles will be deleted on exit
	on.exit({
		setwd(odir)
		unlink(RnwFile2)
		## Possibly delete intermediary files
		if (!isTRUE(keepRnwFile)) unlink(RnwFile)
		if (!isTRUE(keepTxtFile)) unlink(TxtFile)	
	})
	
	## Sweave this document...
	Asciidoc(RnwFile2, encoding = encoding) # This should create the TxtFile
	
	if (!file.exists(TxtFile))
		stop("Problems while creating the Asciidoc file (", TxtFile, ")")
	
	## Do we use a particular theme with Asciidoc
	if (theme == "classic") opts <- '" -a asciimath -a caption "' else
		opts <- paste('" -a asciimath -a caption --theme=', theme, '@ "', sep = "")

	## Use AsciiDoc to convert the .txt file into an .html file
	cat("Running asciidoc to create ", basename(HtmlFile), "\n", sep = "")
	system(paste('"', python, '" "', asciidoc, opts, TxtFile, '"', sep = ""))
		
	## If there is a finalize code for this theme, run it now
	## TODO...

	## Do we view the resulting .html file?
	if (isTRUE(show.it)) {
		cat("Opening the report", basename(HtmlFile), "in the Web browser\n")
		browseURL(normalizePath(HtmlFile))
	} else cat("Report available at ", HtmlFile, "\n", sep = "")
}

RasciidocThemes <- function ()
{
	themesDir <- file.path(dirname(system.file("asciidoc", "asciidoc.py",
		package = "svSweave")), "themes")
	c("classic", dir(themesDir, include.dirs = TRUE))
}

svBuild <- function (Rfile, encoding)
{
	## A function to run an a SciViews R script file, and that looks at the #!
	## line to determine what function to run for compiling the final document

	## Check Rfile
	if (missing(Rfile) || !length(Rfile)) stop("No file provided")
	if (!file.exists(Rfile)) stop("Rfile not found (", Rfile, ")")
	Rfile <- normalizePath(Rfile)
	
	## Get encoding
	if (missing(encoding)) encoding <- getOption("sv.encoding", "UTF-8")	
	
	## Check that it is a R script file (first line starting with #!)
	Rscript <- readLines(Rfile, n = 1L, encoding = encoding)
	if (!grepl("^#!", Rscript))
		stop("Incorrect SciViews R script (it must start with #!)")

	## Decrypt first line to know what function to run to build this file
	cmd <- sub("^#!.+ -e[ \t]*(.+)$", "\\1", Rscript)
	if (cmd == Rscript) stop("Malformed #! line in '", Rfile, "'")
	
	## Eliminate possible quotes around the command and trailing spaces
	cmd <- sub("[ \t]+$", "", cmd)
	cmdNoQuotes <- sub("^'(.+)'$", "\\1", cmd) # Single quotes
	if (cmdNoQuotes == cmd)
		cmdNoQuotes <- sub('^"(.+)"$', "\\1", cmd) # Double quotes
	
	## Pass the file name to the build procedure
	ofile <- options(sv.Rfile = Rfile)$sv.Rfile
	oencoding <- options(sv.encoding = encoding)$sv.encoding
	on.exit(options(sv.Rfile = ofile, encoding = oencoding))
	
	## Run that command
	cmd <- try(parse(text = cmdNoQuotes))
	if (!inherits(cmd, "try-error")) eval(cmd, envir = parent.frame())
}

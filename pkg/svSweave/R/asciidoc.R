## Routines to manage and convert SciViews Rdoc to asciidoc-sweave
## Copyright (c) 2012, Ph. Grosjean (phgrosjean@sciviews.org)
## Note: !"doc block" is managed by the SciViews version of `!`,
## otherwise it produces an error... So, you have to place require(SciViews)
## in the initialisation block (second line) of the SciViews Rdoc!

Rdoc <- function (title, author, email, revnumber = NULL, revdate = NULL,
revremark = NULL, copyright = "cc-by", encoding = "UTF-8", lang = "en",
pagetitle = NULL, description = "SciViews Rdoc", keywords = NULL,
theme = "SciViews", max.width = 640, width = NULL,
toc = c("top", "side", "manual", "none"), toc.title = NULL, toclevels = 2,
numbered = TRUE, data.uri = TRUE, frame = "topbot", grid = "rows",
align = "center", halign = "center", pygments = FALSE, slidefontsizeadjust = 0,
SweaveInit = { options(width = 80); options(SweaveHooks = list(fig = function()
par(col.lab = "#434366", col.main = "#434366"))) }
)
{
	## Format AsciiDocsciidoc attributes
	asciiAttr <- function (header = NULL, name, value) {
		if (!length(value)) return(header)
		paste0(header, ":", name, ": ", paste(value, collapse = ","), "\n")
	}
	
	## Title must be a single string
	title <- as.character(title)[1]
	if (!length(title))
		stop("You must provide a title for your Rdoc")
	
	## Idem for author, but allow several names
	author <- paste(author, collapse = ", ")
	if (!length(author))
		stop("You must provide at least one author for your Rdoc")
	
	## Check email
	email <- as.character(email)[1]
	if (!length(email) || !grepl("^.+@.+$", email))
		stop("You must provide a correct email address for your Rdoc")
	
	## Compute revision field: [revnumber], [revdate]:\n[revremark]
	if (length(revnumber))
		revfield <- paste0("v", revnumber, ", ") else revfield <- ""
	if (!length(revdate)) revdate <- format(Sys.Date(), format = "%B %Y")
	revfield <- paste0(revfield, revdate)
	if (length(revremark))
		revfield <- paste0(revfield, ":\n", paste(revremark, collapse = "\n"))
		
	## Create the Asciidoc header
	header <- paste0(
		"= ", title, "\n",
		author, " <", email, ">\n",
		revfield, "\n"
	)
	
	## Rework copyright
	if (length(copyright)) {
		if (!grepl("^[^,]+,[^,]+,[ \t]*[0-9]{4}$", copyright)) {
			year <- substring(revdate, nchar(revdate) - 3)
			copyright <- paste0(copyright, ", ", author, ", ", year)
		}
		header <- asciiAttr(header, "copyright", copyright)
	}
	
	## Add more attributes
	header <- asciiAttr(header, "encoding", encoding)
	header <- asciiAttr(header, "lang", lang)
	header <- asciiAttr(header, "title", pagetitle)
	header <- asciiAttr(header, "description", description)
	header <- asciiAttr(header, "keywords", keywords)
	header <- asciiAttr(header, "theme", theme)
	header <- asciiAttr(header, "max-width", max.width)
	header <- asciiAttr(header, "width", width)
	
	## How to format the toc?
	toc <- switch(as.character(toc)[1],
		top = ":toc:\n",
		side = ":toc2:\n",
		manual = ":toc:\n:toc-placement: manual\n",
		none = ":toc!:\n",
		stop("'toc' must be 'top', 'side', 'manual' or ''none'"))
	header <- paste0(header, toc)
	header <- asciiAttr(header, "toc-title", toc.title)
	header <- asciiAttr(header, "toclevels", toclevels)
	if (isTRUE(numbered)) header <- paste0(header, ":numbered:\n")
	if (isTRUE(data.uri)) header <- paste0(header, ":data-uri:\n")
	header <- asciiAttr(header, "frame", frame)
	header <- asciiAttr(header, "grid", grid)
	header <- asciiAttr(header, "align", align)
	header <- asciiAttr(header, "halign", halign)
	if (isTRUE(pygments)) header <- paste0(header, ":pygments:\n")
	header <- asciiAttr(header, "slidefontsizeadjust", slidefontsizeadjust)
	header <- paste0(header, "\n") # End of header section
	
	## Run SweaveInit now
	SweaveInit
	## More initialization
	req <- base::require
	req("SciViews", quietly = TRUE, warn.conflicts = FALSE)
	
	## Print the header and return it invisibly
	if (!interactive()) cat(header)
	invisible(header)
}

RdocToRnw <- function (RdocFile, RnwFile, encoding)
{
	## Converts a SciViews Rdoc into an sweave document (.Rnw)
	
	## If RdocFile is missing, try to get it from option or the command line
	if (missing(RdocFile)) RdocFile <- .RdocFile()
	
	## Get RnwFile
	if (missing(RnwFile)) RnwFile <- getOption("Rnw.file",
		.fileExt(RdocFile, "Rnw"))
	## Make sure it is not an old file at the end of the process that remains
	unlink(RnwFile)

	## Get encoding
	if (missing(encoding)) encoding <- getOption("Rdoc.encoding", "UTF-8")
		
	## Read RdocFile content
	Rscript <- readLines(RdocFile, encoding = encoding)
	l <- length(Rscript)
	
	## Detect doc chunks (start with !", and end with !<<...>>=")
	start <- grepl('^!"[ \t]*$', Rscript)
	end <- grepl('^<<.*>>="[ \t]*$', Rscript)
	## Must have at least one doc chunk and same number of starts and ends
	nstart <- sum(start)
	nend <- sum(end)
	if (nstart < 1)
		stop("Incorrect SciViews Rdoc (it must contain at least one doc chunk)")
	if (sum(end) != nstart)
		stop("Incorrect SciViews Rdoc (", nstart, " doc chunk starts but ",
			nend, " ends)")
	## Lines containing starts and ends
	lstart <- (1:l)[start]
	lend <- (1:l)[end]
	## All starts must occur, of course before ends
	cstart <- cumsum(start)
	cend <- cumsum(end)
	if (any(cend > cstart))
		stop("Incorrect SciViews Rdoc",
			 " (inversion of start and end in one or more doc chunks)")
	
	## Check that the SciViews Rdoc file starts with #!
	if (!grepl("^#!", Rscript[1]))
		stop("Incorrect SciViews Rdoc (it must start with #!)")
	## Change this line into an init code chunk
	Rscript[1] <- "<<init, echo=FALSE, results=ascii>>="
	
	## Doc chunks are lines where cstart > cend
	inDoc <- cstart > cend
	
	## Convert \" into " inside doc blocks
	Rscript[inDoc] <- gsub('\\\\"', '"', Rscript[inDoc])
	
	## Convert \\ into \ inside doc blocks
	Rscript[inDoc] <- gsub("\\\\\\\\", "\\\\", Rscript[inDoc])
	
	## Convert comments blocks using four or more #### by ////
	Rscript[inDoc] <- gsub("^####+$", "////", Rscript[inDoc])
	
	## Convert line comments using ## by __
	Rscript[inDoc] <- gsub("^##", "__", Rscript[inDoc])
	
	## Replace all doc chunk starters (!") by @
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
	
	## Write result to the RnwFile
	## TODO: check encoding of .Rnw file on all platforms
#	utf8conv <- function(x) gsub("<U\\+([0-9A-F]{4})>","\\\\u\\1", x)
#	Rscript <- utf8conv(Rscript)
	writeLines(Rscript, RnwFile, useBytes = TRUE)
#	writeLines(enc2utf8(Rscript), RnwFile, useBytes = TRUE)

	## ... and that's done!
	return(invisible(Rscript))
}

RdocConvert <- function (RdocFile, theme, format, show.it, figs.dir,
keep.RnwFile, keep.TxtFile, encoding, asciidoc)
{
	## If RdocFile is missing, try to get it from option or the command line
	if (missing(RdocFile)) RdocFile <- .RdocFile()
	
	## RnwFile is either same place, same name as RdocFile, or option Rnw.file
	RnwFile <- getOption("Rnw.file", .fileExt(RdocFile, "Rnw"))

	## TxtFile is from option, or from SciViews session directory structure
	## or at the same location as the RdocFile
	TxtFile <- getOption("Txt.file", .fileExt(RdocFile, "txt"))
	ReportDir <- .svSessionDirs(RdocFile)$reportdir
	if (length(ReportDir)) {
		TxtFile <- file.path(ReportDir, basename(TxtFile))
	} else TxtFile <- TxtFile
	## Make sure this is not an old file
	unlink(TxtFile)
	
	## If figs.dir is defined (default to 'figures'), make sure it exists
	if (missing(figs.dir)) figs.dir <- getOption("Rdoc.figs.dir", "figures")
	if (length(figs.dir)) dir.create(file.path(dirname(TxtFile), figs.dir),
		showWarnings = FALSE, recursive = TRUE)
	
	## If format is missing, try getting it from options(), or assume "html"
	if (missing(format)) format <- getOption("Rdoc.format", "html")
	## The resulting file extension depends on the format used
	## Note that EndFile is always at same location as TxtFile
	EndExt <- switch(format,
		html = "html",
		html11 = "html",
		html5 = "html",
		html4 = "html",
		slidy = "html",
		slidy2 = "html",
		wordpress = "html",
		docbook = "xml",
		docbook45 = "xml",
		latex = "tex",
		stop("Unknown format,",
			" use html/html4/html5/slidy/slidy2/wordpress/docbook/latex")
		)
	EndFile <- .fileExt(TxtFile, EndExt)
		
	## If theme is missing, try getting it from options()
	if (missing(theme)) theme <- getOption("Rdoc.theme", "sciviews")
	## If there is an initialization file for this theme, run it now
	## TODO...
		
	## Do we show the resulting Html file in the current browser at the end?
	## By default YES, unless in non-interactive mode
	if (missing(show.it)) show.it <- getOption("Rdoc.show.it", interactive())
	
	## Do we keep intermediary .Rnw and .txt files? Default to FALSE
	if (missing(keep.RnwFile))
		keep.RnwFile <- getOption("Rdoc.keep.RnwFile", FALSE)
	if (missing(keep.TxtFile))
		keep.TxtFile <- getOption("Rdoc.keep.TxtFile", FALSE)
	
	## Get encoding... should be UTF-8 for SciViews Rdoc
	## and make sure to configure the system as UTF-8 (except on Windows)
	if (missing(encoding)) encoding <- getOption("Rdoc.encoding", "UTF-8")
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
	RdocToRnw(RdocFile = RdocFile, RnwFile = RnwFile, encoding = encoding)
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
		if (!isTRUE(keep.RnwFile)) unlink(RnwFile)
		if (!isTRUE(keep.TxtFile)) unlink(TxtFile)	
	})
	
	## Sweave this document... (creating the TxtFile)
	## Note: we change some default options here!
	Asciidoc(RnwFile2, encoding = encoding, prefix.string = "figures/fig",
		width = 7.2, height = 7.2, png = TRUE, jpeg = FALSE, format = "png")
	
	if (!file.exists(TxtFile))
		stop("Problems while creating the Asciidoc file (", TxtFile, ")")
	
	## Do we use a particular theme with Asciidoc
	if (theme == "classic") {
		opts <- paste('" -b ', format, ' -a asciimath -a caption "', sep = "")
	} else {
		opts <- paste('" -b ', format, ' -a asciimath -a caption --theme=',
			theme, '@ "', sep = "")
	}

	## Use AsciiDoc to convert the .txt file into an .html file
	cat("Running asciidoc to create ", basename(EndFile), "\n", sep = "")
	system(paste('"', python, '" "', asciidoc, opts, TxtFile, '"', sep = ""))
		
	## If there is a finalize code for this theme, run it now
	## TODO...

	## Do we view the resulting .html file?
	if (isTRUE(show.it) && EndExt == "html") {
		cat("Opening the formatted document", basename(EndFile),
			"in the Web browser\n")
		browseURL(normalizePath(EndFile))
	} else cat("Formatted document available at ", EndFile, "\n", sep = "")
}

RdocThemes <- function ()
{
	themesDir <- file.path(dirname(system.file("asciidoc", "asciidoc.py",
		package = "svSweave")), "themes")
	c("classic", dir(themesDir, include.dirs = TRUE))
}

makeRdoc <- function (RdocFile, encoding)
{
	## A function to run an a SciViews Rdoc file, and that looks at the #!
	## line to determine what function to run for compiling the final document

	## If RdocFile is missing, try to get it from option or the command line
	if (missing(RdocFile)) RdocFile <- .RdocFile()
	
	## Check RdocFile
	if (missing(RdocFile) || !length(RdocFile)) stop("No file provided")
	if (!file.exists(RdocFile)) stop("RdocFile not found (", RdocFile, ")")
	RdocFile <- normalizePath(RdocFile)
	
	## Get encoding
	if (missing(encoding)) encoding <- getOption("Rdoc.encoding", "UTF-8")	
	
	## Check that it is a R script file (first line starting with #!)
	Rscript <- readLines(RdocFile, n = 1L, encoding = encoding)
	if (!grepl("^#!", Rscript))
		stop("Incorrect SciViews Rdoc file (it must start with #!)")

	## Decrypt first line to know what function to run to make this file
	cmd <- sub("^#!.+ -e[ \t]*(.+)$", "\\1", Rscript)
	if (cmd == Rscript) stop("Malformed #! line in '", RdocFile, "'")
	
	## Eliminate possible quotes around the command and trailing spaces
	cmd <- sub("[ \t]+$", "", cmd)
	cmdNoQuotes <- sub("^'(.+)'$", "\\1", cmd) # Single quotes
	if (cmdNoQuotes == cmd)
		cmdNoQuotes <- sub('^"(.+)"$', "\\1", cmd) # Double quotes
	
	## Pass the file name to the build procedure
	ofile <- options(Rdoc.file = RdocFile)$Rdoc.file
	oencoding <- options(Rdoc.encoding = encoding)$Rdoc.encoding
	on.exit(options(Rdoc.file = ofile, encoding = oencoding))
	
	## Run that command
	cmd <- try(parse(text = cmdNoQuotes))
	if (!inherits(cmd, "try-error")) eval(cmd, envir = parent.frame())
}

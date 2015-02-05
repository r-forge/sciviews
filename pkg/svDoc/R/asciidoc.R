## Routines to manage and convert SciViews svDoc to asciidoc-sweave
## Copyright (c) 2012, Ph. Grosjean (phgrosjean@sciviews.org)
## Note: !!"doc block" is managed by the SciViews version of `!`,
## otherwise it produces an error... So, you have to place require(SciViews)
## in the initialisation block (second line) of the SciViews Rdoc!

svDocToRnw <- function (svDocFile, RnwFile, encoding)
{
	## Converts a SciViews doc into an sweave document (.Rnw)
	## with Asciidoc formatting (also convert markdown to Asccidoc)
	
	## If svDocFile is missing, try to get it from option or the command line
	if (missing(svDocFile)) svDocFile <- .svDocFile()
	svDocFile <- normalizePath(svDocFile)
	
	## Get RnwFile
	if (missing(RnwFile)) RnwFile <- getOption("Rnw.file",
		.fileExt(svDocFile, "Rnw"))
	## Make sure it is not an old file at the end of the process that remains
	unlink(RnwFile)

	## Get encoding
	if (missing(encoding)) encoding <- getOption("svDoc.encoding", "UTF-8")
		
	## Read svDocFile content
	Rscript <- readLines(svDocFile, encoding = encoding)
	l <- length(Rscript)
	
	## Detect doc chunks (start with !!", and end with <<...>>=")
	start <- grepl('^!!"[ \t]*$', Rscript)
	end <- grepl('^<<.*>>="[ \t]*$', Rscript)
	## Must have at least one doc chunk and same number of starts and ends
	nstart <- sum(start)
	nend <- sum(end)
	if (nstart < 1)
		stop("Incorrect SciViews doc (it must contain at least one doc chunk)")
	if (sum(end) != nstart)
		stop("Incorrect SciViews doc (", nstart, " doc chunk starts but ",
			nend, " ends)")
	## Lines containing starts and ends
	lstart <- (1:l)[start]
	lend <- (1:l)[end]
	## All starts must occur, of course before ends
	cstart <- cumsum(start)
	cend <- cumsum(end)
	if (any(cend > cstart))
		stop("Incorrect SciViews doc",
			 " (inversion of start and end in one or more text chunks)")
	
	## Check that the SciViews doc file starts with #!
	if (!grepl("^#!", Rscript[1]))
		stop("Incorrect SciViews doc (it must start with #!)")
	## Change this line into an init code chunk
	Rscript[1] <- "<<header, echo=FALSE, results=ascii, strip.white=false>>="
	
	## Text chunks are lines where cstart > cend
	inDoc <- cstart > cend
	
	#### Conversion markdown into asciidoc formattings
	#### Titles
	## Asciidoc does not support H6. Transform it into block .title
#	Rscript[inDoc] <- sub('^######[ \t]*([^#]+)#*$', '.\\1', Rscript[inDoc])
#	## H1 -> H5: markdown to Asciidoc
#	Rscript[inDoc] <- sub('^#####[ \t]*([^#]+)#*$', '===== \\1', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^####[ \t]*([^#]+)#*$', '==== \\1', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^###[ \t]*([^#]+)#*$', '=== \\1', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^##[ \t]*([^#]+)#*$', '== \\1', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^#[ \t]*([^#]+)#*$', '= \\1', Rscript[inDoc])
#	## TODO: make sure we have same number of chars for ==== and ---- underlined titles
	
	## Markdown version of *italic* and __bold__: done in asciidoc.conf
	## Markdown strikethrough ~~text~~ also done in asciidoc.conf
	## Super^script^and sub~script~ is identical between extended markdown
	## and asciidoc, but support also <sub>...</sub> and <super>...</super>
#	Rscript[inDoc] <- gsub('</?sub>', '~', Rscript[inDoc])
#	Rscript[inDoc] <- gsub('</?super>', '~', Rscript[inDoc])
	## Note super^script without terminating ^ like in first  .Rmd version NOT supported!
	## Terminate unterminated superscripts (markdown compatible) and subscripts
	## NO! It is too much error-prone!!!
	#Rscript[inDoc] <- gsub('\\^([^^ \t\r\n]+)\\^?([ \t\r\n])', '^\\1^\\2', Rscript[inDoc])
	#Rscript[inDoc] <- gsub('\\~([^~ \t\r\n]+)~?([ \t\r\n])', '~\\1~\\2', Rscript[inDoc])
	
	## Convert markdown style force line break (2 or more space or 1
	## or more tabs at the end of line) into asciidoc break (space +)
	## TODO: may be use this, but not in passthrough or listing or literal blocks!
#	Rscript[inDoc] <- gsub("(  |\t)[ \t]*$", " +", Rscript[inDoc])
	
	## Make sure rulers are on their own line
	## --- or - - - or *** or * * * or ___
	## Note: if using ---, *** or ___: do not support more than three items!
	## This is to avoid clash with listing, sidebar and quoted blocks, respectively!
#	Rscript[inDoc] <- sub('^[ /t]*[-*_]{3}[ /t]*$', "'''", Rscript[inDoc])
#	Rscript[inDoc] <- sub('^[ /t]*(- ){2,}-[ /t]*$', "'''", Rscript[inDoc])
#	Rscript[inDoc] <- sub('^[ /t]*(\\* ){2,}\\*[ /t]*$', "'''", Rscript[inDoc])
	## Format page break...not needed, since not defined in markdown?
	#Rscript[inDoc] <- sub('^[ /t]*<{3,}[ /t]*$', '\n<<<\n', Rscript[inDoc])
	
	## Convert markdown fenced block (possibly with syntax highlighting) ```s
	## into Asciidoc equivalent [source,lang]\n```
	## TODO: allow for numbered lines (how?)
	Rscript[inDoc] <- sub('^`{3,}([a-zA-Z0-9]+)[ \t]*$', '[source,\\1]\n```', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^`{3,}[ \t]*$', '----', Rscript[inDoc])
	
	## Convert markdown HTML blocks into Asciidoc HTML block by enclosing it inside
	## a passtrough block using ++++
	## TODO: look if it is not already a passthrough and avoid this in listing bocks!
#	Rscript[inDoc] <- sub('^(</[^>]+)>)', '\\1\n++++', Rscript[inDoc])
#	Rscript[inDoc] <- sub('^(<[^>]+)>)', '++++\n\\1', Rscript[inDoc])
	
	## Convert markdown image markups into Asciidoc equivalents
	## ![Alt text](path/to/img.jpg "opt title") on one line => image::/path/to/img.jpg[Alt text]
	## Same one inside text => image:/path/to/img.jpg[Alt text]
	## TODO: how to deal with optional title? And with white space? And non relative path?
	## TODO: I have a space too much if optional title is provided!
	Rscript[inDoc] <- sub('^!(\\[[^]]+\\])\\(([^)"\']+)[^)]*\\)$', 'image::\\2\\1', Rscript[inDoc])
	Rscript[inDoc] <- sub('!(\\[[^]]+\\])\\(([^)"\']+)[^)]*\\)', 'image:\\2\\1', Rscript[inDoc])
	
	## Convert markdown links into Asciidoc equivalents
	## [A link](http://example.com "opt title") => http://example.com/[A link]
	## TODO: deal with spaces inside links
	## TODO: I have a space too much if optional title is provided!
	Rscript[inDoc] <- sub('(\\[[^]]+\\])\\(([^)"\']+)[^)]*\\)', '\\2\\1', Rscript[inDoc])
	
	
	## Asciidoc does not handle markdown quoted text well, currently
	## Just prepend {empty} for transforming it as text
	## TODO... and what about indented stuff?
	

#	isTxt <- grepl("^(#' .*|[ /t]*)$", ttt)
#	tt2 <- sub("^#' ", "", ttt)
#	## Transition text -> R chunk
#	trans1 <- c(FALSE, !isTxt[-1] & isTxt[-length(isTxt)])
#	## Add empty R chunk transition in trans1, if not there
#	tt2t1 <- tt2[trans1]
#	noTrans <- !grepl("^#[+-] ", tt2t1)
#	tt2t1[noTrans] <- paste0("<<>>=\n", tt2t1[noTrans])
#	tt2[trans1] <- tt2t1
#	## Transition R chunk -> text
#	trans2 <- c(FALSE, isTxt[-1] & !isTxt[-length(isTxt)])
#	tt2[trans2] <- paste0("@\n", tt2[trans2])
	
	
	
	## Convert \" into " inside doc blocks
	Rscript[inDoc] <- gsub('\\\\"', '"', Rscript[inDoc])
	
	## Convert \\ into \ inside doc blocks
	Rscript[inDoc] <- gsub("\\\\\\\\", "\\\\", Rscript[inDoc])
	
	## Convert from R markdown `r 1+1`or ``r 1+1``into Sweave style for
	## inline R expressions \Sexpr{1+1} (note that we leave external ` if it is doubled!) 
	Rscript[inDoc] <- gsub('`r[ \t]+([^`]*)`', '\\\\Sexpr{\\1}', Rscript[inDoc])
	## But WAIT: we need to escape } inside the expression!!!
	## First, replace Sexpr delimiters by %@%SEXPR%@% on both sides
#	sexprs <- gsub("`r[ /t]([^`]*)`", "%@%SEXPR%@%\\1%@%SEXPR%@%", Rscript[inDoc])
#	## Then, split the strings on this tag
#	sexprs <- strsplit(sexprs, "%@%SEXPR%@%", fixed = TRUE)
	## Now, all even items in the list contain Sexpr... replace } by \} there,
	## if } is not already escaped
	## Note also that if the Sexpr was at the end of the string, we need to
	## append "" to it, in order to be able to put end delimiter at next step
	## Also, glue together the pieces by using \Sexpr{ and } as delimiters
#	Rscript[inDoc] <- sapply(sexprs, function (x) {
#		l <- length(x)
#		if (!l) return("")
#		evenPos <- !(1:l %% 2)
#		x[evenPos] <-  paste0("\\Sexpr{", gsub("[\\\\]?([{}])", "\\\\\\\\\\1", x[evenPos]),
#			"}")
#		paste(x, collapse = "")
#	})

	## Convert from R markdown latex equations to AsciiDoc version
	## \[ ... \] => ++++\n<center>$ ... $</center>\n++++ for display equations
	Rscript[inDoc] <- gsub('^[ \t]*\\\\\\[', '+++<center>$', Rscript[inDoc])
	Rscript[inDoc] <- gsub('^[ \t]*\\\\\\]', '$</center>+++', Rscript[inDoc])
	## Note: for reasons I don't know, this does not work:  $$latex ... $$ into ++++\n<center>$ ... $</center>\n++++
	## $$latex ... $$ into +++<center>$ ... $</center>+++
	## TODO: eliminate this!
	#Rscript[inDoc] <- gsub('^[ \t]*\\$\\$latex', '+++<center>$', Rscript[inDoc])
#	Rscript[inDoc] <- gsub('^[ \t]*\\$\\$', '$</center>+++', Rscript[inDoc])
	## \( ... \) => +++$ ... $+++ for inline equations
	Rscript[inDoc] <- gsub('\\\\\\(', '+++$', Rscript[inDoc])
	Rscript[inDoc] <- gsub('\\\\\\)', '$+++', Rscript[inDoc])
	## $latex ... $ into +++$ ... $+++
	## TODO: eliminate this
	#Rscript[inDoc] <- gsub('\\$latex ([^$]+)\\$', '+++$\\1$+++', Rscript[inDoc])
	
	
	## Eliminate spaces and tabs between `` and <code> and ``
	## => ``code`` (markdown allows but ignores spaces and tabs... this is
	## to allow  backquotes inside code!). This is tricky, but here it is!
	## TODO: not good solution => solved in asciidoc.conf for single space inside `` code ``
#	Rscript[inDoc] <- gsub("``[ \t]*([^ ]*( (?![ \t]*``)[^ ]*)*)[ \t]*``", "``\\1``",
#		Rscript[inDoc], perl = TRUE)
	
	## Convert comments blocks using four or more #### by ////
	## No, since # is for title now
#	Rscript[inDoc] <- gsub("^####+$", "////", Rscript[inDoc])
	
	## Convert line comments using ## by __
	## NO! Now, it is //, since # is for titles
#	Rscript[inDoc] <- gsub("^##", "__", Rscript[inDoc])
	
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

## TODO: use figs.dir!!!
svDocRender <- function (svDocFile, theme, format, show.it, figs.dir,
keep.RnwFile, keep.TxtFile, encoding, asciidoc)
{
	## If svDocFile is missing, try to get it from option or the command line
	if (missing(svDocFile)) svDocFile <- .svDocFile()
	svDocFile <- normalizePath(svDocFile)
	
	## RnwFile is either same place, same name as svDocFile, or option Rnw.file
	RnwFile <- getOption("Rnw.file", .fileExt(svDocFile, "Rnw"))

	## TODO: use .adoc instead as extention!!!
	## TxtFile is from option, or from SciViews session directory structure
	## or at the same location as the svDocFile
	TxtFile <- getOption("Txt.file", .fileExt(svDocFile, "txt"))
	ReportDir <- .svSessionDirs(svDocFile)$reportdir
	if (length(ReportDir)) {
		TxtFile <- file.path(ReportDir, basename(TxtFile))
	} else TxtFile <- TxtFile
	## Make sure this is not an old file
	unlink(TxtFile)
	
	## If figs.dir is defined (default to 'figures'), make sure it exists
	if (missing(figs.dir)) figs.dir <- getOption("svDoc.figs.dir", "figures")
	if (length(figs.dir)) {
		figs.dir <- file.path(dirname(TxtFile), figs.dir)
		if (!file.exists(figs.dir)) {
			dir.create(figs.dir, showWarnings = FALSE, recursive = TRUE)
		} else figs.dir <- NULL # Avoid eliminating a dir that already exists!
	}
	
	## If format is missing, try getting it from options(), or assume "html"
	## TODO: get it from the document itself!!!
	if (missing(format)) format <- getOption("svDoc.format", "html")
	## The resulting file extension depends on the format used
	## Note that EndFile is always at same location as TxtFile
	EndExt <- switch(format,
		html = "html",
		html11 = "html",
		html5 = "html",
		html4 = "html",
		slidy = "html",
		slidy2 = "html",
		docbook = "xml",
		docbook45 = "xml",
		latex = "tex",
		odt = "odt",
		stop("Unknown format,",
			" use html/html4/html5/slidy/slidy2/wordpress/docbook/latex/odt")
		)
	EndFile <- .fileExt(TxtFile, EndExt)
		
	## If theme is missing, try getting it from options()
	if (missing(theme)) theme <- getOption("svDoc.theme", "sciviews")
	## If there is an initialization file for this theme, run it now
	## TODO...
		
	## Do we show the resulting Html file in the current browser at the end?
	## By default YES, unless in non-interactive mode
	if (missing(show.it)) show.it <- getOption("svDoc.show.it", interactive())
	
	## Do we keep intermediary .Rnw and .txt files? Default to FALSE
	if (missing(keep.RnwFile))
		keep.RnwFile <- getOption("svDoc.keep.RnwFile", FALSE)
	if (missing(keep.TxtFile))
		keep.TxtFile <- getOption("svDoc.keep.TxtFile", FALSE)
	
	## Get encoding... should be UTF-8 for usual SciViews doc
	## and make sure to configure the system as UTF-8 (except on Windows)
	if (missing(encoding)) encoding <- getOption("svDoc.encoding", "UTF-8")
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
		system.file("asciidoc", "asciidoc.py", package = "svDoc",
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
	svDocToRnw(svDocFile = svDocFile, RnwFile = RnwFile, encoding = encoding)
	if (!file.exists(RnwFile))
		stop("Problems while creating the R noweb file(", RnwFile, ")")
	
	## Copy it to where the Txt file must be created...
	if (dirname(TxtFile) != dirname(RnwFile)) {
		RnwFile2 <- file.path(dirname(TxtFile), basename(RnwFile))
		file.copy(RnwFile, RnwFile2, overwrite = TRUE)
		if (!file.exists(RnwFile2))
			stop("Problems while copying the R noweb file(", RnwFile, " to ",
				dirname(TxtFile), ")")
		unlink(RnwFile)
	} else RnwFile2 <- RnwFile
	
	## Sweave that document to .txt file
	## Note that the ascii package must be loaded first!
	req <- base::require
	req(ascii, quietly = TRUE, warn.conflicts = FALSE)
	odir <- setwd(dirname(RnwFile2)) # Work now relative to destination file
	## Also display warnings immediately
	owarn <- options(warn = 1)
	
	## Make sure intermediary filles will be deleted on exit
	on.exit({
		setwd(odir)
		## Possibly delete intermediary files
		if (!isTRUE(keep.RnwFile)) unlink(RnwFile2)
		if (!isTRUE(keep.TxtFile)) unlink(TxtFile)
		## If figs.dir is empty, delete it
		if (length(figs.dir) && !length(dir(figs.dir, include.dirs = TRUE)))
			unlink(figs.dir, recursive = TRUE)
		## Restore warn option
		options(owarn)
	}, add = TRUE)
	
	## Sweave this document... (creating the TxtFile)
	## Note: we change some default options here!
	Asciidoc(RnwFile2, encoding = encoding, prefix.string = "figures/fig",
		width = 7.2, height = 7.2, png = TRUE, jpeg = FALSE, format = "png")
	
	if (!file.exists(TxtFile))
		stop("Problems while creating the Asciidoc file (", TxtFile, ")")
	
	## Do we use a particular theme with Asciidoc
	## I have got problem with `var` insode code blocks that are interpreted as
	## equations by MathML => do not use it!!!
	#if (theme == "classic") {
	#	opts <- paste('" -b ', format, ' -a asciimath -a caption "', sep = "")
	#} else {
	#	opts <- paste('" -b ', format, ' -a asciimath -a caption --theme=',
	#		theme, '@ "', sep = "")
	#}
	if (theme == "classic") {
		opts <- paste('" --unsafe -b ', format, ' -a latexmath -a caption "', sep = "")
	} else {
		opts <- paste('" --unsafe -b ', format, ' -a latexmath -a caption --theme=',
			theme, '@ "', sep = "")
	}

	## Use AsciiDoc to convert the .txt file into an .html file
	cat("Running asciidoc to create ", basename(EndFile), "\n", sep = "")
	system(paste('"', python, '" "', asciidoc, opts, TxtFile, '"', sep = ""))
	
	## Special case for 'odt': the file created has .fodt extension
	## and we want to rename it with an .odt extension
	if (format == "odt") {
		TempFile <- sub("\\.fodt$", ".odt", EndFile)
		if (file.exists(TempFile)) file.rename(TempFile, EndFile)
	}
		
	## If there is a finalize code for this theme, run it now
	## TODO...

	## Check that the final file exists!
	if (!file.exists(EndFile))
		stop("Asciidoc was unable to format your document")
	
	## Do we view the resulting .html file?
	if (isTRUE(show.it) && EndExt == "html") {
		cat("Opening the formatted document", basename(EndFile),
			"in the Web browser\n")
		browseURL(normalizePath(EndFile))
	} else cat("Formatted document available at ", EndFile, "\n", sep = "")
	invisible(EndFile)
}

svDocThemes <- function ()
{
	themesDir <- file.path(dirname(system.file("asciidoc", "asciidoc.py",
		package = "svDoc")), "themes")
	c("classic", dir(themesDir, include.dirs = TRUE))
}

render... <- function (svDocFile, encoding)
{
	## A function to run an a SciViews doc file, and that looks at the #!
	## line to determine what function to run for compiling the final document

	## If svDocFile is missing, try to get it from option or the command line
	if (missing(svDocFile)) svDocFile <- .svDocFile()
	
	## Check svDocFile
	if (missing(svDocFile) || !length(svDocFile)) stop("No file provided")
	if (!file.exists(svDocFile)) stop("svDocFile not found (", svDocFile, ")")
	svDocFile <- normalizePath(svDocFile)
	
	## Get encoding
	if (missing(encoding)) encoding <- getOption("svDoc.encoding", "UTF-8")	
	
	## Check that it is a R script file (first line starting with #!)
	Rscript <- readLines(svDocFile, n = 1L, encoding = encoding)
	if (!grepl("^#!", Rscript))
		stop("Incorrect SciViews doc file (it must start with #!)")

	## Decrypt first line to know what function to run to make this file
	cmd <- sub("^#!.+ -e[ \t]*(.+)$", "\\1", Rscript)
	if (cmd == Rscript) stop("Malformed #! line in '", svDocFile, "'")
	
	## Eliminate possible quotes around the command and trailing spaces
	cmd <- sub("[ \t]+$", "", cmd)
	cmdNoQuotes <- sub("^'(.+)'$", "\\1", cmd) # Single quotes
	if (cmdNoQuotes == cmd)
		cmdNoQuotes <- sub('^"(.+)"$', "\\1", cmd) # Double quotes
	
	## Pass the file name to the build procedure
	ofile <- options(svDoc.file = svDocFile)$svDoc.file
	oencoding <- options(svDoc.encoding = encoding)$svDoc.encoding
	on.exit(options(svDoc.file = ofile, encoding = oencoding))
	
	## If the command is me (svDoc::render...), then call svDocRender()
	if (cmdNoQuotes == "svDoc::render...") {
		svDocRender()
	} else {
		## Run that command, first replacing svDoc::render... by svDocRender
		cmdNoQuotes <- gsub("svDoc::render\\.\\.\\.", "svDoc::svDocRender",
			cmdNoQuotes)
		cmd <- try(parse(text = cmdNoQuotes))
		if (!inherits(cmd, "try-error")) eval(cmd, envir = parent.frame())
	}
}

class(render...) <- c("renderer", "function")

print.renderer <- function (x, ...) unclass(x)()

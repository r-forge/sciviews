## TODO: see the tables package for better looking tables, including in LaTeX!
## TODO: merge both functions and use a tag in the document to decide
##       if using sweave or knitr

weaveLyxRnw <- function (file, driver = RweaveLatex(),
syntax = getOption("SweaveSyntax"), encoding = "UTF-8", width = 80,
useFancyQuotes = TRUE, ...)
{
	## Run in LyX as the Sweave -> LaTex (from Sweave|pdflatex|plain) converter:
	##> R -e svSweave::weaveLyxRnw(\"$$i\"[,driver=highlight::HighlightWeaveLatex()]) -q --vanilla

	## Switch encoding (we do work with UTF-8 by default)
	oenc <- options(encoding = encoding)
	on.exit(options(encooding = oenc))
	Sys.setlocale("LC_CTYPE", "UTF-8")

	## By default, use fancy quotes
	ofc <- options(useFancyQuotes = useFancyQuotes)
	on.exit(options(useFancyQuotes = ofc), add = TRUE)
	
	## Set default width for text to a reasonable value
	owidth <- options(width = width)
	on.exit(options(width = owidth), add = TRUE)

	## Issue warnings immediately
	owarn <- options(warn = 1)
	on.exit(options(warn = owarn), add = TRUE)

	## Process 'file'
	if (!file.exists(file)) {
		stop("You must provide the name of an existing .Rnw file to process!")
	} else {
		## Redirect output
		unlink("/tmp/.lyxSweave.log")
		on.exit({
			## Echo results
			sink(type = "message")
			sink()
			try(cat(readLines("/tmp/.lyxSweave.log"), sep = "\n"), silent = TRUE)
		}, add = TRUE)
		con <- file("/tmp/.lyxSweave.log", open = "wt")
		sink(con)
		sink(con, type = "message")
		cat("Weaving ", basename(file), " ...\n", sep = "")
		
		## Clean the R noweb file
		cleanLyxRnw(file, encoding = encoding)
		
		## Weave the file
		Sweave(file, driver = driver, syntax = syntax, ...)
	}
}

knitLyxRnw <- function (file, encoding = "UTF-8", width = 80,
useFancyQuotes = TRUE, ...)
{
	## Run in LyX as the Sweave -> LaTex (from Sweave|pdflatex|plain) converter:
	##> R -e svSweave::knitLyxRnw(\"$$i\") -q --vanilla

	## Switch encoding (we do work with UTF-8 by default)
	oenc <- options(encoding = encoding)
	on.exit(options(encooding = oenc))
	Sys.setlocale("LC_CTYPE", "UTF-8")

	## By default, use fancy quotes
	ofc <- options(useFancyQuotes = useFancyQuotes)
	on.exit(options(useFancyQuotes = ofc), add = TRUE)
	
	## Set default width for text to a reasonable value
	owidth <- options(width = width)
	on.exit(options(width = owidth), add = TRUE)

	## Issue warnings immediately
	owarn <- options(warn = 1)
	on.exit(options(warn = owarn), add = TRUE)

	## Process 'file'
	if (!file.exists(file)) {
		stop("You must provide the name of an existing .Rnw file to process!")
	} else {
		## Redirect output
		unlink("/tmp/.lyxSweave.log")
		on.exit({
			## Echo results
			sink(type = "message")
			sink()
			try(cat(readLines("/tmp/.lyxSweave.log"), sep = "\n"), silent = TRUE)
		}, add = TRUE)
		con <- file("/tmp/.lyxSweave.log", open = "wt")
		sink(con)
		sink(con, type = "message")
		cat("Weaving ", basename(file), " with knitr...\n", sep = "")
		
		## Clean the R noweb file
		cleanLyxRnw(file, encoding = encoding)
		
		## Weave the file using knitr
		knit(file, ...)
	}
}

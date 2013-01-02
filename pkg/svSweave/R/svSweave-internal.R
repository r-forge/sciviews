.onLoad <- function (lib, pkg)
{
	## Look for a suitable python executable
	py <- .python()
	if (!is.null(py)) options(python = py)
}

.packageName <- "svSweave"

.fileExt <- function (file, extension)
{
	## Change the extension of a file
	file <- sub("\\.[^\\.]*$", "", file)
	paste(file, extension, sep = ".")
}

.RdocFile <- function ()
{
	## Try to get RdocFile from option or the command line
	## Note: the file from the command line is for #! scripts!
	RdocFile <- getOption("Rdoc.file", NULL)
	if (is.null(RdocFile)) RdocFile <- commandArgs(TRUE)[1] # If #! script
	if (!length(RdocFile) || !file.exists(RdocFile))
		stop("RdocFile not found (", RdocFile, ")")
	return(normalizePath(RdocFile, winslash = "/"))
	
}

.svSessionDirs <- function (file, ensure.exist = TRUE)
{
	## Get the structure of the current session, giving a file or dir
	## in the base directory or a child directory of a SciViews session
	if (!file.exists(file))
		stop("File not found (", file, ")")
	if (file.info(file)$isdir) {
		dir <- file
	} else {
		dir <- dirname(file)
		if (dir == ".") dir <- getwd()
	}
	
	## Look if these is a .svData file there or in the parent dir
	if (file.exists(svDataFile <- file.path(dir, ".svData"))) {
		baseDir <- normalizePath(dir, winslash = "/") 
	} else if (file.exists(svDataFile <- file.path(dirname(dir), ".svData"))) {
		baseDir <- normalizePath(dirname(dir), winslash = "/")
	} else { # Apparently not a SciViews session
		return(list(basedir = character(0), datadir = character(0),
			scriptdir = character(0), reportdir = character(0)))
	}
	
	## Read the .svData file and get datadir, scriptdir and reportdir
	svData <- strsplit(suppressWarnings(
		readLines(svDataFile)), "=", fixed = TRUE)
	items <- sapply(svData, function (x) sub("^ *", "", sub(" *$", "", x[1])))
	values <- lapply(svData, function (x) sub("^ *", "", sub(" *$", "",
		paste(x[-1], collapse = "="))))
	names(values) <- items
	
	## Rework svData to have a list of base, data, script & report absolute dirs
	svNames <- c("basedir", "datadir", "scriptdir", "reportdir")
	svDirs <- values[svNames]
	names(svDirs) <- svNames
	
	## Combine these to get absolute paths
	svDirs <- lapply(svDirs, function (x) if (!length(x)) baseDir else
		file.path(baseDir, x))
	
	## Make sure these paths exist
	if (isTRUE(ensure.exist))
		lapply(svDirs, dir.create, showWarnings = FALSE, recursive = TRUE)

	## Returns this list of paths
	return(svDirs)
}

.python <- function (min.version = 2.4)
{
	## Try getting a valid python executable, with version at least min.version
	.pyCheck <- function (py, min.version = min.version) {
		if (Sys.which(paste('"', py, '"', sep = "")) == "")
			return(FALSE) # Not found
		## Check version...
		## The following is obvious, but does not work in Rterm.exe (stdout is
		## *not* redirected to stdin there!)
		#pyVersion <- sub("^Python ", "",
		#	system(paste('"', py, '" --version 2>&1', sep = ""), intern = TRUE))
		pyVersion <- sub("^([^ ]+).*$", "\\1", system(paste('"', py,
			'" -c "import sys; print sys.version"', sep = ""),
			intern = TRUE)[1])
		res <- try(suppressWarnings(compareVersion(pyVersion, "2.4") > 0),
			silent = TRUE)
		## If there is an error, by-pass version checking and just look if
		## the file is there (sometimes it fails on Windows)
		if (inherits(res, "try-error")) res <- file.exists(py)
		return(as.logical(res)[1])
	}
	
	## Try easiest first!
	py <- Sys.getenv("python")
	if (py == "") py <- "python"
	if (.pyCheck(py)) return(py)
	
	## If Komodo Edit/IDE is installed, it comes with a suitable Python version
	ko <- Sys.which("komodo")
	if (ko == "") return(NULL)

	## This is a symlink on Linux & Mac OS X => get original executable
	ko2 <- Sys.readlink(ko)	
	if (ko2 != "") koDir <- dirname(ko2) else koDir <- dirname(ko)
	
	## Python executable can be located at different places, relative to komodo
	py <- file.path(koDir, "mozpython") # On Mac OS X
	if (!file.exists(py)) # On Windows
		py <- file.path(dirname(koDir), "python", "python.exe")
	if (!file.exists(py)) # On Linux
		py <- file.path(dirname(koDir), "lib", "python", "bin", "python")
	if (!file.exists(py)) return(NULL)

	## Recheck now...
	if (.pyCheck(py)) return(py) else return(NULL)
}

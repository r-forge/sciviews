## Define the S3 method
dlgDir <- function (default = getwd(), message, ..., gui = .GUI) {
	if (!gui$startUI("dlgDir", call = match.call(), default = default,
		msg = "Displaying a modal dir selection dialog box",
		msg.no.ask = "A modal dir selection dialog box was by-passed"))
		return(invisible(gui))
	
	## Check and rework main arguments and place them in gui$args
	if (!is.null(default) && !inherits(default, "character") &&
		length(default) != 1)
        stop("'default' must be a length 1 character string or NULL")
	if (is.null(default)) default <- getwd()
    if (file.exists(default)) {
        if (!file.info(default)$isdir)
            stop("'default' must be a directory, not a file!")
    }
	default <- path.expand(default)
	## Under Windows, it uses \\ as separator, although .Platform$file.sep
	## is now / (tested in R 2.11.1) => replace it
	if (.Platform$OS.type == "windows")
		default <- gsub("\\\\", "/", default)
	if (missing(message) || message == "") message <- "Choose a directory" else
		message <- paste(message, collapse = "\n")
	gui$setUI(args = list(default = default, message = message))
	
	## ... and dispatch to the method
	UseMethod("dlgDir", gui)
}

## Used to break the chain of NextMethod(), searching for a usable method
## in the current context
dlgDir.gui <- function (default = getwd(), message, ..., gui = .GUI) {
	msg <- paste("No workable method available to display a dir selection dialog box using:",
		paste(guiWidgets(gui), collapse = ", "))
	gui$setUI(status = "error", msg = msg, widgets = "none")
	stop(msg)
}

## The pure textual version used a fallback in case no GUI could be used
dlgDir.textCLI <- function (default = getwd(), message, ..., gui = .GUI)
{
	gui$setUI(widgets = "textCLI")
	## Ask for the directory
	res <- readline(paste(gui$args$message, " [", gui$args$default, "]: ",
		sep = ""))
	if (res == "") res <- gui$args$default else res <- res
	## To get the same behaviour as the GUI equivalents, we must make sure
	## it is a directory, or try to create it (possibly recursively, if it
	## does not exist). Also return absolute path
	if (file.exists(res)) {
		## Check that this is a directory, not a file!
		if (!file.info(res)$isdir) {
			warning(res, " is not a directory")
			res <- character(0) # Same as if the user did cancel the dialog box
		}
	} else {
		## The directory does not exists, try to create it now...
		dir.create(res, recursive = TRUE)
		if (!file.exists(res) || !file.info(res)$isdir) {
			warning("Error while creating the directory ", res)
			res <- character(0)
		}
	}
	if (length(res)) res <- normalizePath(res)
	gui$setUI(res = res, status = NULL)
	return(invisible(gui))
}

## The native version of the input box
dlgDir.nativeGUI <- function (default = getwd(), message, ..., gui = .GUI)
{
	gui$setUI(widgets = "nativeGUI")
	## A 'choose a directory' dialog box
    ## It almost follows the conventions of tkchooseDirectory()
    ## The argument default indicates the initial directory
    ## If cancelled, then return character(0)
    ## This dialog box is always modal
	##
	## It is a replacement for choose.dir(), tk_choose.dir() & tkchooseDirectory()
	res <- switch(Sys.info()["sysname"],
		Windows = .winDlgDir(gui$args$default, gui$args$message),
		Darwin = .macDlgDir(gui$args$default, gui$args$message),
		.unixDlgDir(gui$args$default, gui$args$message)
	)
	
	## Do we need to further dispatch?
	if (is.null(res)) NextMethod("dlgDir", gui) else {
		gui$setUI(res = res, status = NULL)
		return(invisible(gui))
	}
}

## Windows version
.winDlgDir <- function (default = getwd(), message = "")
{
	res <- choose.dir(default = default, caption = message)
    if (is.na(res)) res <- character(0) else res <-  gsub("\\\\", "/", res)
	return(res)
}

## Mac OS X version
.macDlgDir <- function (default = getwd(), message = "")
{
    ## Display a modal directory selector with native Mac dialog box
	if (.Platform$GUI == "AQUA") app <- "(name of application \"R\")" else
		app <- "\"Terminal\""
	## Avoid displaying warning message when the user clicks on 'Cancel'
	owarn <- getOption("warn")
	on.exit(options(warn = owarn))
	options(warn = -1)
	if (message == "") mcmd <- "" else mcmd <- paste("with prompt \"",
		message, "\" ", sep = "")
	cmd <- paste("-e 'tell application ", app,
		" to set foldername to choose folder ", mcmd, "default location \"",
		default , "\"' -e 'POSIX path of foldername'", sep = "")
	## For some reasons, I cannot use system(intern = TRUE) with this in R.app/R64.app
	## (deadlock situation?), but I can in R run in a terminal. system2() also
	## works, but this preclue of using svDialogs on R < 2.12.0.
	## The hack is thus to redirect output to a file, then, to read the content
	## of that file and to desctroy it
	tfile <- tempfile()
	on.exit(unlink(tfile))
	res <- try(system(paste("osascript", cmd, ">", tfile), wait = TRUE,
		intern = FALSE, ignore.stderr = TRUE), silent = TRUE)
	if (inherits(res, "try-error") || !length(res)) return(character(0))
	if (res > 0) return(character(0)) # User cancelled input
	res <- readLines(tfile)
	#res <- sub("^text returned:", "", res)
	#res <- sub(", button returned:.*$", "", res)
	#res <- paste(res, collapse = " ")
	return(res)	
}

## Linux/Unix version
.unixDlgDir <- function (default = getwd(), message = "")
{
    ## zenity must be installed on this machine!
    if (Sys.which("zenity") == "") return(NULL)
    ## Avoid displaying warning message in case user clicks on Cancel
    owarn <- getOption("warn")
    on.exit(options(warn = owarn))
    options(warn = -1)
    ## Use zenity to display the directory selection
	## There is no message area here, but one can set the title
	if (message == "") {
		message <- "Choose a directory" # Default message
	} else {
		## Determine if the message is multiline...
		if (regexpr("\n", message) > 0) {
			## Try to use a notification instead
			if (Sys.which("notify-send") != "") {
				system(paste("notify-send --category=\"R\"",
					" \"R message\" \"", message, "\"", sep = ""), wait = FALSE)
				message <- "Choose folder"			
			} # Else the wole message cannot be displayed!!
		}
	}
    msg <- paste("zenity --file-selection --title=\"", message,
	"\" --directory --filename=\"", default, "\"", sep = "")
    res <- system(msg, intern = TRUE)
    return(res)	
}

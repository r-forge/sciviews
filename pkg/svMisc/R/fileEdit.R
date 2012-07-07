fileEdit <- function (file, template = NULL, replace = FALSE, wait = FALSE,
editor = getOption("fileEditor"))
{
	## Fallback to "editor", in case no fileEditor is provided
	if (isWin()) {
		if (!length(editor)) editor <- getOption("editor")
	} else if (!grepl("%s", editor)) {
		cmd <- paste('which ', '"', editor, '"', sep = "")
		if (!length(system(cmd, intern = TRUE))) {
			## Fall back to the default editor (if any)
			editor <- getOption("editor")
		}	
	}
	
	## If the file does not exists, create one (possibly from template)
	if (isTRUE(replace) || !file.exists(file)) {
		if (!length(template)) {
			file.create(file)
		} else if (file.exists(template)) {
			file.copy(template, file, overwrite = TRUE, copy.mode = FALSE)
		} else { # Template file not found!
			warning("Template file '", template,
				'" not found, starting from an empty file')
			file.create(file)
		}
	}

	if (!interactive() || editor == "") {
		## Do nothing, issue, a warning!
		warning("Cannot edit '", basename(file),
			"': no editor or not in interactive mode")
		return(FALSE)
	} else {
		if (grepl("%s", editor)) {
			cmd <- sprintf(editor, normalizePath(file))
		} else {
			cmd <- paste('"', editor, '" "', normalizePath(file), '"', sep = "")
		}
		wait <- isTRUE(as.logical(wait))
		if (wait) {
			message("Editing the file '", basename(file),
			"'... Close the editor to continue!")
			flush.console()
		}
		if (isWin()) {
			res <- try(system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE,
				wait = wait, minimized = FALSE, invisible = FALSE,
				show.output.on.console = FALSE), silent = TRUE)
		} else {
			res <- try(system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE,
				wait = wait), silent = TRUE)
		}
		return(invisible(!inherits(res, "try-error")))
	}
}
 
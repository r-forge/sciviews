### Tries to parse a file
### Romain Francois <francoisromain@free.fr>
tryParse <- function (file, action, encoding = getOption("encoding"))
{	
	if (is.character(file)) {
		filename <- file
		file <- file(filename, encoding = encoding)
		on.exit(close(file))
	} else {
		filename <- summary(file)$description
	}
	
	out <- try(parse(file), silent = TRUE)
	if (inherits(out, "try-error")) {
		err <- parseError(out)
		if (is.na(err$file[1])) err$file <- rep(filename, nrow(err))
		if (!missing(action)) action(err)
		return(invisible(err))
	} else return(invisible(out))  
}

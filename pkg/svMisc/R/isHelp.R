"isHelp" <-
function (topic, package = NULL, lib.loc = NULL)
{
	# Code taken from example(), but here we don't run the example!
	topic <- substitute(topic)
    if (!is.character(topic))
        topic <- deparse(topic)[1]
    INDICES <- .find.package(package, lib.loc, verbose = FALSE)
    file <- index.search(topic, INDICES, "AnIndex", "R-ex")
    # Neither help, nor example
	if (file == "") return(c(help = FALSE, example = FALSE))
    packagePath <- dirname(dirname(file))
    if (length(file) > 1) {
        packagePath <- packagePath[1]
        file <- file[1]
    }
    pkg <- basename(packagePath)
    lib <- dirname(packagePath)
    zfile <- zip.file.extract(file, "Rex.zip")
    if (zfile != file) on.exit(unlink(zfile))
    # Help but no example
	if (!file.exists(zfile)) return(c(help = TRUE, example = FALSE))
	# Both help and example
	return(c(help = TRUE, example = TRUE))
}

isHelp <- function (topic, package = NULL, lib.loc = NULL)
{
	## Code taken from example(), but here we don't run the example!
	topic <- substitute(topic)
    if (!is.character(topic))  topic <- deparse(topic)[1L]
    pkgpaths <- .find.package(package, lib.loc, verbose = FALSE)
    file <- utils:::index.search(topic, pkgpaths, TRUE)
    if (!length(file)) return(c(help = FALSE, example = FALSE))
    
	packagePath <- dirname(dirname(file))
    pkgname <- basename(packagePath)
    lib <- dirname(packagePath)
    encoding <- NULL
    tf <- tempfile("Rex")
	on.exit(unlink(tf))
    encoding <- "UTF-8"
    tools::Rd2ex(utils:::.getHelpFile(file), tf)
    if (!file.exists(tf)) {
        return(c(help = TRUE, example = FALSE))
    } else return(c(help = TRUE, example = TRUE))
}

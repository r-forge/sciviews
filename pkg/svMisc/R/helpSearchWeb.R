"helpSearchWeb" <-
function (apropos, type = c("google", "archive", "wiki"), browse = TRUE)
{
	apropos <- paste(apropos, collapse = " ", sep = "")
	apropos <- gsub(" ", "+", apropos)
	type <- type[1]
	RSearchURL <- switch(type,
		"google" = paste("http://www.google.com/search?sitesearch=r-project.org&q=",
			apropos, sep = ''),
		"archive" = paste("http://www.google.com/u/newcastlemaths?q=",
			apropos, sep = ''),
		"wiki" = paste("http://wiki.r-project.org/rwiki/doku.php?do=search&id=",
			apropos, sep = ''),
		stop("'type' could be only 'google', 'archive' or 'wiki', currently!"))
	if (browse) browseURL(RSearchURL)
	return(invisible(RSearchURL))
}

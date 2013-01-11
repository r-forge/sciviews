## Create an Asciidoc header according to these items

header <- function (title, author = NULL, email = NULL, revnumber = NULL,
revdate = NULL, revremark = NULL, copyright = "cc-by", encoding = "UTF-8",
lang = "en", pagetitle = NULL, description = "SciViews document", keywords = NULL,
format = NULL, theme = "sciviews", max.width = 640, width = NULL,
toc = c("top", "side", "manual", "none"), toc.title = NULL, toclevels = 2,
numbered = TRUE, data.uri = TRUE, frame = "topbot", grid = "rows",
align = "center", halign = "center", pygments = FALSE, slidefontsizeadjust = 0,
SweaveInit = { options(width = 80); options(SweaveHooks = list(fig = function()
par(col.lab = "#434366", col.main = "#434366"))) }
)
{
	## Format Asciidoc attributes
	asciiAttr <- function (header = NULL, name, value) {
		if (!length(value)) return(header)
		paste0(header, ":", name, ": ", paste(value, collapse = ","), "\n")
	}
	
	## Create the Asciidoc header
	header <- character(0)
	
	## Title must be a single string and start with '= '
	if (length(title)) header <- paste0(as.character(title)[1], "\n")
	if (substring(header, 1, 2) != "= ") header <- paste("=", header)
	
	## Idem for author, but allow several names
	if (length(author)) {
		author <- paste(author, collapse = ", ")
	
		## Check also email
		if (length(email)) {
			email <- as.character(email)[1]
			if (!grepl("^.+@.+$", email))
				stop("You must provide a correct email address for your svDoc")
			header <- paste0(header, author, " <", email, ">\n")
		} else {
			header <- paste0(header, author, "\n")	
		}
	}
	
	## Compute revision field: [revnumber], [revdate]:\n[revremark]
	## TODO: check all this in function of all possible missing items
	if (length(revnumber) || length(revdate) || length(revremark)) {
		if (length(revnumber))
			revfield <- paste0("v", revnumber, ", ") else revfield <- ""
		if (!length(revdate)) revdate <- format(Sys.Date(), format = "%B %Y")
		revfield <- paste0(revfield, revdate)
		if (length(revremark))
			revfield <- paste0(revfield, ":\n", paste(revremark, collapse = "\n"))
		header <- paste0(header, revfield, "\n")
	}
	
	## Rework copyright
	if (length(copyright)) {
		if (!grepl("^[^,]+,[^,]+,[ \t]*[0-9]{4}$", copyright)) {
			if (length(revdate)) {
				year <- substring(revdate, nchar(revdate) - 3)
			} else year <- format(Sys.Date(), format = "%Y")
			if (!length(author)) {
				copyright <- paste0(copyright, ", ", year)	
			} else {
				copyright <- paste0(copyright, ", ", author, ", ", year)
			}
		}
		header <- asciiAttr(header, "copyright", copyright)
	}
	
	## Add more attributes
	header <- asciiAttr(header, "encoding", encoding)
	header <- asciiAttr(header, "lang", lang)
	header <- asciiAttr(header, "title", pagetitle)
	header <- asciiAttr(header, "description", description)
	header <- asciiAttr(header, "keywords", keywords)
	header <- asciiAttr(header, "format", format)
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
	## Are we currently building a dynamic document?
	if (svMisc::existsTemp(".build__dynamic__svDoc__"))
		header <- paste0(header, ":dynamic:\n")
	header <- paste0(header, "\n") # End of header section
	
	## Run SweaveInit now
	SweaveInit
	## More initialization (make sure svDoc and SciViews are attached)
	req <- base::require
	req("svSweave", quietly = TRUE, warn.conflicts = FALSE)
	
	## Print the header and return it invisibly
	cat(header)
	invisible(header)
}

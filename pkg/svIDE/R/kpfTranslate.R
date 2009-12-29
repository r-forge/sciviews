# Make a .pot file with translatable strings found in a Komodo project/package
# Translatable strings are:
# 1) All names
# 2) In snippets:
#    [[%ask:R-desc:XXX]]
#    [[%ask:R-tip:XXX]]
#    [[%ask|pref:URL-help:XXX]] and [[%ask|pref:RWiki-help:XXX]]
#    [[%tr:XXX]
# 3) In macros:
#    Strings inside _("XXX"), with _() being a function returning its argument
kpf2pot <- function (kpfFile, potFile) {
    if (missing(potFile)) 
        potFile <- sub("\\.kpf", ".pot", kpfFile)
	if (kpfFile == potFile)
		potFile <- paste(kpfFile, "pot", sep = ".")
	# Extract translatable strings from this file
	doc <- xmlRoot(xmlTreeParse(kpfFile))
	imax <- xmlSize(doc)
	if (imax < 1) stop("No node found in the file!")
	# Collect all strings to be translated
	s <- character(0)
	for (i in 1:imax) {
		n <- xmlGetAttr(doc[[i]], "name")
		if (!is.null(n)) {
			s <- c(s, n) 
			type <- xmlName(doc[[i]])
			# If this is a snippet, look for other translatable strings
			if (type == "snippet") {
				snip <- xmlValue(doc[[i]])
				chunks <- strsplit(snip, "\\[\\[|\\]\\]")[[1]]
				# Keep only chunks starting with R-desc:, R-tip:, URL-help:
				# RWiki-help: or %tr:
				chunks <- chunks[grep("^%ask:R-desc:|^%ask:R-tip:|^%ask:URL-help:|^%ask:RWiki-help:|^%pref:URL-help|^%pref:RWiki-help|%tr:", chunks)]
				# Are there any remaining chunks?
				l <- length(chunks)
				if (l > 0) {
					# Eliminate leading stuff
					chunks <- sub("^%ask:[^:]+:|%tr:", "", chunks)
					# and add to the list of items to translate
					s <- c(s, chunks)
				}
			} else if (type == "macro") {
				mac <- xmlValue(doc[[i]])
				# Collect tagged strings (i.e., strings inside _(...))
				repeat {
					str <- sub("^.*_\\(\"(.*[^\\\\])\"\\).*$", "\\1", mac)
					if (str == mac) break
					s <- c(s, gsub('\\\\"', '"', str))
					mac <- sub("^(.*)(_\\(\".*[^\\\\]\"\\))(.*)$",
						"\\1(...)\\3", mac)
				}
				repeat {
					str <- sub("^.*_\\('(.*[^\\\\])'\\).*$", "\\1", mac)
					if (str == mac) break
					s <- c(s, gsub("\\\\'", "'", str))
					mac <- sub("^(.*)(_\\('.*[^\\\\]'\\))(.*)$",
						"\\1(...)\\3", mac)
				}
			}
		}
	}
	# Keep only unique strings
	s <- unique(s)
	s <- s[nzchar(s)]
    tmp <- shQuote(encodeString(s), type = "cmd")
    con <- file(potFile, "wt")
    on.exit(close(con))
    writeLines(con = con, c("msgid \"\"", "msgstr \"\"",
		sprintf("\"Project-Id-Version: R %s.%s\\n\"", 
        R.version$major, R.version$minor),
		"\"Report-Msgid-Bugs-To: support@sciviews.org\\n\"", 
        paste("\"POT-Creation-Date: ", format(Sys.time(), "%Y-%m-%d %H:%M"), 
            "\\n\"", sep = ""),
		"\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"", 
        "\"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n\"", 
        "\"Language-Team: LANGUAGE <LL@li.org>\\n\"",
		"\"MIME-Version: 1.0\\n\"", 
        "\"Content-Type: text/plain; charset=utf-8\\n\"",
		"\"Content-Transfer-Encoding: 8bit\\n\"", 
        ""))
    for (e in tmp)
		writeLines(con = con, c("", paste("msgid", e), "msgstr \"\""))
	# Check that the .pot file is created
	return(invisible(file.exists(potFile)))	
}

kpz2pot <- function (kpzFile, potFile) {
    if (missing(potFile)) 
        potFile <- sub("\\.kpz", ".pot", kpzFile)
	if (kpzFile == potFile)
		potFile <- paste(kpzFile, "pot", sep = ".")
    # The kpz file is a zipped file containing package.kpf in a subdirectory
	f <- file.path(tempdir(), "package.kpf")
	unlink(f)	# Make sure the file does not exist yet
	unzip(kpzFile, junkpaths = TRUE, exdir = tempdir())
	if (!file.exists(file.path(tempdir(), "package.kpf")))
		stop("Impossible to extract the content of the .kpz file.")
	# Run kpf2pot() on this file
	kpf2pot(f, potFile)	
	# Delete extracted file
	unlink(f)
	# Check that the .pot file is created
	return(invisible(file.exists(potFile)))
}

kpfTranslate <- function (kpfFile, lang, poFile, kpf2File) {
    if (missing(lang))
		stop("You must provide 'lang' (ex.: 'fr', or 'de')")
	po <- paste("-", lang, ".po", sep = "")
	kpf2 <- paste("-", lang, ".kpf", sep = "")
	if (missing(poFile)) 
        poFile <- sub("\\.kpf", po, kpfFile)
	if (kpfFile == poFile)
		poFile <- paste(kpfFile, po, sep = "")
	if (!file.exists(poFile))
		stop("'poFile' not found!")
	if (missing(kpf2File)) {
		kpf2File <- sub("\\.kpf", kpf2, kpfFile)
		if (kpfFile == kpf2File)
			kpf2File <- paste(kpfFile, kpf2, sep = "")
		unlink(kpf2File)  # Make sure we create a new resulting file
	}
	
	# Read the content of the .po file
	tr <- readLines(poFile, encoding = "UTF-8")
	# Keep only lines starting with msgid or msgstr
	trid <- tr[regexpr("^msgid ", tr) == 1]
	trid <- sub("^msgid ", "", trid)
	trmsg <- tr[regexpr("^msgstr ", tr) == 1]
	trmsg <- sub("^msgstr ", "", trmsg)
	# Check that both trid and trmsg have same length
	if (length(trid) != length(trmsg))
		stop("Unequal number of id and translated strings in the .po file!")
	keep <- trid != "\"\""
	trid <- trid[keep]
	trmsg <- trmsg[keep]

	# We need to "unquote" the strings
	unquote <- function (s) {
		# Replace any \\\" by \"
		s <- gsub("\\\\\"", "\"", s)
		# Eliminate leading and trailing quotes
		s <- sub("^\"", "", s)
		s <- sub("\"$", "", s)
		return(s)
	}
	trid <- unquote(trid)
	trmsg <- unquote(trmsg)
	names(trmsg) <- trid
	
	# Extract translatable strings from the .kpf file
	doc <- xmlRoot(xmlTreeParse(kpfFile))
	imax <- xmlSize(doc)
	if (imax < 1) stop("No node found in the file!")
	# Collect all strings to be translated
	trans <- function (s) {
		tr <- as.character(trmsg[s])
		if (is.na(tr) || tr == "") return(s) else return(tr)
	}
	
	s <- character(0)
	for (i in 1:imax) {
		n <- xmlGetAttr(doc[[i]], "name")
		if (!is.null(n)) {
			# Replace name in attributes of this node
			node <- addAttributes(doc[[i]], name = trans(n), append = TRUE)
			type <- xmlName(node)
			# If this is a snippet, look for other translatable strings
			if (type == "snippet") {
				snip <- xmlValue(node)
				chunks <- strsplit(snip, "\\[\\[|\\]\\]")[[1]]
				# Translate chunks starting with R-desc:, R-tip:, URL-help:,
				# RWiki-help: or %tr:
				toTrans <- grep("^%ask:R-desc:|^%ask:R-tip:|^%ask:URL-help:|^%ask:RWiki-help:|^%pref:URL-help|^%pref:RWiki-help|%tr:", chunks)
				if (length(toTrans) > 0) {
					for (j in toTrans) {
						msg <- sub("^%ask:[^:]+:|%tr:", "", chunks[j])
						header <- sub("^(%ask:[^:]+:|%tr:).*$", "\\1", chunks[j])
						chunks[j] <- paste(header, trans(msg), sep = "")
					}
					# Reconstitute the snippet content using translated messages
					snip <- paste(chunks, c("[[", "]]"),
						sep = "", collapse = "")
					# We need to eliminate latest '[['
					snip <- sub("\\[\\[$", "", snip)
					xmlValue(node) <- snip
				}
			} else if (type == "macro") {
				mac <- xmlValue(node)
				# Translate tagged strings (i.e., strings inside _(...))
				repeat {
					str <- sub("^.*_\\(\"(.*[^\\\\])\"\\).*$", "\\1", mac)
					if (str == mac) break
					s <- trans(gsub('\\\\"', '"', str))
					s <- gsub('"', '\\"', s)
					mac <- sub("^(.*)(_\\(\".*[^\\\\]\"\\))(.*)$",
						paste("\\1%%%%%%(\"", s, "\")\\3", sep = ""), mac)
				}
				repeat {
					str <- sub("^.*_\\('(.*[^\\\\])'\\).*$", "\\1", mac)
					if (str == mac) break
					s <- trans(gsub("\\\\'", "'", str))
					s <- gsub("'", "\\'", s)
					mac <- sub("^(.*)(_\\('.*[^\\\\]'\\))(.*)$",
						paste("\\1%%%%%%('", s, "')\\3", sep = ""), mac)
				}
				mac <- gsub("%%%%%%", "_", mac)
				xmlValue(node) <- mac
			}
			# Replace the node with its translated version
			doc[[i]] <- node
		}
	}
	# In case the project has a name, we change it now
	projname <- xmlGetAttr(doc, "name")
	if (!is.null(projname))
		doc <- addAttributes(doc, name = basename(kpf2File), append = TRUE)
	
	# Save the translated XML content into the second .kpf file
	saveXML(doc, file = kpf2File, prefix = '<?xml version="1.0" encoding="UTF-8"?>\n<!-- Komodo Project File - DO NOT EDIT -->\n')
	# Check that the new .kpf file is produced
	return(invisible(file.exists(kpf2File)))	
}

kpzTranslate <- function (kpzFile, lang, poFile, kpz2File) {
    if (missing(lang))
		stop("You must provide 'lang' (ex.: 'fr', or 'de')")
	po <- paste("-", lang, ".po", sep = "")
	kpz2 <- paste("-", lang, ".kpz", sep = "")
	if (missing(poFile)) 
        poFile <- sub("\\.kpz", po, kpzFile)
	if (kpzFile == poFile)
		poFile <- paste(kpzFile, po, sep = "")
	if (!file.exists(poFile))
		stop("'poFile' not found!")
	if (missing(kpz2File))
		kpz2File <- sub("\\.kpz", kpz2, kpzFile)
	if (kpzFile == kpz2File)
		kpz2File <- paste(kpzFile, kpz2, sep = "")
	unlink(kpz2File)  # Make sure we create a new resulting file
	
    # The kpz file is a zipped file containing package.kpf in a subdirectory
	f <- file.path(tempdir(), "package.kpf")
	unlink(f)	# Make sure the file does not exist yet
	unzip(kpzFile, junkpaths = TRUE, exdir = tempdir())
	if (!file.exists(file.path(tempdir(), "package.kpf")))
		stop("Impossible to extract the content of the .kpz file.")
	
	# Call kpfTranslate on the created package.kpf file
	kpfTranslate(f, lang, poFile, f)
	
	# Compress the file in a kpz zipped archive named kpz2File
	# Create a directory of the same name as the package
	d <- sub("\\\\.kpz$", "", basename(kpz2File))
	d <- file.path(dirname(f), d)
	dir.create(d)
	# Move the package.kpf file there
	f2 <- file.path(d, "package.kpf")
	file.copy(f, f2)
	unlink(f)
	# Compress (zip) the directory
	odir <- getwd()
	on.exit(setwd(odir))
	setwd(dirname(kpz2File))
	# Note: the 'zip' program must be accessible!
	cmd <- paste('zip -rqm9 "', basename(kpz2File), '" "', d, '"', sep = "")
	try(system(cmd, intern = TRUE, wait = TRUE), silent = TRUE)
	# Check that the file is produced
	return(invisible(file.exists(kpz2File)))
}

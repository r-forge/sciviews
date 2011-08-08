options(json.method="R")

if("komodoConnection" %in% search()) detach("komodoConnection")
attach(new.env(), name="komodoConnection")

if(existsFunction("stopAllServers")) stopAllServers()
if(existsFunction("stopAllConnections")) stopAllConnections()

with(as.environment("komodoConnection"), {

	#`svOption` <- function (arg.name, default = NA, as.type = as.character, ...) {
	#	args <- gsub("\\b-\\b", ".", commandArgs(trailingOnly=TRUE))
	#
	#	pfx <- paste("^--", arg.name, "=", sep = "")
	#	x <- args[grep(pfx, args)]
	#
	#	x <- if (!length(x)) default else sub(pfx, "", x)
	#	x <- as.type(x, ...)
	#	x <- structure(list(x), names = arg.name)
	#	do.call("options", x)
	#	return(x)
	#}

	`svPager` <- function (files, header, title, delete.file) {
		files <- gsub("\\", "\\\\", files[1], fixed = TRUE)
		tryCatch(koCmd(sprintf('sv.r.pager("%1$s", "%2$s", %3$s)',
			 files, title, if (delete.file) 'true' else 'false')),
			error=function(e) browseURL(files, NULL))
	}

	`svBrowser` <- function(url) {
		url <- gsub("\\", "\\\\", url, fixed = TRUE)
		## If the URL starts with '/', assume a file path
		## on Unix or Mac and prepend 'file://'
		url <- sub("^/", "file:///", url)
		tryCatch(koCmd(sprintf("sv.command.openHelp(\"%s\")", url)),
			warning=function(e) browseURL(url, NULL)
			)
	}

	local({
		require(utils)
		`readline` <- function (prompt = "")
			paste(koCmd(sprintf("ko.dialogs.prompt('%s', '', '', 'R asked a question', 'R-readline')", prompt),
			timeout=0), collapse=" ")
		unlockBinding("readline", env=baseenv())
		bindingIsLocked("readline", env=baseenv())
		assign("readline", value=readline, envir = baseenv())
		utils::assignInNamespace("readline", value=readline, ns="base")
		lockBinding("readline", env=baseenv())
	})

	options(browser = svBrowser, pager = svPager)

	# a way round to get the url:
	#getHelpURL(help("anova")) <- old syntax
	#getHelpURL("anova") <- new syntax
	`getHelpURL` <- function(..., help_type = "html") {
		if(tools:::httpdPort == 0) suppressMessages(tools:::startDynamicHelp(TRUE))
		help_type <- "html"
		ret <- NULL
		oBrowser <- options(browser=function(url) ret <<- url)
		on.exit(options(oBrowser))
		if(mode((cl <- match.call())[[2]][[1]]) == "name") { # handle old syntax
			cl <- cl[[2]]
			cl$help_type <- help_type
			print(eval(cl, .GlobalEnv))
		} else {
			print(utils::help(..., help_type = help_type))
		}
		ret
	}

	require(utils)
	require(stats)


	env <- as.environment("komodoConnection")
	src <- dir(pattern="\\.R$")
	lapply(src[src != "init.R"], sys.source, envir=env)
	invisible()
})



#svOption("ko.port", as.type=as.numeric)
#svOption("ko.host", default="localhost")

.Last <- function() {
	try({
	stopAllServers()
	stopAllConnections()
	})
}


local({

port <- 1111L
while((port < 1115L) && (as.character(startServer(port)) == "0")) port <- port + 1L

cwd0 <- normalizePath(".")

#cat("cwd0 is ", sQuote(getwd()), "\n")

if(file.exists("init.R")) source("init.R")

Rservers <- enumServers()
if(is.numeric(getOption("ko.port")) && length(Rservers) > 0) {
	cat("Server started at port", Rservers, "\n")
	invisible(koCmd(paste(
		"sv.cmdout.append('R is started')",
		"sv.command.updateRStatus(true)",
		sprintf("sv.pref.setPref('sciviews.r.port', %s)", tail(Rservers, 1)),
		sep = ";")))
}

cat("cwd is now ", sQuote(getwd()), "\n")

## Do we have a .Rprofile file to source?
#rprofile <- file.path(c(getwd(), Sys.getenv("R_USER")), ".Rprofile")
cwd <- normalizePath(getwd())
isBaseDir <- file.exists(file.path(cwd, "sv-basedir")) || (cwd == cwd0)
rprofile <- file.path(c(if(!isBaseDir) getwd(), Sys.getenv("R_USER")), ".Rprofile")
rprofile <- rprofile[file.exists(rprofile)][1]

if (!is.na(rprofile)) {
	source(rprofile)
	cat("Loaded file:", rprofile, "\n")
}


if(!any(c("--vanilla", "--no-restore", "--no-restore-data") %in% commandArgs())
	&& file.exists(".RData")) {
	#sys.load.image(".RData", FALSE)
}
if(file.exists(".Rhistory")) loadhistory(".Rhistory")


#obj <- ls(.GlobalEnv)
#conflictObjs <- obj[obj %in% ls("komodoConnection")]
#
#if(length(conflictObjs) > 0) {
#	cat("Following objects in .GlobalEnv were conflicting and  should be removed: \n")
#	cat(sQuote(conflictObjs), "\n")
#	rm(list=conflictObjs, envir=.GlobalEnv, inherits=FALSE)
#}


})

#with(as.environment("komodoConnection"), {
#rm(getHelpURL,  envir=.GlobalEnv)
#})

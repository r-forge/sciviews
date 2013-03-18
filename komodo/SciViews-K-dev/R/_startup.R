options(json.method="R")

if(existsFunction("stopAllConnections")) stopAllConnections()
if(existsFunction("stopAllServers")) stopAllServers()

if("komodoConnection" %in% search()) detach("komodoConnection")
attach(new.env(), name = "komodoConnection")

with(as.environment("komodoConnection"), {



	`svPager` <- function (files, header, title, delete.file) {
		files <- gsub("\\", "\\\\", files[1L], fixed = TRUE)
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
			timeout=0), collapse = " ")
		unlockBinding("readline", env = baseenv())
		bindingIsLocked("readline", env = baseenv())
		assign("readline", value=readline, envir = baseenv())
		utils::assignInNamespace("readline", value=readline, ns = "base")
		lockBinding("readline", env = baseenv())
	})

	options(browser = svBrowser, pager = svPager)


	# a way round to get the url:
	#getHelpURL(help("anova")) <- old syntax
	#getHelpURL("anova") <- new syntax
	`getHelpURL` <- function(..., help_type = "html") {
		if(tools:::httpdPort == 0L) suppressMessages(tools:::startDynamicHelp(TRUE))
		help_type <- "html"
		ret <- NULL
		oBrowser <- options(browser = function(uri) ret <<- uri)
		on.exit(options(oBrowser))
		if(tools:::httpdPort == 0L) return("")
		if(!length(list(...))) {
			return(paste("http://127.0.0.1:", tools:::httpdPort, "/doc/html/index.html",
				  sep = ""))
		}
		cl <- match.call()
		if(length(cl) > 1L && mode(cl[[2L]][[1L]]) == "name") { # handle old syntax
			cl <- cl[[2L]]
			cl$help_type <- help_type
			print(eval(cl, .GlobalEnv))
		} else {
			print(utils::help(..., help_type = help_type))
		}
		ret
	}

	require(utils)

	env <- as.environment("komodoConnection")
	#setwd("~/Dokumenty/Projects/SciViews/komodo/SciViews-K-dev\\R")

	src <- dir(pattern = "^[^_].*\\.R$")
	Rdata <- "startup.RData"


	if(file.exists(Rdata) && {
		mtime <- file.info(c(Rdata, src))[, "mtime"]
		all(mtime[-1L] <= mtime[1L])
	}) {
		#cat('komodoConnection restored from "startup.RData" \n')
		load(Rdata, envir = env)
		rm(mtime)
		#sys.source("rserver.R", envir = env)
	} else{
		lapply(src, sys.source, envir = env, keep.source = FALSE)
		
		#NOTE PhG: .find.package becomes find.package in R 3.0.0
		if(length(.find.package("compiler", quiet = TRUE))) {
			for(fun in ls(env)) if(exists(fun, env, mode = "function"))
					assign(fun, compiler::cmpfun(get(fun, env),
						options = list(suppressAll = TRUE)))
		}
		suppressWarnings(save(list = ls(env), file = Rdata, envir = env))
		cat("'komodoConnection' loaded from source files \n")

	}
	init.Rserver()
	rm(env, Rdata, src)
	invisible()
})

local({
	port <- 1111L
	while((port < 1150L) && (as.character(sv_startServer(port)) == "0"))
		port <- port + 1L

	cwd0 <- normalizePath(".")
	if(file.exists("_init.R")) source("_init.R")

	cat("cwd is now ", sQuote(getwd()), "\n")

	## Do we have a .Rprofile file to source?
	#rprofile <- file.path(c(getwd(), Sys.getenv("R_USER")), ".Rprofile")
	cwd <- normalizePath(getwd())
	isBaseDir <- file.exists(file.path(cwd, "sv-basedir")) || (cwd == cwd0)
	rprofile <- file.path(c(if(!isBaseDir) getwd(), Sys.getenv("R_USER")), ".Rprofile")
	rprofile <- rprofile[file.exists(rprofile)][1L]

	if (!is.na(rprofile)) {
		source(rprofile)
		cat("Loaded file:", rprofile, "\n")
	}

	if(.Platform$GUI == "Rgui") {
		if(file.exists("Rconsole"))	utils:::loadRconsole("Rconsole")
		utils::setWindowTitle("talking to Komodo")
	}

	#if(!any(c("--vanilla", "--no-restore", "--no-restore-data") %in% commandArgs())
		#&& file.exists(".RData")) {
		#sys.load.image(".RData", FALSE)
	#}
	if(file.exists(".Rhistory")) loadhistory(".Rhistory")

	Rservers <- enumServers()
	if(is.numeric(getOption("ko.port")) && length(Rservers) > 0L) {
		cat("Server started at port", Rservers, "\n")
		invisible(koCmd(paste(
			"sv.cmdout.clear()",
			sprintf("sv.cmdout.append('%s is started')", R.version.string),
			"sv.command.updateRStatus(true)",
			# "sv.rbrowser.smartRefresh(true)", # not before workspace is loaded
			sprintf("sv.pref.setPref('sciviews.r.port', %s)", tail(Rservers, 1L)),
			sep = ";")))
	}

	assign(".First", function() {
			invisible(koCmd("sv.rbrowser.smartRefresh(true)"))
			#cat("Komodo is refreshed \n")
			rm(list = ".First", envir = .GlobalEnv) # self-destruct
		}, .GlobalEnv)


	assign(".Last", function() {
		tryCatch({
		koCmd("sv.addNotification(\"R says bye!\"); sv.command.updateRStatus(false);")
		stopAllServers()
		stopAllConnections()
		}, error = function(...) NULL)
	}, .GlobalEnv)



})

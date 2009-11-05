### SciViews install begin ###
# SciViews-R installation and startup for running R with Komodo/SciViews-K
# Version 0.9.6, 2009-11-03 Ph. Grosjean (phgrosjean@sciviews.org)

#TODO: Include all this as a function in svMisc??
#TODO: [KB] Fix problem with installing sv* packages when not running R as root.
#      R tries to install them forever, and finally crashes my Ubuntu (Bug #685)

# Make sure we don't process this twice in case of duplicate items in .Rprofile
svStart <- function(){
# [KB] Wrapped this in a function, so we can be sure it does not leave any garbage or
#      overwrites user's objects.

if (!exists(".SciViewsReady", envir = .GlobalEnv)) {

	assign(".SciViewsReady", FALSE, .GlobalEnv)
	minVersion <- c(R = "2.10.0", svMisc = "0.9-56", svSocket = "0.9-48", svGUI = "0.9-46")

	# First of all, check R version... redefine compareVersion() because it is
	# not defined in very old R versions... and thus we don't get an explicit
	# error message in that particular case
	checkVersion <- function (a, b) {
		a <- as.integer(strsplit(a, "[\\.-]")[[1]])
		b <- as.integer(strsplit(b, "[\\.-]")[[1]])
		for (k in 1:length(a)) {
			if (k <= length(b)) {
				if (a[k] > b[k]) return(1)
				else if (a[k] < b[k]) return(-1)
			} else return(1)
		}
		if (length(b) > length(a)) return(-1) else return(0)
	}
	rVersion <- paste(R.Version()$major, R.Version()$minor, sep = ".")
	res <- checkVersion(rVersion, minVersion["R"])
	if (res < 0) {
		res <- FALSE
		cat("R is too old for this version of SciViews (R >=",
			minVersion["R"], "is needed), please, upgrade it\n")
	} else res <- TRUE

	# Load main R packages (tools added to the list because now required by svMisc)
	res <- all(sapply(c("methods", "datasets", "utils", "grDevices", "graphics", "stats", "tools"),
				  function(x) require(x, quietly = TRUE, character.only = TRUE)))


	# Get environment variables
	if (res) {
		args <- commandArgs()
		# If started --quiet, display a simplified message
		# but not if started -q, so that the user can still make it fully quiet!
		par <- args[grep("^--quiet$", args)]
		if (length(par) > 0) cat(R.version.string, "\n", sep = "")

		# Collect SciViews socket client/server config from command line or vars
		par <- args[grep("^--ko.serve=", args)]
		if (length(par) == 0) par <- as.integer(Sys.getenv("koServe")) else
			par <- as.integer(sub("^--ko.serve=", "", par))
		if (is.na(par)) par <- 8888
		options(ko.serve = par)		# Port used by the R socket server
		par <- args[grep("^--ko.host=", args)]
		if (length(par) == 0) par <- as.character(Sys.getenv("koHost")) else
			par <- sub("^--ko.host=", "", par)
		if (par == "") par <- "localhost"
		options(ko.host = par)		# Machine where Komodo is running
		par <- args[grep("^--ko.port=", args)]
		if (length(par) == 0) par <- as.integer(Sys.getenv("koPort")) else
			par <- as.integer(sub("^--ko.port=", "", par))
		if (is.na(par)) par <- 7052
		options(ko.port = par)		# Port used by the Komodo socket server
		par <- args[grep("^--ko.id=", args)]
		if (length(par) == 0) par <- as.character(Sys.getenv("koId")) else
			par <- sub("^--ko.id=", "", par)
		if (par == "") par <- "SciViewsK"
		options(ko.id = par)		# The id used by Komodo
		par <- args[grep("^--ko.activate=", args)]
		if (length(par) == 0) par <- as.character(Sys.getenv("koActivate")) else
			par <- sub("^--ko.activate=", "", par)
		if (par == "") par <- "FALSE"
		par <- (par[1] == "TRUE")
		options(ko.activate = par)	# Do we reactivate Komodo?
		par <- args[grep("^--R.id=", args)]
		if (length(par) == 0) par <- as.character(Sys.getenv("Rid")) else
			par <- sub("^--R.id=", "", par)
		if (par == "") par <- "R"
 		options(R.id = par)			# The id used for this R kernel in Komodo
		par <- args[grep("^--R.initdir=", args)]
		if (length(par) == 0) par <- as.character(Sys.getenv("Rinitdir")) else
			par <- sub("^--R.initdir=", "", par)
		# If the initial directory is "", or it does not exist or it is not a dir
		# we use the default home directory instead!
		if (par == "" || !file.exists(par) || !file.info(par)$isdir) par <- "~"
		options(R.initdir = par)	# The initial directory to use for R
		# Note: the initial directory is used to load/save workspace and history
		rm(par)
	}

	# Load tcltk package
	if (res) {
		if (capabilities("tcltk")) {
			# Make sure tcltk can start: on Mac OS X < 10.5 only,
			# that is, darwin < 9, we need to check that X11 is installed
			# (optional component!) and started!
			# But this is not needed any more for R >= 2.8.0. Before we
			# activate this test, we must find a way to start Tk later,
			# when tktoplevel() is first invoked!
			#if (checkVersion(rVersion, "2.8.0") < 0) {
			if (regexpr("^darwin[5-8]", R.Version()$os) > -1) {
				# First, is the DISPLAY environment variable defined?
				dis <- Sys.getenv("DISPLAY")
				if (dis == "") {
					Sys.setenv(DISPLAY = ":0")	# Local X11
					dis <- Sys.getenv("DISPLAY")
				}
				# Second, if DISPLAY points to a default local X11, make sure
				# X11 is installed and started on this machine
				if (dis %in% c(":0", ":0.0", "localhost:0", "localhost:0.0",
					"127.0.0.1:0", "127.0.0.1:0.0")) {
					# X11 is optional on Mac OS X 10.3 Panther and 10.4 Tiger!
					# We locate 'open-x11' and run it,... not X11 directly!
					if (length(system('find /usr/bin/ -name "open-x11"',
						intern = TRUE)) == 0){
						cat("'open-x11' not found. Make sure you installed X11\n")
						cat("(see http://developer.apple.com/opensource/tools/runningx11.html\n")
						res <- FALSE
					} else {	# Make sure X11 is started
						# trick: we try opening a non X11 prog,
						# effect is starting X11 alone
						system("open-x11 more", intern = TRUE)
					}
				}
				rm(dis)
			}
			#} # Test if R >= 2.8.0 for setting DISPLAY environment variable
			if (res) {
				res <- suppressPackageStartupMessages(require(tcltk, quietly = TRUE))
				if (!res) {
					cat("Error starting tcltk. Make sure Tcl/Tk is installed and can\n")
					cat("be run on your machine. Then, with packages svMisc, svSocket\n")
					cat("and svGUI installed, restart R or type require(svGUI)\n")
				}
			}
		} else cat("Tcl/Tk is required by SciViews,\nbut it is not supported by this R installation\n")
	} else cat("Problem loading standard R packages, check R installation\n")
	rm(checkVersion, rVersion)

	if (res) {
		# Load packages svMisc, svSocket & svGUI (possibly after installing
		# or upgrading them). User is supposed to agree with this install
		# from the moment he tries to start and configure R from Komodo Edit

		pkgs <- c("svMisc", "svSocket", "svGUI")
		ext <- switch(.Platform$pkgType,
			mac.binary = "\\.tgz",
			win.binary = "\\.zip",
			"\\.tar.gz")

		res <- sapply(pkgs, function(pkgName) {
			file <- dir(pattern = paste(pkgName, ext, sep = ".+"))
			file <- sort(file)[length(file)]	# Keep newest one found
			desc <- system.file("DESCRIPTION", package = pkgName)
			if (desc == "") {
				cat("Installing missing package", sQuote(pkgName), "\n")
				if (length(file)) {
					install.packages(file, repos = NULL) # or use "http://R-Forge.R-project.org"
					res <- require(pkgName, quietly = TRUE, character.only = TRUE)
				} else res <- FALSE
			} else { # Check version
				if ((compareVersion(packageDescription(pkgName, fields = "Version"),
					minVersion[pkgName]) < 0)) {
					cat("Updating package", sQuote(pkgName), "\n")
					if (length(file)) {
						install.packages(file, repos = NULL)
						res <- require(pkgName, quietly = TRUE, character.only = TRUE)
					} else res <- FALSE
				} else res <- require(pkgName, quietly = TRUE, character.only = TRUE)
			}
			return(res)
		})

		rm(ext)
		# Try starting the R socket server now
		if (inherits(try(startSocketServer(port = getOption("ko.serve")),
			silent = TRUE), "try-error")) {

			cat("Impossible to start the SciViews R socket server\n(socket",
				getOption("ko.serve"), "already in use?)\n")
			cat("Solve the problem, then type: require(svGUI)\n")
			cat("or choose a different port for the server in Komodo\n")

		} else {
			# Finally, load svGUI
			if (res["svGUI"]) res["svGUI"] <- require("svGUI", quietly = TRUE)

			if (all(res)) {
				cat("R is SciViews ready!\n")
				assign(".SciViewsReady", TRUE, .GlobalEnv)

				# Indicate what we have as default packages
				options(defaultPackages = c("datasets", "utils", "grDevices",
					"graphics", "stats", "methods", "tools", "tcltk", "svMisc",
					"svSocket", "svGUI"))
			} else {
				cat("R is not SciViews ready, install latest svMisc, svSocket & svGUI packages\n")
			}
		}
	}
	res <- all(res)

	if (res) {
		# Make sure Komodo is started now
		# Note: in Mac OS X, you have to create the symbolic link manually
		# as explained in the Komodo Help with:
		# sudo ln -s "/Applications/Komodo Edit.app/Contents/MacOS/komodo" /usr/local/bin/komodo
		# You must issue something similar too under Linux
		# (see Komodo installation guide) or the script will complain.

		# A custom pager consists in displaying the file in Komodo
		svPager <- function (files, header, title, delete.file) {
			files <- gsub("\\", "\\\\", files[1], fixed = TRUE)
			koCmd(sprintf('sv.r.pager("%s", "%s")', files, title))

			if (delete.file) {
				koCmd(sprintf('window.setTimeout("try { sv.tools.file.getfile(\\"%s\\").remove(false); } catch(e) {}", 10000);', files));
			}
		}
		svBrowser <- function(url) {
			koCmd(sprintf("sv.command.openHelp(\"%s\")", gsub("\\", "\\\\", url, fixed = TRUE)))
		}

		# Look if and where komodo is installed
		if (.Platform$OS.type == "unix") {
			if (Sys.getenv("koAppFile") != "") {
				Komodo <- Sys.getenv("koAppFile")
			} else {
				Komodo <- "/usr/local/bin/komodo"	# Link should be created!
			}
			# Check that this file exists
			if (!file.exists(Komodo)) {
				# File not found, display a message with missing link
				Komodo <- NULL
				cat("Komodo is not found by R. Please, follow instructions at",
					"http://www.sciviews.org/SciViews-K to install it correctly.",
					"In particular, you must create a symbolic link in /user/local/bin:",
					"sudo ln -s <KomodoBinLocation>/komodo /usr/local/bin/komodo",
					"otherwise, R cannot find it!", sep="\n")
			} else {
				# Change the editor and the pager to Komodo
				options(editor = Komodo, browser = svBrowser, pager = svPager)
			}
		} else {
		    # if komodo path was passed in environment
			if (file.exists(Sys.getenv("koAppFile"))) {
				Komodo <-  Sys.getenv("koAppFile")
			} else {
				# On Windows, 'komodo' should be enough
				# But for reasons that escape me, komodo seems to stip off its own
				# directory from the path variable. So, I have to restore it from
				# the Windows registry :-(

				Ret <- tclRequire("registry", warn = TRUE)
				Path <- tclvalue(.Tcl("registry get {HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment} {Path}"))
				if (!is.null(Path) && !is.na(Path) && Path != "") {
					Path <- strsplit(Path, ";")[[1]]
					Path <- Path[sapply(Path, function(x) file.exists(file.path(x, "komodo.exe")))][1]
					Komodo <- gsub("\\\\+", "\\\\", (file.path(Path, "komodo.exe", fsep = "\\")))
				} else {
					Komodo <- "komodo"
				}
				rm(Ret, Path)
			}

			owarn <- getOption("warn")
			options(warn = -1)
			# Try to run Komodo now
			res <- try(system(paste('"', Komodo, '"', sep = ""), wait = FALSE), silent = TRUE)
			if (res == -1) {
				Komodo <- NULL
				cat("R cannot find Komodo. Please, make sure you install it correctly\n",
					"You can find it at http://www.activestate.com/Products/komodo_edit.\n")
			} else {
				# Change the editor and the pager to Komodo
				options(editor = Komodo, browser = svBrowser, pager = svPager)
			}
			options(warn = owarn)
			rm(owarn)
		}
		rm(minVersion, res, svPager)

		# Make sure we use HTML help (required for Shift-F1 and Alt-Shift-F1)
		# to display R help in Komodo Edit (in Windows, chmhelp is the default up to R 2.9.2)
		#Old code: if (.Platform$OS.type == "windows") options(chmhelp = FALSE)
		#Old code: options(htmlhelp = TRUE)		
		# In R 2.10, help system is completely changed
		options(help_type = "html")
		# Make sure the help server is started
		if (tools:::httpdPort == 0L) 
				tools::startDynamicHelp()
		# Record the home page for the help server in an option
		options(helphome = paste("http://127.0.0.1:", tools:::httpdPort,
				"/doc/html/index.html", sep = ""))
		# I need to get the help file URL, but help() does not provide it any more!
		# This is a temporary workaround for this problem
		assignTemp("getHelpURL", function(x, ...) {
				file <- as.character(x)
				if (length(file) == 0) return("")
				return(paste("http://127.0.0.1:", tools:::httpdPort, 
				"/library/", basename(dirname(dirname(file))),
				"/html/", basename(file), sep = ""))
		})

# print method of object returned by help() is very unflexible for R.app and
# does not allow in any way to use anything else than the R.app internal
# browser for help!!!
# That makes me very unhappy! Hey guys, I would like to use SciViews help
# browser here! So, no other solution than to be even harsher, and to force
# rewriting of the print function in base environment!!!
# (problem emailed to Simon Urbanek on 03/11/2009... I hope he will propose
# a work-around for this in R 2.10.1!!!)
unlockBinding("print.help_files_with_topic", env = baseenv())
assign("print.help_files_with_topic",
function (x, ...) 
{
    browser <- getOption("browser")
    topic <- attr(x, "topic")
    type <- attr(x, "type")
	# This is the problematic code!
    #if (.Platform$GUI == "AQUA" && type == "html") {
    #    browser <- function(x, ...) {
    #        .Internal(aqua.custom.print("help-files", x))
    #        return(invisible(x))
    #    }
    #}
    paths <- as.character(x)
    if (!length(paths)) {
        writeLines(c(gettextf("No documentation for '%s' in specified packages and libraries:", 
            topic), gettextf("you could try '??%s'", topic)))
        return(invisible(x))
    }
    if (type == "html") 
        if (tools:::httpdPort == 0L) 
            tools::startDynamicHelp()
    if (attr(x, "tried_all_packages")) {
        paths <- unique(dirname(dirname(paths)))
        msg <- gettextf("Help for topic '%s' is not in any loaded package but can be found in the following packages:", 
            topic)
        if (type == "html" && tools:::httpdPort > 0L) {
            path <- file.path(tempdir(), ".R/doc/html")
            dir.create(path, recursive = TRUE, showWarnings = FALSE)
            out <- paste("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n", 
                "<html><head><title>R: help</title>\n", "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=\"UTF-8\">\n", 
                "<link rel=\"stylesheet\" type=\"text/css\" href=\"/doc/html/R.css\">\n", 
                "</head><body>\n\n<hr>\n", sep = "")
            out <- c(out, "<p>", msg, "</p><br>")
            out <- c(out, "<table width=\"100%\" summary=\"R Package list\">\n", 
                "<tr align=\"left\" valign=\"top\">\n", "<td width=\"25%\">Package</td><td>Library</td></tr>\n")
            pkgs <- basename(paths)
            links <- paste("<a href=\"http://127.0.0.1:", tools:::httpdPort, 
                "/library/", pkgs, "/help/", topic, "\">", pkgs, 
                "</a>", sep = "")
            out <- c(out, paste("<tr align=\"left\" valign=\"top\">\n", 
                "<td>", links, "</td><td>", dirname(paths), "</td></tr>\n", 
                sep = ""))
            out <- c(out, "</table>\n</p>\n<hr>\n</body></html>")
            writeLines(out, file.path(path, "all.available.html"))
            browseURL(paste("http://127.0.0.1:", tools:::httpdPort, 
                "/doc/html/all.available.html", sep = ""), browser)
        }
        else {
            writeLines(c(strwrap(msg), "", paste(" ", formatDL(c(gettext("Package"), 
                basename(paths)), c(gettext("Library"), dirname(paths)), 
                indent = 22))))
        }
    }
    else {
        if (length(paths) > 1L) {
            if (type == "html" && tools:::httpdPort > 0L) {
                browseURL(paste("http://127.0.0.1:", tools:::httpdPort, 
                  "/library/NULL/help/", topic, sep = ""), browser)
                return(invisible(x))
            }
            file <- paths[1L]
            p <- paths
            msg <- gettextf("Help on topic '%s' was found in the following packages:", 
                topic)
            paths <- dirname(dirname(paths))
            txt <- formatDL(c("Package", basename(paths)), c("Library", 
                dirname(paths)), indent = 22L)
            writeLines(c(strwrap(msg), "", paste(" ", txt), ""))
            if (interactive()) {
                fp <- file.path(paths, "Meta", "Rd.rds")
                tp <- basename(p)
                titles <- tp
                if (type == "html" || type == "latex") 
                  tp <- tools::file_path_sans_ext(tp)
                for (i in seq_along(fp)) {
                  tmp <- try(.readRDS(fp[i]))
                  titles[i] <- if (inherits(tmp, "try-error")) 
                    "unknown title"
                  else tmp[tools::file_path_sans_ext(tmp$File) == 
                    tp[i], "Title"]
                }
                txt <- paste(titles, " {", basename(paths), "}", 
                  sep = "")
                res <- menu(txt, title = gettext("Choose one"), 
                  graphics = getOption("menu.graphics"))
                if (res > 0) 
                  file <- p[res]
            }
            else {
                writeLines(gettext("\nUsing the first match ..."))
            }
        }
        else file <- paths
        if (type == "html") {
            if (tools:::httpdPort > 0L) {
                path <- dirname(file)
                dirpath <- dirname(path)
                pkgname <- basename(dirpath)
                browseURL(paste("http://127.0.0.1:", tools:::httpdPort, 
                  "/library/", pkgname, "/html/", basename(file), 
                  sep = ""), browser)
            }
            else {
                warning("HTML help is unavailable", call. = FALSE)
                att <- attributes(x)
                xx <- sub("/html/([^/]*)\\.html$", "/help/\\1", 
                  x)
                attributes(xx) <- att
                attr(xx, "type") <- "text"
                print(xx)
            }
        }
        else if (type == "text") {
            path <- dirname(file)
            dirpath <- dirname(path)
            pkgname <- basename(dirpath)
            RdDB <- file.path(path, pkgname)
            if (file.exists(paste(RdDB, "rdx", sep = "."))) {
                temp <- tools::Rd2txt(tools:::fetchRdDB(RdDB, 
                  basename(file)), out = tempfile("Rtxt"), package = pkgname)
                file.show(temp, title = gettextf("R Help on '%s'", 
                  topic), delete.file = TRUE)
            }
            else {
                zfile <- zip.file.extract(file, "Rhelp.zip")
                if (file.exists(zfile)) {
                  first <- readLines(zfile, n = 1L)
                  enc <- if (length(grep("\\(.*\\)$", first))) 
                    sub("[^(]*\\((.*)\\)$", "\\1", first)
                  else ""
                  if (enc == "utf8") 
                    enc <- "UTF-8"
                  if (.Platform$OS.type == "windows" && enc == 
                    "" && l10n_info()$codepage < 1000) 
                    enc <- "CP1252"
                  file.show(zfile, title = gettextf("R Help on '%s'", 
                    topic), delete.file = (zfile != file), encoding = enc)
                }
                else stop(gettextf("No text help for '%s' is available:\ncorresponding file is missing", 
                  topic), domain = NA)
            }
        }
        else if (type %in% c("ps", "postscript", "pdf")) {
            ok <- FALSE
            zfile <- zip.file.extract(file, "Rhelp.zip")
            if (zfile != file) 
                on.exit(unlink(zfile))
            if (file.exists(zfile)) {
                .show_help_on_topic_offline(zfile, topic, type)
                ok <- TRUE
            }
            else {
                path <- dirname(file)
                dirpath <- dirname(path)
                pkgname <- basename(dirpath)
                RdDB <- file.path(dirpath, "help", pkgname)
                if (file.exists(paste(RdDB, "rdx", sep = "."))) {
                  key <- sub("\\.tex$", "", basename(file))
                  tf2 <- tempfile("Rlatex")
                  tools::Rd2latex(tools:::fetchRdDB(RdDB, key), 
                    tf2)
                  .show_help_on_topic_offline(tf2, topic, type)
                  ok <- TRUE
                }
            }
            if (!ok) 
                stop(gettextf("No offline help for '%s' is available:\ncorresponding file is missing", 
                  topic), domain = NA)
        }
    }
    invisible(x)
}, envir = baseenv())
lockBinding("print.help_files_with_topic", env = baseenv())


		# Change the working directory to the provided directory
		setwd(getOption("R.initdir"))

		# Create a .Last.sys function that clears some variables in .GlobalEnv
		# and then, switch to R.initdir before closing R. The function is stored
		# in TempEnv()
		assignTemp(".Last.sys", function () {
			# Eliminate some known hidden variables from .GlobalEnv to prevent
			# saving them in the .RData file
			if (exists(".required", envir = .GlobalEnv, inherits = FALSE))
				rm(.required, envir = .GlobalEnv, inherits = FALSE)
			if (exists(".SciViewsReady", envir = .GlobalEnv, inherits = FALSE))
				rm(.SciViewsReady, envir = .GlobalEnv, inherits = FALSE)
			# If a R.initdir is defined, make sure to switch to it, so that
			# the session's workspace and command history are written at the
			# right place (in case of error, no change is made!)
			try(setwd(getOption("R.initdir")), silent = TRUE)
		})

		msg <- paste("Session directory is", getOption("R.initdir"))
		# Do we load .RData and .Rhistory now?
		if (!"--vanilla" %in% args && !"--no-restore" %in% args &&
			!"--no.restore-data" %in% args) {
				if (file.exists(".RData")) {
						load(".RData")
						msg <- paste(msg, "[data loaded")
				} else msg <- paste(msg, "[no data")
				if (file.exists(".Rhistory")) {
						loadhistory()
						msg <- paste(msg, ... = "/history loaded]", sep = "")
				} else msg <- paste(msg, "/no history]", sep = "")
		} else msg <- paste(msg, "[data/history not loaded]")
		cat(msg, "\n", sep = "", file = stderr())

		# Do we reactivate Komodo now?
		koact <- getOption("ko.activate")
		if (.SciViewsReady && isTRUE(koact)) {
			if ((.Platform$pkgType == "mac.binary")) {
				system("osascript -e 'tell application \"Komodo\" to activate'",
					wait = FALSE)
			} else if (!is.null(Komodo)) {
				# TODO: The following starts komodo if not started yet, but does not activate it!
				system(Komodo, wait = FALSE)
			}
			# Indicate to Komodo that R is ready
			# And test also communication from R to Komodo!
			koCmd('ko.statusBar.AddMessage("<<<data>>>", "R", 10000, true);',
				data = paste("'", getOption("R.id"), "' (R ", R.Version()$major, ".",
				R.Version()$minor, ") connected. Session dir: ",
				path.expand(getOption("R.initdir")), sep = ""))
		}
		rm(koact, Komodo, args, msg)
		# update
		invisible(koCmd("sv.socket.updateCharset();"));
	}
}


}



svStart()

rm(svStart)

### SciViews install end ###

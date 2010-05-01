### SciViews install begin ###
# SciViews-R installation and startup for running R with Komodo/SciViews-K
# Version 0.9.11, 2010-02-09 Ph. Grosjean (phgrosjean@sciviews.org)
# Version 0.9.15, 2010-05-01 mod by K. Barton

# TODO: also use value in koDebug to debug server from within R!

"svStart" <-
function (minVersion = c(R = "2.6.0", svMisc = "0.9-56",
svSocket = "0.9-48", svGUI = "0.9-46", ellipse = "0.3-5", SciViews = "0.9-1"),
	# NOTE: minVersion is now also used as a list of required packages
	remote.repos = "http://R-Forge.R-project.org",
	pkg.dir = ".",
	debug = Sys.getenv("koDebug") == "TRUE",
	pkgsLast = c("svGUI", "ellipse", "SciViews") # to be loaded at end
	) {

	# needed later for tryCatch'ing:
	"err.null" <- function (e) return(NULL)

	# TODO: if R crashes before this code is done, 00LOCK remains and it is not
	# possible to initiate SciViews extensions any more! => use a different
	# mechanism (perhaps, a file in /tmp and/or make sure the 00LOCK file
	# is deleted when Komodo Edit quits)
	# TODO: 00LOCK should be best deleted with StartR command from Komodo

	path0 <- getwd()
	lockfile <- file.path(path0, "00LOCK")
	if (file.exists(lockfile)) {
		# We can safely assume that running svStart will not take more that 5 minutes,
		# if 00LOCK is older, it means something went wrong previously, so we simply disregard it
		if(difftime(Sys.time(), file.info(lockfile)[,"mtime"], units="mins") < 5) {
			return (invisible(NULL))
		} else {
			file.remove(lockfile)
		}
	}
	file.create(lockfile)
	on.exit(file.remove(lockfile)) # Clean up

	if (debug) {
		"debugMsg" <- function(...) {
			cat("DEBUG:", ..., "\n")
		}
	} else {
		"debugMsg" <- function(...) {};
	}

	# Return if any of the sv* packages already loaded and Rserver running
	if (any(c("package:svGUI", "package:svSocket", "package:svMisc") %in% search())
	&& existsFunction("getSocketServers")
	&& !is.na(getSocketServers()["Rserver"])) {
		invisible(return(NA))
	}

	# First of all, check R version... redefine compareVersion() because it is
	# not defined in very old R versions... and thus we don't get an explicit
	# error message in that particular case
	if (!existsFunction("compareVersion")) {
		"compareVersion" <- function (a, b) {
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
	}
	rVersion <- paste(R.Version()$major, R.Version()$minor, sep = ".")
	res <- compareVersion(rVersion, minVersion["R"])
	if (res < 0) {
		res <- FALSE
		cat("R is too old for this version of SciViews (R >=",
			minVersion["R"], "is needed), please, upgrade it\n")
	} else res <- TRUE

	# Load main R packages (tools added to the list because now required by svMisc)
	res <- all(sapply(c("methods", "datasets", "utils", "grDevices", "graphics",
		"stats", "tools"), function(x)
		require(x, quietly = TRUE, character.only = TRUE)))

	# Get environment variables
	if (res) {
		"svOption" <- function (arg.name,
		envName = gsub("\\.(\\w)", "\\U\\1", arg.name, perl = TRUE),
		default = NA, as.type = as.character, args = commandArgs(), ...) {
			pfx <- paste("^--", arg.name, "=", sep = "")
			x <- args[grep(pfx, args)]
			x <- if (!length(x)) Sys.getenv(envName) else sub(pfx, "", x)
			x <- as.type(x, ...)
			if (is.na(x) || x == "") x <- default
			x <- structure(list(x), names = arg.name)
			do.call("options", x)
			return(x)
		}

		args <- commandArgs()
		# If started --quiet, display a simplified message
		# but not if started -q, so that the user can still make it fully quiet!
		par <- args[grep("^--quiet$", args)]
		if (length(par) > 0) cat(R.version.string, "\n", sep = "")

		# Collect SciViews socket client/server config from command line or vars
		# Port used by the R socket server
		svOption("ko.serve", default = 8888, args = args, as.type = as.integer)
		# Machine where Komodo is running
		svOption("ko.host", default = "localhost", args = args)
		# Port used by the Komodo socket server
		svOption("ko.port", default = 7052, args = args, as.type = as.integer)
		# The id used by Komodo
		svOption("ko.id", default = "SciViewsK", args = args)
		# Do we reactivate Komodo?
		svOption("ko.activate", default = FALSE, args = args, as.type = as.logical)
		# The id used for this R kernel in Komodo
		svOption("R.id", envName = "Rid", default = "R", args = args)
		# If the initial directory is "", or it does not exist or it is not a dir
		# we use the default home directory instead!
		# The initial directory to use for R
		# Note: the initial directory is used to load/save workspace and history
		svOption("R.initdir", envName = "Rinitdir", default = "~",
			args = args, as.type = function (x, default.dir) {
				if (x == "" || !file.exists(x) || !file.info(x)$isdir) {
					return (NA)
				} else {
					return(x)
				}
			}
		)
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
			#if (compareVersion(rVersion, "2.8.0") < 0) {
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

			if (res) {
				res <- suppressPackageStartupMessages(require(tcltk, quietly = TRUE))
				if (!res) {
					cat("Error starting tcltk. Make sure Tcl/Tk is installed and can\n",
					"be run on your machine. Then, with packages svMisc, svSocket\n",
					"and svGUI installed, restart R or type require(svGUI)\n")
				}
			}
		} else cat("Tcl/Tk is required by SciViews,\n",
				"but it is not supported by this R installation\n")
	} else cat("Problem loading standard R packages, check R installation\n")

	if (res) {
		# Load packages svMisc, svSocket & svGUI (possibly after installing
		# or upgrading them). User is supposed to agree with this install
		# from the moment he tries to start and configure R from Komodo Edit
		pkgs <- names(minVersion)
		pkgs <- pkgs[!(pkgs %in% "R")]

		ext <- switch(.Platform$pkgType, # There is a problem on some Macs
			# => always install from sources there! mac.binary = "\\.tgz",
			win.binary = "\\.zip", "\\.tar\\.gz")
		typ <- switch(.Platform$pkgType, # There is a problem on some Macs
			# => always install from sources there! mac.binary = "\\.tgz",
			win.binary = "win.binary", "source")

		# Find a library location with write access, usually, last item in the
		# list is fine
		lib <- .libPaths()
		k <- file.access(lib, 2) == 0
		if (!any(k)) {
			# If nothing is available to current user, create user library location
			lib <- Sys.getenv("R_LIBS_USER")[1L]
			dir.create(lib, recursive = TRUE)
			# update library paths:
			.libPaths(lib)
		} else {
			lib <- tail(lib[k], 1)
		}

		debugMsg("Installing packages if needed:")
		sapply(pkgs, function (pkgName) {
			debugMsg("Now trying package:", pkgName)
			file <- dir(path = pkg.dir, pattern = paste(pkgName, ext, sep = ".+"))

			if (length(file) > 0) {
				# Better by-version sorting
				ver <- gsub(paste("(^", pkgName, "_", "|", ext, "$)", sep = ""),
					"", basename(file))
				file <- tail(file[order(sapply(strsplit(ver, "[\\.\\-]"),
					function (x) sum(as.numeric(x) * (100 ^ -seq_along(x)))))], 1)
				# For some reasons (bug probably?) I cannot install a package in
				# R 2.10.1 under Mac OS X when the path to the package has spaces
				# Also, correct a bug here when installing package from a
				# repository where we are not supposed to prepend a path!
				# Copy the dfile temporarily to the temp dir
				sourcefile <- file.path(pkg.dir, file)
				file <- file.path(tempdir(), file)
				repos <- NULL

				# remove directory lock if exists (happens sometimes on linux)
				if (.Platform$OS.type == "unix") {
					system(paste("rm -r -f", file.path(lib, "00LOCK")))
				}
			} else {
				# No packages found, download from the web
				sourcefile <- NULL
				file <- pkgName
				repos <- remote.repos
			}

			# desc <- suppressWarnings(system.file("DESCRIPTION", package = pkgName))
			pkgIsInstalled <- pkgName %in% installed.packages()[, 1]

			if (!pkgIsInstalled || compareVersion(packageDescription(pkgName,
				fields = "Version"), minVersion[pkgName]) < 0) {
				if (!pkgIsInstalled) {
					cat("Installing missing package", sQuote(pkgName),
						"into", sQuote(lib), "\n")
				} else {
					cat("Updating package", sQuote(pkgName), "\n")
				}
				# Copy the install file to the temporary directory
				if (!is.null(sourcefile)) try(invisible(file.copy(sourcefile, file)))
				# Install or update the package
				try(install.packages(file, lib = lib, repos = repos, type = typ))
				# Erase the temporary file
				try(unlink(file))
			} else {
				debugMsg("Package", pkgName, "is up to date")
			}
		})

		# Split pkgs to primary and secondary
		pkgsPrimary <- pkgs[!(pkgs %in% pkgsLast)]
		pkgsSecondary <- pkgs[pkgs %in% pkgsLast]

		# Do not load svGUI yet
		res <- sapply(pkgsPrimary, function(pkgName)
					  require(pkgName, quietly = TRUE, character.only = TRUE))

		if (!all(res)) {
			cat("Problem loading package(s):", paste(pkgsPrimary[!res], collapse = ", "), "\n")
		} else {
			# Try starting the R socket server now
			res <- !inherits(try(startSocketServer(port = getOption("ko.serve")),
			silent = TRUE), "try-error")

			if (!res) {
				cat("Impossible to start the SciViews R socket server\n(socket",
					getOption("ko.serve"), "already in use?)\n")
				cat("Solve the problem, then type: require(svGUI)\n")
				cat("or choose a different port for the server in Komodo\n")

			} else {
				# Finally, load svGUI, MASS and SciViews
				res <- sapply(pkgsSecondary, function(pkgName)
					  require(pkgName, quietly = TRUE, character.only = TRUE))

				if (all(res)) {
					cat("R is SciViews ready!\n")
					assignTemp(".SciViewsReady", TRUE)

					# Indicate what we have as default packages
					options(defaultPackages =
							unique(c(getOption("defaultPackages"), "tcltk", pkgs)))
				} else {
						cat("R is not SciViews ready, install latest",
						paste(pkgs, collapse=", "), "packages\n")
				}
			}
		}
	}
	res <- all(res)	# all packages are loaded

	if (res) {
		# Make sure Komodo is started now
		# Note: in Mac OS X, you have to create the symbolic link manually
		# as explained in the Komodo Help with:
		# sudo ln -s "/Applications/Komodo Edit.app/Contents/MacOS/komodo" /usr/local/bin/komodo
		# You must issue something similar too under Linux
		# (see Komodo installation guide) or the script will complain.
		if (Sys.getenv("koAppFile") != "") {
			Komodo <- Sys.getenv("koAppFile")
		} else Komodo <- ""

		if (Komodo != "") debugMsg("path to Komodo was passed in environment")

		# Look if and where komodo is installed
		if (.Platform$OS.type == "unix") {
			if (Komodo == "")
				Komodo <- "/usr/local/bin/komodo" # default location
			if (!file.exists(Komodo)) {
				Komodo <- Sys.which("komodo")[1]
				debugMsg("which", "returned", Komodo)
			}

			if (length(Komodo) == 0 || Komodo == "") {
				Komodo <- system("locate --basename -e --regex ^komodo$ | grep -vF 'INSTALLDIR' | grep -F 'bin/komodo' | tail --lines=1",
					intern = TRUE, ignore.stderr = TRUE)
				debugMsg("locate komodo", "returned", Komodo)
			}

		} else { # Windows
		    # If komodo path was not passed in environment
			if (Komodo == "") {
				Komodo <- NULL
				# On Windows, 'komodo' should be enough
				# But for reasons that escape me, Komodo seems to stip off its
				# own directory from the path variable. So, I have to restore it
				# from the Windows registry :-(

				# Try several ways to get Komodo path from registry.
				key <- "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\komodo.exe"
				Komodo <-
					tryCatch(readRegistry(key, hive = "HLM")[["(Default)"]],
					error = err.null)

				if (is.null(Komodo) || !file.exists(Komodo)) {
					key <- "Applications\\komodo.exe\\shell\\open\\command"
					Komodo <-
						tryCatch(readRegistry(key, hive = "HCR")[["(Default)"]],
						error = err.null)
					if (!is.null(Komodo))
						Komodo <- sub(" *\\\"%[1-9\\*].*$", "", Komodo)
				}

				if (is.null(Komodo) || !file.exists(Komodo)) {
					key <- "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"
					Path <-
						tryCatch(readRegistry(key, hive = "HLM")$Path,
							error = err.null)
					if (!is.null(Path) && !is.na(Path) && Path != "") {
						Path <- strsplit(Path, ";")[[1]]
						Path <- Path[sapply(Path,
							function (x)
								file.exists(file.path(x, "komodo.exe")))][1]
						Komodo <- gsub("\\\\+", "\\\\", file.path(Path,
							"komodo.exe", fsep = "\\"))
					}
				}
				debugMsg("Komodo searched for in registry in", key)
			}
			debugMsg("Komodo path is:", Komodo)
		}

		if (!is.null(Komodo) && Komodo != "" && file.exists(Komodo)) {
			# Change the editor and the pager to Komodo
			# A custom pager consists in displaying the file in Komodo
			"svPager" <- function (files, header, title, delete.file) {
				files <- gsub("\\", "\\\\", files[1], fixed = TRUE)
				koCmd(sprintf('sv.r.pager("%s", "%s")', files, title))
				if (delete.file)
					koCmd(sprintf('window.setTimeout("try { sv.tools.file.getfile(\\"%s\\").remove(false); } catch(e) {}", 10000);', files));
			}

			"svBrowser" <- function (url) {
				url <- gsub("\\", "\\\\", url, fixed = TRUE)
				# If the URL starts with '/', I could safely assume a file path
				# on Unix or Mac and prepend 'file://'
				url <- sub("^/", "file:///", url)
				koCmd(sprintf("sv.command.openHelp(\"%s\")", url))
			}

			options(editor = Komodo, browser = svBrowser, pager = svPager)
		} else {
			Komodo <- NULL
			cat("R cannot find Komodo.")
			if (.Platform$OS.type == "unix") {
				cat("Please, follow instructions at",
					"http://www.sciviews.org/SciViews-K to install it correctly.",
					"In particular, you must create a symbolic link in /user/local/bin:",
					"sudo ln -s <KomodoBinLocation>/komodo /usr/local/bin/komodo",
					"otherwise, R cannot find it!", sep = "\n")
			} else {
				cat("Please, make sure you install it correctly\n",
					"You can find it at http://www.activestate.com/Products/komodo_edit.\n")
			}
		}

		# Make sure we use HTML help (required for Shift-F1 and Alt-Shift-F1)
		# to display R help in Komodo Edit
		# (in Windows, chmhelp is the default up to R 2.9.2)
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
		# I need to get the help file URL, but help() does not provide it any
		# more! This is a temporary workaround for this problem
		assignTemp("getHelpURL", function(x, ...) {
			file <- as.character(x)
			if (length(file) == 0) return("")
			# Extension ".html" may be missing 
			htmlfile <- basename(file)
			if(substring(htmlfile, nchar(htmlfile) -4) != ".html")
				htmlfile <- paste(htmlfile, ".html", sep="")
			return(paste("http://127.0.0.1:", tools:::httpdPort,
			"/library/", basename(dirname(dirname(file))),
			"/html/", htmlfile, sep = ""))
		})

# print method of object returned by help() is very unflexible for R.app and
# does not allow in any way to use anything else than the R.app internal
# browser for help!!!
# That makes me very unhappy! Hey guys, I would like to use SciViews help
# browser here! So, no other solution than to be even harsher, and to force
# rewriting of the print function in base environment!!!
# (problem emailed to Simon Urbanek on 03/11/2009... I hope he will propose
# a work-around for this in R 2.10.1!!!)
source("print.help_files_with_topic.R")

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
			# Note: .SciViewsReady is now recorded in TempEnv() instead of
			# .GlobalEnv, but we leave this code for old workspaces...
			if (exists(".SciViewsReady", envir = .GlobalEnv, inherits = FALSE))
				rm(.SciViewsReady, envir = .GlobalEnv, inherits = FALSE)
			# If a R.initdir is defined, make sure to switch to it, so that
			# the session's workspace and command history are written at the
			# right place (in case of error, no change is made!)
			try(setwd(getOption("R.initdir")), silent = TRUE)
		})

		msg <- paste("Session directory is", dQuote(getOption("R.initdir")))
		msg2 <- NULL

		# Do we load .RData and .Rhistory now?
		if (!"--vanilla" %in% args && !"--no-restore" %in% args &&
			!"--no.restore-data" %in% args) {
				if (file.exists(".RData")) {
					load(".RData")
					msg2 <- append(msg2, "data loaded")
				} else
					msg2 <- append(msg2, "no data")

				if (file.exists(".Rhistory")) {
					# On R Tk gui:
					# "Error in loadhistory(file) : no history mechanism available"
					# So, do it inside a try()
					history.loaded <- try(loadhistory(), silent = TRUE)
					if (inherits(history.loaded, "try-error"))  {
						msg2 <- append(msg2, "history cannot be loaded")
					} else {
						msg2 <- append(msg2, "history loaded")
					}
				} else
					msg2 <- append(msg2, "no history")
		} else
			msg2 <- append(msg2, "data and history not loaded")

		cat(msg, " (", paste(msg2, collapse=", "),  ")", "\n", sep = "", file = stderr())

		# Do we reactivate Komodo now?
		koact <- getOption("ko.activate")
		debugMsg("Reactivate Komodo:", koact)
		if (getTemp(".SciViewsReady", FALSE) && koact) {
			if ((.Platform$pkgType == "mac.binary")) {
				system("osascript -e 'tell application \"Komodo\" to activate'",
					wait = FALSE)
			} else if (!is.null(Komodo)) {
				# TODO: The following starts komodo if not started yet,
				# but does not activate it!
				system(shQuote(Komodo), wait = FALSE)
			}
			# Indicate to Komodo that R is ready
			# and test also communication from R to Komodo!
			koCmd('sv.cmdout.message("<<<data>>>", 10000, true);',
				data = paste("'", getOption("R.id"), "' (R ",
				R.Version()$major, ".", R.Version()$minor,
				") connected. Session dir: ",
				path.expand(getOption("R.initdir")), sep = ""))
		}
		# Update info in Komodo:
		debugMsg("Contacting Komodo with koCmd")
		invisible(koCmd("sv.socket.updateCharset();"))
		invisible(koCmd("sv.cmdout.append('R is started');"))
		invisible(koCmd("sv.command.updateRStatus(true);"))

	}
	return(invisible(res))
}
### SciViews install end ###

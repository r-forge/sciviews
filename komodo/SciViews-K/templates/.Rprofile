### SciViews install begin ###
# SciViews-R installation and startup for running R with Komodo/SciViews-K
# Version 0.6.4, 2008-08-18 Ph. Grosjean (phgrosjean@sciviews.org)

# Make sure we don't process this twice in case of duplicate items in .Rprofile
if (!exists(".SciViewsReady", envir = .GlobalEnv)) {
	.SciViewsReady <- FALSE
	minVersion <- c(R = "2.7.0", svMisc = "0.9-44", svSocket = "0.9-41", svGUI = "0.9-42")

	# Get environment variables
	args <- commandArgs()

	## TODO: also check environment variables like:
	#par <- Sys.getenv("ko.serve") (returns "" if not set)
	# Configure socket client/server
	par <- args[grep("^--ko.serve=", args)]
	if (length(par) == 0) par <- 8888 else par <- as.integer(sub("^--ko.serve=", "", par))
	options(ko.serve = par)			# Port used by the R socket server
	par <- args[grep("^--ko.host=", args)]
	if (length(par) == 0) par <- "localhost" else par <- sub("^--ko.host=", "", par)
	options(ko.host = par)			# Machine where Komodo is running (local only for the moment)
	par <- args[grep("^--ko.port=", args)]
	if (length(par) == 0) par <- 7052 else par <- as.integer(sub("^--ko.port=", "", par))
	options(ko.port = par)			# Port used by the Komodo socket server
	par <- args[grep("^--ko.id=", args)]
	if (length(par) == 0) par <- "R" else par <- sub("^--ko.id=", "", par)
	options(ko.id = par)			# The id used for this R kernel in Komodo
	rm(par)

### If started --quiet, display a simplified message

	# Load main R packages
	res <- require(methods, quietly = TRUE)
	if (res) res <- require(datasets, quietly = TRUE)
	if (res) res <- require(utils, quietly = TRUE)
	if (res) res <- require(grDevices, quietly = TRUE)
	if (res) res <- require(graphics, quietly = TRUE)
	if (res) res <- require(stats, quietly = TRUE)
	if (res) {
		if (capabilities("tcltk")) {
			# Make sure tcltk can start: on Mac OS X < 10.5 only,
			# that is, darwin < 9, we need to check that X11 is installed
			# (optional!) and started!
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
					} else {	# Make sure X11 is started (trick: we try opening a non X11 prog)
						system("open-x11 more", intern = TRUE)
					}
				}
				rm(dis)
			}
			if (res) {
				res <- suppressPackageStartupMessages(require(tcltk, quietly = TRUE))
				if (!res) {
					cat("Error starting tcltk. Make sure Tcl/Tk is installed and can\n")
					cat("be run on your machine. Then, with packages svMisc, svSocket\n")
					cat("and svGUI installed, restart R or type require(svGUI)\n")
				}
			}
		} else cat("Tcl/Tk is required by SciViews, but it is not supported by this R installation\n")
	} else cat("Problem loading standard R packages, check R installation\n")

	if (res) {
		# Check for R version
		res <- compareVersion(paste(R.Version()$major, R.Version()$minor,
			sep = "."), minVersion["R"])
		if (res < 0) {
			cat("R is too old for this version of SciViews, please, upgrade it\n")
		} else {
			# Load packages svMisc, svSocket & svGUI (possibly after installing
			# or upgrading them). User is supposed to agree with this install
			# from the moment he tries to start and configure R from Komodo Edit
			ext <- switch(.Platform$pkgType,
				mac.binary = "\\.tgz",
				win.binary = "\\.zip",
				"\\.tar.gz")

			## svMisc
			file <- dir(pattern = paste("svMisc", ext, sep = ".+"))
			file <- sort(file)[length(file)]	# Keep oldest one
			desc <- system.file("DESCRIPTION", package = "svMisc")
			if (desc == "") {
				cat("Installing missing package 'svMisc'\n")
				if (length(file)) {
					install.packages(file, repos = NULL) # or use "http://R-Forge.R-project.org"
					res <- require(svMisc, quietly = TRUE)
				} else res <- FALSE
			} else { # Check version
				if ((compareVersion(packageDescription("svMisc", fields = "Version"),
					minVersion["svMisc"]) < 0)) {
					cat("Updating package 'svMisc'\n")
					if (length(file)) {
						install.packages(file, repos = NULL)
						res <- require(svMisc, quietly = TRUE)
					} else res <- FALSE
				} else res <- require(svMisc, quietly = TRUE)
			}

			## svSocket
			file <- dir(pattern = paste("svSocket", ext, sep = ".+"))
			file <- sort(file)[length(file)]	# Keep oldest one
			desc <- system.file("DESCRIPTION", package = "svSocket")
			if (desc == "") {
				cat("Installing missing package 'svSocket'\n")
				if (length(file)) {
					install.packages(file, repos = NULL)
					res[2] <- require(svSocket, quietly = TRUE)
				} else res[2] <- FALSE
			} else { # Check version
				if ((compareVersion(packageDescription("svSocket", fields = "Version"),
					minVersion["svSocket"]) < 0)) {
					cat("Updating package 'svSocket'\n")
					if (length(file)) {
						install.packages(file, repos = NULL)
						res[2] <- require(svSocket, quietly = TRUE)
					} else res[2] <- FALSE
				} else res[2] <- require(svSocket, quietly = TRUE)
			}

			## svGUI
			file <- dir(pattern = paste("svGUI", ext, sep = ".+"))
			file <- sort(file)[length(file)]	# Keep oldest one
			desc <- system.file("DESCRIPTION", package = "svGUI")
			res[3] <- TRUE
			if (desc == "") {
				cat("Installing missing package 'svGUI'\n")
				if (length(file)) {
					install.packages(file, repos = NULL)
				} else res[3] <- FALSE
			} else { # Check version
				if ((compareVersion(packageDescription("svGUI", fields = "Version"),
					minVersion["svGUI"]) < 0)) {
					cat("Updating package 'svGUI'\n")
					if (length(file)) {
						install.packages(file, repos = NULL)
					} else res[3] <- FALSE
				}
			}
			rm(desc, ext, file)

			# Try starting the R socket server
			if (inherits(try(startSocketServer(port = getOption("ko.serve")),
				silent = TRUE), "try-error")) {
				cat("Impossible to start the SciViews R socket server\n(socket",
					getOption("ko.serve"), "already in use?)\n")
				cat("Solve the problem, then type: require(svGUI)\n")
			} else {
				# Finally, load svGUI
				if (res[3]) res[3] <- require(svGUI, quietly = TRUE)

				if (all(res)) {
					cat("R is SciViews ready!\n")
					.SciViewsReady <- TRUE
				} else {
					cat("R is not SciViews ready, install latest svMisc, svSocket & svGUI packages\n")
				}
			}
		}
	}

	# Make sure Komodo is started now
	# Note: in Mac OS X, you have to create the symbolic link manually as explained
	# in the Komodo Help with:
	# sudo ln -s "/Applications/Komodo Edit.app/Contents/MacOS/komodo" /usr/local/bin/komodo
	# You must issue something similar too under Linux (see Komodo installation guide)
	# Or the script will complain.

	## Don't need this here, since R is supposed to be started from within Komodo!
	#system("komodo", wait = FALSE)

	# Look if and where komodo is installed
	if (.Platform$OS.type == "unix") {
		Komodo <- "/usr/local/bin/komodo"
		# Check that this file exists
		if (!file.exists(Komodo)) {
			# File not found, display a message with missing link
			Komodo <- NULL
			# TODO: look why I can't find Komodo on Linux Ubuntu
			#cat("Komodo is not found by R. Please, follow instructions at\n",
			#	"http://www.sciviews.org/SciViews-K to install it correctly.\n",
			#	"In particular, you must create a symbolic link in /user/local/bin:\n",
			#	"sudo ln -s <KomodoBinLocation>/komodo /usr/local/bin/komodo\n",
			#	"otherwise, R cannot find it!\n")
		} else {
			# Change the editor and the pager to Komodo
			options(editor = Komodo)
			#TODO: we need something else here: options(pager = Komodo)
		}
	} else {
		# TODO: this does not seem to work, becasue the path with spaces is not recognized?
		Komodo <- "komodo"	# On Windows, 'komodo' should be enough
		owarn <- getOption("warn")
		options(warn = -1)
		res <- try(system(Komodo, wait = FALSE), silent = TRUE)
		if (res == -1) {
			Komodo <- NULL
		#	cat("R cannot find Komodo. Please, make sure you install it correctly\n",
		#		"You can find it at http://www.activestate.com/Products/komodo_edit.\n")
		} else {
			# Change the editor and the pager to Komodo
			options(editor = Komodo)
			#TODO: we need something else here: options(pager = Komodo)
		}
		options(warn = owarn)
		rm(owarn)
	}
	rm(minVersion, res)

	# Change the working directory to the users working dir (by default) or to
	# the directory that is specified in --dir=
	dir <- args[grep("^--dir=", args)]
	if (length(dir) == 0) {
		dir <- "~"	# Use home directory as default one
	} else dir <- sub("^--dir=", "", dir)
	setwd(dir)

	# Do we load .RData and .Rhistory?
	if (!"--no-restore" %in% args && !"--no.restore-data" %in% args)
		if (file.exists(".RData")) load(".RData")
	if (!"--no-restore" %in% args && !"--no.restore-history" %in% args)
		if (file.exists(".Rhistory")) loadhistory()

	# Do we reactivate Komodo now?
	koact <- getOption("ko.activate")
	if (is.null(koact)) {
		koact <- "--ko-activate" %in% args
		options(ko.activate = koact)
	}
	if (.SciViewsReady && isTRUE(koact)) {
		if ((.Platform$pkgType == "mac.binary")) {
			system("osascript -e 'tell application \"Komodo\" to activate'",
				intern = TRUE)
		} else if (!is.null(Komodo)) {
			# TODO: The following start komodo if not started yet, but does not activate it!
			system(Komodo, wait = FALSE)
		}
		# Indicate to Komodo that R is ready
		koCmd('ko.statusBar.AddMessage("<<<data>>>", "R", 10000, true);',
			data = paste("'", getOption("ko.id"), "' (R ", R.Version()$major, ".",
			R.Version()$minor, ") connected", sep = ""))
	}
	rm(koact, Komodo, args, dir)
}
### SciViews install end ###
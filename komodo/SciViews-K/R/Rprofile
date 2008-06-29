### SciViews install begin ###
# SciViews-R installation and startup for running R with Komodo/SciViews-K
# Merge this with your .Rprofile file in your home directory to configure
# R automatically at startup

# Make sure we don't process this twice in case of duplicate items in .Rprofile
if (!exists(".SciViewsReady", envir = .GlobalEnv)) {
	.SciViewsReady <- FALSE
	minVersion <- c(R = "2.7.0", svMisc = "0.9-42", svSocket = "0.9-41", svGUI = "0.9-42")

	# Configure socket client/server
	options(ko.serve = 8888)		# Port used by the R socket server
	options(ko.host = "localhost")	# Machine where Komodo is running (local only for the moment)
	options(ko.port = 7052)			# Port used by the Komodo socket server
	options(ko.id = "R")			# The id used for this R kernel in Komodo
	options(ko.activate = FALSE)		# Do we start/activate Komodo at startup?
	# Note: set ko.activate to TRUE causes problems currently!

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
			# or upgrading them). User is supposed to have agreed

			## svMisc
			desc <- system.file("DESCRIPTION", package = "svMisc")
			if (desc == "") {
				cat("Trying to install missing package 'svMisc'\n")
				install.packages("svMisc", repos = "http://R-Forge.R-project.org")
				res <- require(svMisc, quietly = TRUE)
			} else { # Check version
				if ((compareVersion(packageDescription("svMisc", fields = "Version"),
					minVersion["svMisc"]) < 0)) {
					cat("Trying to update package 'svMisc'\n")
					install.packages("svMisc", repos = "http://R-Forge.R-project.org")
				}
				res <- require(svMisc, quietly = TRUE)
			}

			## svSocket
			desc <- system.file("DESCRIPTION", package = "svSocket")
			if (desc == "") {
				cat("Trying to install missing package 'svSocket'\n")
				install.packages("svSocket", repos = "http://R-Forge.R-project.org")
				res[2] <- require(svSocket, quietly = TRUE)
			} else { # Check version
				if ((compareVersion(packageDescription("svSocket", fields = "Version"),
					minVersion["svSocket"]) < 0)) {
					cat("Trying to update package 'svSocket'\n")
					install.packages("svSocket", repos = "http://R-Forge.R-project.org")
				}
				res[2] <- require(svSocket, quietly = TRUE)
			}

			## svGUI
			desc <- system.file("DESCRIPTION", package = "svGUI")
			if (desc == "") {
				cat("Trying to install missing package 'svGUI'\n")
				install.packages("svGUI", repos = "http://R-Forge.R-project.org")
			} else { # Check version
				if ((compareVersion(packageDescription("svGUI", fields = "Version"),
					minVersion["svGUI"]) < 0)) {
					cat("Trying to update package 'svGUI'\n")
					install.packages("svGUI", repos = "http://R-Forge.R-project.org")
				}
			}
			rm(desc)

			# Try starting the R socket server
			if (inherits(try(startSocketServer(port = getOption("ko.serve")),
				silent = TRUE), "try-error")) {
				cat("Impossible to start the SciViews R socket server\n(socket",
					getOption("ko.serve"), "already in use?)\n")
				cat("Solve the problem, then type: require(svGUI)\n")
			} else {
				# Finally, load svGUI
				res[3] <- require(svGUI, quietly = TRUE)

				if (all(res)) {
					cat("R is SciViews ready!\n")
					.SciViewsReady <- TRUE
					if (is.null(getOption("ko.id"))) options(ko.id = "R")	# Default
					# Do we (re)activate Komodo now?
					koact <- getOption("ko.activate")
					if (is.null(koact)) koact <- FALSE
					if (koact[1]) {
						if ((.Platform$pkgType == "mac.binary")) {
							Res <- system("osascript -e 'tell application \"Komodo\" to activate'",
								intern = TRUE)
							rm(Res)
						}	### TODO: the same under Windows and Linux
						# Indicate to Komodo that R is ready
						koCmd('ko.statusBar.AddMessage("<<<data>>>", "R", 10000, true);',
							data = paste("'", getOption("ko.id"), "' (R ", R.Version()$major, ".",
							R.Version()$minor, ") connected", sep = ""))
					}
					rm(koact)
				} else {
					cat("R is not SciViews ready, install latest svMisc, svSocket & svGUI packages\n")
				}
			}
		}
	}

	# Clean up .GlobalEnv
	rm(minVersion, res)

	# Make sure Komodo is started now
	# Note: in Mac OS X, you have to create the symbolic link manually as explained in the Komodo Help with:
	# sudo ln -s "/Applications/Komodo Edit.app/Contents/MacOS/komodo" /usr/local/bin/komodo
	# Or the script will complain with: /bin/sh: line 1: komodo: command not found.
	system("komodo", wait = FALSE)

	# Make sure to use Komodo as your R editor
	
}

### SciViews install end ###
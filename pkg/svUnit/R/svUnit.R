svUnit <-
function (tests) {
	# Check provided tests and build a 'svUnit' object
	tests <- as.character(tests)
	# Remove NAs and empty strings ("") from tests
	tests <- tests[!is.na(tests) & !(tests == "")]
	if (length(tests) > 0) {
		# Tests must be character strings like:
		# * package:PKG
		# * package:PKG (TESTSUITE)
		# * dir:MYDIR
		# * test(OBJ) where OBJ is any object with a 'test' attribute
		# * OBJ being a 'svTest' object (with non "exotic" name!),
		# Syntax is checked, but not the existence/validity of corresponding tests!
		check1 <- (regexpr("^package:[a-zA-Z._]+$", tests) > -1)
		check2 <- (regexpr("^package:[a-zA-Z._]+ *\\(.+\\)$", tests) > -1)
		check3 <- (regexpr("^dir:.+", tests) > -1)
		check4 <- (regexpr("^test\\(.+\\)$", tests) > -1)
		check5 <- (regexpr("^[a-zA-Z0-9_.]+$", tests) > -1)
		wrong <- ((check1 + check2 + check3 + check4 + check5) == 0)
		if (any(wrong))
			stop("Wrong 'test' data: must be 'package:PKG', 'package:PKG (SUITE)',\n'dir:MYDIR', 'test(OBJ)' or 'OBJ'")
	}
	class(tests) <- "svUnit"
	return(tests)
}

as.svUnit <-
function (x)
	return(svUnit(x))

is.svUnit <-
function (x)
	return(inherits(x, "svUnit"))

print.svUnit <-
function (x, ...) {
	if (!is.svUnit(x))
		stop("'x' must be a 'svUnit' object")
	if (length(x) < 1) {
		cat("An empty svUnit test suite\n")
	} else {
		cat("A svUnit test suite definition with:\n")
		# Separate unit tests from tests embedded in objects
		isSuite <- regexpr("^[package:|dir:]", x) > -1
		if (any(isSuite)) {
			Suites <- x[isSuite]
			msg <- ifelse (length(Suites) == 1, "\n- Test suite:\n",
				"\n- Test suites:\n")
			cat(msg)
			print(Suites)
		}

		if (any(!isSuite)) {
			Objs <- x[!isSuite]
			msg <- ifelse (length(Objs) == 1, "\n- Test function:\n",
				"\n- Test functions:\n")
			cat(msg)
			print(Objs)
		}
	}
	return(invisible(x))
}

svUnitList <-
function (packages = TRUE, objects = TRUE, pos = .GlobalEnv) {
	# List unit test (1) in loaded packages and (2) in objects in pos
	# Note: Komodo should list test files in loaded projects too!
	if (length(packages) < 1)
		stop("'package' cannot have zero length")
	if (length(objects) < 1)
		stop("'objects' cannot have zero length")

	items <- character()

	# 1) Unit test files in loaded packages
	if (packages[1] != FALSE) {
		if (is.character(packages)) {	# We assume it is a list of packages
			Pkgs <- packages
		} else {	# We use the list of all loaded packages
			Pkgs <- .packages()
		}
		for (Pkg in Pkgs) {
			path <- system.file(package = Pkg, "unitTests")
			if (path != "" && file.info(path)$isdir) {
				pkgname <- paste("package", Pkg, sep = ":")
				items <- c(items, pkgname)
				Files <- list.files(path = path, full.names = TRUE)
				for (File in Files) { # Add all subdirectories too
					if (file.info(File)$isdir)
						items <- c(items, paste(pkgname, " (", basename(File),
							")", sep = ""))
				}
			}
		}
	}

	# 2) Test embedded in objects located in 'pos' environment
	if (objects[1] != FALSE) {
		envir = as.environment(pos)
		if (is.character(objects)) {
			tests <- character()
			for (Oname in objects) {
				if (exists(Oname, envir = envir, inherits = FALSE)) {
					Obj <- get(Oname, envir = envir, inherits = FALSE)
					if (is.svTest(Obj)) {
						tests <- c(tests, Oname)
					} else if (is.test(Obj)) {
						tests <- c(tests, paste("test(", Oname, ")", sep = ""))
					}
				}
			}
		} else {	# We list all objects in pos
			Objs <- mget(ls(envir = envir), envir = envir)
			Onames <- names(Objs)
			tests <- character()
			if (length(Objs) > 0) {
				for (i in 1:length(Objs)) {
					if (is.svTest(Objs[[i]])) {
						tests <- c(tests, Onames[i])
					} else if (is.test(Objs[[i]])) {
						tests <- c(tests, paste("test(", Onames[i], ")", sep = ""))
					}
				}
			}
		}
		items <- c(items, sort(tests))
	}
	# Make it a 'svUnit' object
	class(items) <- "svUnit"
	return(items)
}

makeUnit.svUnit <-
function(x, name = make.names(deparse(substitute(x))), dir = tempdir(),
pos = .GlobalEnv, ...) {
	# Take an 'svUnit' object and make a unit from its function tests
	# It is saved in a file runit.<name>.R in 'dir'
	if (!is.svUnit(x))
		stop("'x' must be a 'svUnit' object")
	name <- as.character(name[1])
	dir <- as.character(dir[1])
	# Check that dir exists (do not create it!)
	if (!file.exists(dir) || !file.info(dir)$isdir)
		stop("'dir' must be an existing directory")

	# Collect all items that are not 'package:...' or 'dir:...'
	isObj <- regexpr("^[package:|dir:]", x) == -1
	Objs <- sub("^test[(](.+)[)]$", "\\1", x[isObj])
	if (length(Objs) == 0) {
		# No objects, return NULL
		return(NULL)
	}

	Unit <- file.path(dir, paste("runit", name, "R", sep = "."))
	cat("# Test unit '", name, "'\n", sep = "", file = Unit)

	# Collect all tests from Objs together in the test unit
	# We provide the name of objects located in 'pos' environment
	for (objname in Objs) {
		if (regexpr("^test\\.", objname) > -1) testname <- objname else
			testname <- paste("test", objname, sep = ".")
		testname <- make.names(testname)
		cat('\n"', testname, '" <-\n', sep = "", file = Unit, append = TRUE)
		if (!exists(objname, where = pos)) {
			# Create a dummy test with DEACTIVATED entry
			body <- c(
				'function() {',
				paste('\tDEACTIVATED("Object', objname, 'not found!")'),
				'}\n')
		} else {
			Test <- test(get(objname, pos = pos))
			if (is.null(Test)) {
				# Create a dummy test with DEACTIVATED entry
				body <- c(
					'function() {',
					paste('\tDEACTIVATED("Object', objname, 'has no tests!")'),
					'}\n')
			} else {
				capture.body <-
				function(Data) {
					rval <- NULL
					File <- textConnection("rval", "w", local = TRUE)
					sink(File)
					on.exit({ sink(); close(File) })
					dput(Data, file = File, control = "useSource")
					on.exit()
					sink()
					close(File)
					return(rval)
				}
				body <- capture.body(Test)
			}
		}
		cat(body, sep = "\n", file = Unit, append = TRUE)
	}
	return(Unit)
}

runTest.svUnit <-
function(x, name = make.names(deparse(substitute(x))), ...) {
	# Compile and run the test for this 'svUnit' object
	if (!is.svUnit(x))
		stop("'x' must be a 'svUnit' object")
	name <- as.character(name[1])

	# Decode tests contained in x
	tests <- as.character(x)
	dirs <- character()
	# Package suites...
	isPkg <- regexpr("^package:", tests) > -1
	if (any(isPkg)) {
		Pkgs <- tests[isPkg]
		Subdirs <- sub("^.+[(](.+)[)] *$", "\\1", Pkgs)
		Subdirs[Subdirs == Pkgs] <- ""
		Pkgs <- sub("^package:([^ ]+).*$", "\\1", Pkgs)
		for (i in 1:length(Pkgs)) {
			dir <- system.file(package = Pkgs[i], "unitTests", Subdirs[i])
				if (dir != "") dirs <- c(dirs, dir)
		}
	}

	# Add directories, and possibly make a temporary unit for test objects
	if (any(!isPkg)) {
		tests <- tests[!isPkg]
		# Directories
		isDir <- regexpr("^dir:", tests) > -1
		if (any(isDir))
			dirs <- c(dirs, sub("^dir:", "", tests[isDir]))
		# Objects
		if (any(!isDir)) {
			# make a temporary unit for the tests of these objects
			if (!is.null(Unit <- makeUnit(x, name = name))) {
				# Add this path to dirs, and make sure that the temporary file
				# is destroyed at the end
				dirs <- c(dirs, dirname(Unit))
				on.exit(unlink(Unit))
			}
		}
	}

	# Run these tests now
	res <- runUnit(name = name, dirs = dirs)
	return(invisible(res))
}

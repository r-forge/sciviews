runUnit <-
function(name, dirs, print.errors = !interactive(), warn = print.errors,
	rngKind = "Marsaglia-Multicarry", rngNormalKind = "Kinderman-Ramage") {
	# Define a test suite and run it more silently than done in RUnit
	# Also, increment counters with errors, failings and deactivated

	# Define a test suite and run it (same as defineTestSuite() in RUnit)
	testSuite <- list(name = name, dirs = dirs,
		testFileRegexp = "^runit.+\\.[rR]$", testFuncRegexp = "^test.+",
		rngKind = rngKind, rngNormalKind = rngNormalKind)
	class(testSuite) <- "RUnitTestSuite"

	# runTestSuite() prints results of tests, but we prefer to run it
	# more silently than in RUnit
	runSuite <- function (testSuite) {
		file <- textConnection("rval", "w", local = TRUE)
		sink(file, type = "output")
		sink(file, type = "message")
		on.exit({
			sink(type = "output")
			sink(type = "message")
			close(file)
		})
		return(runTestSuite(testSuites = testSuite))
	}
	res <- runSuite(testSuite)

	# Check that res is a 'RUnitTestData' object
	if (!inherits(res, "RUnitTestData"))
		stop("Result of runTestSuite() is not a 'RUnitTestData' object")

	# If there are errors, failures or deactivated items, increment counters
	err <- list(nErr = 0, nDeactivated = 0, nFail = 0, nTestFunc = 0)
    for (i in seq(length = length(res))) {
        err$nErr <- err$nErr + res[[i]]$nErr
        err$nDeactivated <- err$nDeactivated + res[[i]]$nDeactivated
        err$nFail <- err$nFail + res[[i]]$nFail
	}

	if (err$nErr > 0) {
		if (exists(".tests.errors", envir = .GlobalEnv, inherits = FALSE)) {
			nErr <- get(".tests.errors", envir = .GlobalEnv, inherits = FALSE)
		} else nErr <- 0
		assign(".tests.errors", nErr + err$nErr, envir = .GlobalEnv)
	}
	if (err$nFail > 0) {
		if (exists(".tests.failures", envir = .GlobalEnv, inherits = FALSE)) {
			nFail <- get(".tests.failures", envir = .GlobalEnv, inherits = FALSE)
		} else nFail <- 0
		assign(".tests.failures", nFail + err$nFail, envir = .GlobalEnv)
	}
	if (err$nDeactivated > 0) {
		if (exists(".tests.deactivated", envir = .GlobalEnv, inherits = FALSE)) {
			nDeactivated <- get(".tests.deactivated", envir = .GlobalEnv,
				inherits = FALSE)
		} else nDeactivated <- 0
		assign(".tests.deactivated", nDeactivated + err$nDeactivated, envir = .GlobalEnv)
		if (warn) warning("Test unit '", name, "' has ", err$nDeactivated, " deactivated items")
	}

	# Change class to c('svUnitData', 'RUnitTestData') to overload summary()
	class(res) <- c('svUnitData', 'RUnitTestData')

	# Do we print a summary of these tests in case of errors or failures?
	if (print.errors && (err$nErr + err$nFail) > 0)
		summary(res)

	return(invisible(res))
}

print.svUnitData <-
function(x, ...) {
	if (!inherits(x, "svUnitData"))
		stop("'x' must be a 'svUnitData' object")
	if (length(x) == 0) {
        cat("no test cases\n")
        return(invisible(TRUE))
    }
	err <- list(nErr = 0, nDeactivated = 0, nFail = 0, nTestFunc = 0)
    for (i in seq(length = length(x))) {
        err$nErr <- err$nErr + x[[i]]$nErr
        err$nDeactivated <- err$nDeactivated + x[[i]]$nDeactivated
        err$nFail <- err$nFail + x[[i]]$nFail
		err$nTestFunc <- err$nTestFunc + x[[i]]$nTestFunc
	}
    cat("Number of test functions:", err$nTestFunc, "\n")
    if (err$nDeactivated > 0)
        cat("Number of deactivated test functions:", err$nDeactivated, "\n")
    cat("Number of errors:", err$nErr, "\n")
    cat("Number of failures:", err$nFail, "\n")
	return(invisible(x))
}

summary.svUnitData <-
function(object, ...) {
	if (!inherits(object, "svUnitData"))
		stop("'object' must be a 'svUnitData' object")

    sop <- function(number, word, plext = "s") {
        ifelse(number == 1, paste(number, word), paste(number,
            paste(word, plext, sep = "")))
    }

    if (length(object) == 0) {
        cat("no test cases\n")
        return(invisible(object))
    }
	err <- list(nErr = 0, nDeactivated = 0, nFail = 0, nTestFunc = 0)
    for (i in seq(length = length(object))) {
        err$nErr <- err$nErr + object[[i]]$nErr
        err$nDeactivated <- err$nDeactivated + object[[i]]$nDeactivated
        err$nFail <- err$nFail + object[[i]]$nFail
		err$nTestFunc <- err$nTestFunc + object[[i]]$nTestFunc
	}
    cat("Number of test functions:", err$nTestFunc, "\n")
    if (err$nDeactivated > 0)
        cat("Number of deactivated test functions:", err$nDeactivated, "\n")
    cat("Number of errors:", err$nErr, "\n")
    cat("Number of failures:", err$nFail, "\n")

    if (err$nErr + err$nDeactivated + err$nFail == 0)
		return(invisible(object))

	cat("Details:\n")
	traceBackCutOff <- 9 	# Cut unintersting part of the traceBack
    for (tsName in names(object)) {
        tsList <- object[[tsName]]
        cat("===========================\n")
        cat("Test Suite:", tsName, "\n")
        if (length(tsList$dirs) == 0) {
            cat("No directories !\n")
        } else {
            res <- tsList$sourceFileResults
            testFileNames <- names(res)
            if (length(res) == 0) {
                cat("no test files\n")
            } else {
                for (testFileName in testFileNames) {
					testFuncNames <- names(res[[testFileName]])
					if (length(testFuncNames) > 0) {
						cat("---------------------------\n")
						cat("Test file:", testFileName, "\n")
						for (testFuncName in testFuncNames) {
							testFuncInfo <- res[[testFileName]][[testFuncName]]
							if (testFuncInfo$kind == "success") {
								cat(testFuncName, ":", " ... OK (", testFuncInfo$time,
									" seconds)\n", sep = "")
							 } else {
								if (testFuncInfo$kind == "error") {
									cat(testFuncName, ": ERROR !!\n", sep = "")
								} else if (testFuncInfo$kind == "failure") {
									cat(testFuncName, ": FAILURE !! (check number ",
										testFuncInfo$checkNum, ")\n", sep = "")
								} else if (testFuncInfo$kind == "deactivated") {
									cat(testFuncName, ": DEACTIVATED, ")
								} else {
									cat(testFuncName, ": unknown error kind\n", sep = "")
								}
								cat(testFuncInfo$msg)
								if (length(testFuncInfo$traceBack) > 0) {
									cat("   Call Stack:\n")
									if (traceBackCutOff > length(testFuncInfo$traceBack)) {
										cat("   (traceBackCutOff argument larger than length of trace back: full trace back printed)")
										for (i in 1:length(testFuncInfo$traceBack)) {
											cat("   ", i, ": ", testFuncInfo$traceBack[i],
												"\n", sep = "")
										}
									} else {
										for (i in traceBackCutOff:length(testFuncInfo$traceBack)) {
											cat("   ", 1 + i - traceBackCutOff,
												": ", testFuncInfo$traceBack[i],
												"\n", sep = "")
										}
									}
								}
							}
						}
					}
                }
            }
        }
    }
    return(invisible(TRUE))
}

unitClear <-
function () {
	# Clear .tests.errors.tests.failures and .tests.deactivated from .GlobalEnv
	if (exists(".tests.errors", envir = .GlobalEnv, inherits = FALSE)) {
		nErr <- get(".tests.errors", envir = .GlobalEnv, inherits = FALSE)
		rm(".tests.errors", envir = .GlobalEnv, inherits = FALSE)
	} else nErr <- 0
	if (exists(".tests.failures", envir = .GlobalEnv, inherits = FALSE)) {
		nFail <- get(".tests.failures", envir = .GlobalEnv, inherits = FALSE)
		rm(".tests.failures", envir = .GlobalEnv, inherits = FALSE)
	} else nFail <- 0
	if (exists(".tests.deactivated", envir = .GlobalEnv, inherits = FALSE)) {
		nDeactivated <- get(".tests.deactivated", envir = .GlobalEnv,
			inherits = FALSE)
		rm(".tests.deactivated", envir = .GlobalEnv, inherits = FALSE)
	} else nDeactivated <- 0
	return(invisible(list(nErr = nErr, nDeactivated = nDeactivated,
		nFail = nFail)))
}

unitError <-
function (errors = TRUE, failures = TRUE, deactivated = TRUE,
stopit = TRUE) {
	# Read the content of .tests.errors and .tests.failures from .GlobalEnv
	allErr <- 0
	if (errors) {
		if (exists(".tests.errors", envir = .GlobalEnv, inherits = FALSE)) {
			nErr <- get(".tests.errors", envir = .GlobalEnv, inherits = FALSE)
			allErr <- nErr
		} else nErr <- 0
	} else nErr <- NA

	if (failures) {
		if (exists(".tests.failures", envir = .GlobalEnv, inherits = FALSE)) {
			nFail <- get(".tests.failures", envir = .GlobalEnv, inherits = FALSE)
			allErr <- allErr + nFail
		} else nFail <- 0
	} else nFail <- NA

	# Are there deactivated items?
	if (deactivated) {
		if (exists(".tests.deactivated", envir = .GlobalEnv, inherits = FALSE)) {
			nDeactivated <- get(".tests.deactivated", envir = .GlobalEnv,
				inherits = FALSE)
		if (stopit)	# Issue a warning!
			warning("There are ", nDeactivated, " deactivated tests!")
		} else nDeactivated <- 0
	} else nDeactivated <- NA

	# Do we stop in case of any error?
	if (stopit && allErr > 0) {
		msg <- paste("\nUnit test errors:  ", nErr, "\n")
		msg <- paste(msg, "Unit test failures: ", nFail, sep = "")
		stop(msg)
	}
	res <- (allErr == 0)
	attr(res, "errors") <- list(nErr = nErr, nDeactivated = nDeactivated,
		nFail = nFail)
	return(invisible(res))
}

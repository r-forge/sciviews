svTest <-
function (testFun) {
	# Create a 'svTest' object, using testFun: a function without arguments
	if (!is.function(testFun))
		stop("'testFun' must be a function or a 'svTest' object")
	# Check that there are no arguments
	if (length(formals(testFun)) > 0)
		stop("'testFun' must be a function without any arguments")
	# This is a S3 object of class 'svTest'
	class(testFun) <- "svTest"
	return(testFun)
}

as.svTest <-
function (x) {
	# Coercion to a 'svTest' object
	return(svTest(x))
}

is.svTest <-
function (x) {
	# It this a svTest object
	return(inherits(x, "svTest"))
}

is.test <-
function (x) {
	# Is this a test object (indeed a 'svTest' one)
	# or do this object contain a non NULL 'test' attribute
	return(is.svTest(x) || !is.null(attr(x, "test")))
}

test <-
function (x) {
	# If x is a 'svTest' object, return it, otherwise,
	# get the 'test' attribute from the object, if it exists
	if (is.svTest(x)) {
		return(x)
	} else {
		return(attr(x, "test"))
	}
}

`test<-` <-
function (x, value) {
	# Add 'value' as a 'test' attribute to 'x' after coercing to 'svTest'
	attr(x, "test") <- as.svTest(value)
    return(x)
}

makeUnit <-
function(x, ...)
	UseMethod("makeUnit")

makeUnit.default <-
function(x, name = make.names(deparse(substitute(x))), dir = tempdir(), ...) {
	# Take an object and make a unit from the tests it contains
	# It is saved in a file runit.<name>.R in 'dir'
	name <- as.character(name[1])
	dir <- as.character(dir[1])
	# Check that dir exists (do not create it!)
	if (!file.exists(dir) || !file.info(dir)$isdir)
		stop("'dir' must be an existing directory")

	Unit <- file.path(dir, paste("runit", name, "R", sep = "."))
	cat("# Test unit '", name, "'\n", sep = "", file = Unit)

	# Just get the test from the object
	Test <- test(x)
	# Make sure the name start with "test."
	if (regexpr("^test\\.", name) > -1) testname <- name else
		testname <- paste("test", name, sep = ".")
	testname <- make.names(testname)
	cat('\n"', testname, '" <-\n', sep = "", file = Unit, append = TRUE)
	if (is.null(Test)) {
		# Create a dummy test with DEACTIVATED entry
		body <- c(
			'function() {',
			paste('\tDEACTIVATED("Object', deparse(substitute(x)), 'has no tests!")'),
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
	cat(body, sep = "\n", file = Unit, append = TRUE)

	return(Unit)
}

makeUnit.svTest <-
function(x, name = make.names(deparse(substitute(x))), dir = tempdir(), ...)
	return(makeUnit.default(x, name = name, dir = dir, ...))

runTest <-
function(x, ...)
	UseMethod("runTest")

runTest.default <-
function(x, name = make.names(deparse(substitute(x))), ...) {
	# Run the test for the 'test' attribute of this object
	Test <- test(x)
	if (is.null(Test) || !inherits(Test, "svTest"))
		Test <- svTest(function () DEACTIVATED("Object has no tests!"))
	return(runTest(Test, name = name, ...))
}

runTest.svTest <-
function(x, name = make.names(deparse(substitute(x))), ...) {
	# Make a test unit with the test data
	Unit <- makeUnit(x, name = name, ...)
	if (is.null(Unit)) return(NULL)	# No tests to run!
	# Make sure that the temporary test unit file is destroyed when done
	on.exit(unlink(Unit))

	# Run the tests now
	res <- runUnit(name = name, dirs = dirname(Unit), ...)
	return(res)
}

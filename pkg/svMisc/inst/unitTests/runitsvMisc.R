## runitsvMisc.R test suite
## by Ph. Grosjean <phgrosjean@sciviews.org>
## run it simply by example(unitTests.svMisc)

## The test cases
.setUp <- function () {}

.tearDown <- function () {}

testparseText <- function () {
	checkTrue(is.na(parseText("1 +")), msg = "parseText() returns NA when parsing incomplete command")
	## TODO: the other tests...
}

testcaptureAll <- function () {
	## A couple of expressions and expected results from captureAll()
	expr1 <- parse(text = 1+1)
	res1 <- c("[1] 2", "")	# Note: should we really always got that empty string at the end???
	
	## General tests of captureAll()
	## TODO...

	## Test of 'expr' argument
	## Expected behaviour: expr can be an expression, a name, a call (and they are evaluated),
	## or NA, and it is passed through. Anything else raises an exception
	checkTrue(is.na(captureAll(NA)), msg = "captureAll() returns NA when expr is NA")
	checkException(captureAll(1), msg = "captureAll(1) raises error (expr only expression or NA)")
	checkException(captureAll("1+1"), msg = "captureAll(\"1+1\") raises error (expr only expression or NA)")
	checkException(captureAll(TRUE), msg = "captureAll(TRUE) raises error (expr only expression or NA)")
	checkException(captureAll(NULL), msg = "captureAll(NULL) raises error (expr only expression or NA)")
	checkException(captureAll(logical(0)), msg = "captureAll(logical(0)) raises error (expr only expression or NA)")
	
	## Test of 'split' argument
	## TODO: we cannot check if split is correct, but at least, we can check it does not raise error
	## Expected behaviour: split can be anything, but only split = TRUE do split the output
	checkIdentical(res1, captureAll(expr1, split = TRUE), msg = "captureAll(...., split = TRUE) test")
	checkIdentical(res1, captureAll(expr1, split = FALSE), msg = "captureAll(...., split = FALSE) test")
	checkIdentical(res1, captureAll(expr1, split = c(TRUE, FALSE)), msg = "captureAll(...., split = c(TRUE, FALSE)) test")
	checkIdentical(res1, captureAll(expr1, split = logical(0)), msg = "captureAll(...., split = logical(0)) test")
	checkIdentical(res1, captureAll(expr1, split = NULL), msg = "captureAll(...., split = NULL) test")
	checkIdentical(res1, captureAll(expr1, split = "TRUE"), msg = "captureAll(...., split = \"TRUE\") test")
	checkIdentical(res1, captureAll(expr1, split = 1), msg = "captureAll(...., split = 1) test")
	checkIdentical(res1, captureAll(expr1, split = NA), msg = "captureAll(...., split = NA) test")
	
	## TODO:... other tests (warnings, errors, sink(), capture.output(), interactive commands -how?-, etc.)
}

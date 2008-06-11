# runit.unitFunctions.R test suite
# by Ph. Grosjean <phgrosjean@sciviews.org>
# run it simply by example(unitTests.svUnit)

.setUp <- function () {
	# Executed before each test function
	# ... your code here
}

.tearDown <- function () {
	# Executed after each test function
	# ... your code here
}

test.svUnit <- function () {
	checkTrue(is.svUnit(svUnitList()),					"svUnitList() returns a 'svUnit' object")#1
	checkTrue("package:svUnit" %in% svUnitList(),		"svUnitList() lists 'svUnit' package")	#2
	checkTrue("package:svUnit (VirtualClass)" %in% svUnitList(), "svUnitList() lists 'VirtualClass' suite")	#3

	# Create a 'svTest' object and another object containing a test in .GlobalEnv
	test.R <<- svTest(function () {
		checkTrue(1 < 2)
	})

	foo <- function(x) return(x)
	test(foo) <- function () {
		checkEqualsNumeric(foo(2), 2)
		checkException(foo("xx"))
	}
	Foo <<- foo 	# Place a copy of 'foo' in .GlobalEnv

	checkTrue("test.R" %in% svUnitList(),					"svUnitList() lists 'svTest' objects")	#4
	checkTrue("test(Foo)" %in% svUnitList(),				"svUnitList() lists objects with tests")	#5
	rm(foo)
	rm(test.R, Foo, pos = .GlobalEnv)
}

test.runTest <- function () {
	# A simple svTest object
	test.R <- svTest(function () {
		checkTrue(1 < 2)
	})
	checkTrue(inherits(runTest(test.R), "svUnitData"), "result of runTest(svTest) is svUnitData")	#1

	### TODO: more tests!
	rm(test.R)
}

test.unitErrorClear <- function() {
	### TODO: tests for unitError() and unitClear()
}
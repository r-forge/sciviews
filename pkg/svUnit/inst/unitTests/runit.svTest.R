# runit.svTest.R test suite
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

test.svTest <- function () {
	# An R object
	mat <- matrix(rnorm(4), ncol = 2)
	# An example function
	foo <- function(x) return(x)

	checkTrue(!is.test(mat), 						"No associated test cases to 'mat'")	#1
	checkTrue(!is.test(foo), 						"No associated test cases to 'foo'")	#2
	checkTrue(is.null(test(foo)), 					"Return NULL if no test cases")			#3
	checkTrue(!is.test(test(foo)),					"No 'svTest' object if no test cases")	#4
	checkTrue(!is.test(mat),						"This is not a 'svTest' object (1)")	#5
	checkTrue(!is.test(foo),						"This is not a 'svTest' object (2)")	#6
	checkTrue(!is.svTest(foo),						"This is not a 'svTest' object (3)")	#7
	checkTrue(!is.test("x"),						"This is not a 'svTest' object (4)")	#8
	checkTrue(!is.test(NULL),						"This is not a 'svTest' object (5)")	#9
	checkTrue(!is.test(NA),							"This is not a 'svTest' object (6)")	#10

	# Create very simple test cases for matrix 'mat' and function 'foo'
	test.mat <- svTest(function () {
		checkEqualsNumeric(nrow(mat), 2)
		checkTrue(is.numeric(mat))
	})

	test.foo <- function () {
		checkEqualsNumeric(foo(2), 2)
		checkException(foo("xx"))
	}

	checkTrue(is.test(svTest(test.foo)),			"Creation of a 'svTest' object")		#11
	checkTrue(is.test(as.svTest(test.foo)),			"Coercion to a 'svTest' object")		#12
	checkException(svTest(foo),						"Functions with arguments not allowed")	#13
	checkException(svTest("x"),						"Strange argument to svTest")			#14

	# Add test cases to an object
	test(mat) <- test.mat

	checkTrue(is.test(mat), 						"'mat' has associated test cases")		#15
	checkIdentical(test(mat), test.mat,				"test of 'mat' identical to 'test.mat'")#16
	checkTrue(is.test(test.mat),					"Is this a 'svTest' object (1)?")		#17
	checkTrue(is.svTest(test.mat),					"Is this a 'svTest' object (2)?")		#18


	# Use a function as test
	test(foo) <- test.foo

	checkTrue(has.test(foo), 						"'foo' has associated test cases")		#19
	checkEquals(test(foo), svTest(test.foo),		"test of 'foo' equals 'test.foo'")		#20
	checkTrue(!is.test(test.foo),					"Is this a 'svTest' object (3)?")		#21
	checkTrue(is.svTest(test.foo),					"Is this a 'svTest' object (4)?")		#22


	# Transform into a svTest object and use it as test
	test.foo <- as.svTest(test.foo)
	test(foo) <- test.foo

	checkIdentical(test(test.foo), test.foo,		"'test' returns a 'svTest' object")		#23
	checkTrue(is.test(test.foo),					"Is this a 'svTest' (5)?")				#24
	checkTrue(is.test(foo), 						"'foo' has associated test cases")		#25
	checkIdentical(test(foo), test.foo,				"test of 'foo' identical to 'test.foo'")#26

	checkException(test(foo) <- "x",				"Strange value to assign as 'test'")	#27
	checkException(test(foo) <- function(y) y, 		"Try assign a function with arguments")	#28

	# Strange,... but allowed
	test(test.foo) <- test.foo

	checkIdentical(test(test.foo), test.foo,		"Assigning test to oneself")			#29
}

\name{svTest}
\alias{svTest}
\alias{as.svTest}
\alias{is.svTest}
\alias{test}
\alias{test<-}
\alias{is.test}
\alias{makeUnit}
\alias{makeUnit.default}
\alias{makeUnit.svTest}
\alias{runTest}
\alias{runTest.default}
\alias{runTest.svTest}

\title{ Create, attach to and manipulate test functions in R objects }
\description{
  Test functions are functions without arguments with class 'svTest' containing
  one or more assertions using \code{checkXXX()} functions from RUnit (see
  examples). They can be attached to any object as a 'test' attribute, written
  to unit files or run.
}

\usage{
svTest(testFun)
as.svTest(x)
is.svTest(x)

test(x)
test(x) <- value
is.test(x)

makeUnit(x, \dots)
\method{makeUnit}{default}(x, name = make.names(deparse(substitute(x))),
	dir = tempdir(), \dots)
\method{makeUnit}{svTest}(x, name = make.names(deparse(substitute(x))),
	dir = tempdir(), \dots)

runTest(x, \dots)
\method{runTest}{default}(x, name = make.names(deparse(substitute(x))), \dots)
\method{runTest}{svTest}(x, name = make.names(deparse(substitute(x))), \dots)
}

\arguments{
  \item{testFun}{ A function without arguments defining assertions for tests to
    be transformed into a 'svTest' object }
  \item{x}{ Any kind of object }
  \item{value}{ The tests to place in the object (as 'test' attribute).
    Could be a 'svTest' object, or a function without arguments with assertions
	(\code{checkXXX()} functions) }
  \item{name}{ The name of a test unit }
  \item{dir}{ The directory where to create a test unit }
  \item{\dots}{ Further arguments to the method (not used yet) }
}

\value{
  A 'svTest' object for \code{svTest()}, \code{as.svTest()}
  and \code{test()}. Function \code{is.svTest()} returns \code{TRUE} if 'x' is
  a 'svTest' object, and \code{is.test()} does the same but also looks in the
  'test' attribute if the class of 'x' is not 'svTest' and returns \code{TRUE}
  if it finds something there.

  \code{makeUnit()} takes an object, extract its test function and write it in
  a sourceable test unit on the disk. RUnit functions need such files.

  \code{runTest()} returns a 'svUnitData' object identical (for the moment) to
  the 'RUnitTestData' objects returned by \code{runTestSuite()} in package
  RUnit.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{svUnit}}, \code{\link{runUnit}},
  \code{\link[RUnit]{checkTrue}}, \code{\link[RUnit]{runTestSuite}} }

\examples{
foo <- function(x, y = 2) return(x * y)
is.test(foo)	# No
# Create test cases for this function
test(foo) <- function () {
	checkEqualsNumeric(foo(2), 4)
	checkEqualsNumeric(foo(2, 3), 6)
	checkTrue(is.test(foo))
	checkTrue(is.test(test(foo)))
	checkIdentical(test(foo), attr(foo, "test"))
	checkException(foo(2, "aa"))
	checkException(foo("bb"))
}
is.test(foo)	# Yes

\dontrun{
# Create a test unit on disk and view it
unit <- makeUnit(foo)
file.show(unit, delete.file = TRUE)
}

# Run the test
(runTest(foo))
# Same as
bar <- test(foo)
(runTest(bar))

is.svTest(test(foo))	# Yes, of course!
# When an object without associated test is passed to runTest(), a simple
# test containing only a DEACTIVATED entry is build
x <- 1:10
summary(runTest(x))

rm(foo, bar, x)
}

\keyword{ utilities }

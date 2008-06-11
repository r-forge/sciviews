\name{svUnit}
\alias{svUnit}
\alias{as.svUnit}
\alias{is.svUnit}
\alias{svUnitList}
\alias{print.svUnit}
\alias{makeUnit.svUnit}
\alias{runTest.svUnit}

\title{ Create and run test units by collecting together RUnit tests and tests
  defined in objects }
\description{
  A 'svUnit' object is essentially a list of test units directories, and of
  object names containing tests to add to the test unit. These must be formatted
  in a concise way as described for the 'tests' argument.

  \code{svUnitList()} lists all loaded packages having /unitTests/runit*.R files
  (or similar files in subdirectories), and all objects in the user workspace
  that have a 'test' attribute, or are 'svTest' objects (by default). It is a
  rather exhaustive list of all test items currently available in this session.

  \code{makeUnit()} writes a test unit on disk with the tests from the objects
  lised in 'svUnit'. \code{runTest()} runs all the test in packages, directories
  and objects listed in the 'svUnit' object.
}

\usage{
svUnit(tests)

as.svUnit(x)
is.svUnit(x)

svUnitList(packages = TRUE, objects = TRUE, pos = .GlobalEnv)

\method{print}{svUnit}(x, \dots)
\method{makeUnit}{svUnit}(x, name = make.names(deparse(substitute(x))),
	dir = tempdir(), pos = .GlobalEnv, \dots)
\method{runTest}{svUnit}(x, name = make.names(deparse(substitute(x))), \dots)
}

\arguments{
  \item{tests}{ A character string with items to include in the test suite.
    It could be 'package:PKG' for including test units located in the /unitTests
	subdirectory of the package PGK, or 'package:PKG (SUITE)' for test units
	located in the subdirectory /unitTests/SUITE of package PKG, or 'dir:MYDIR'
	for including test units in MYDIR, or 'test(OBJ)' for tests embedded in an
	object, or 'OBJ' for 'svTest' object directly }
  \item{x}{ Any kind of object }
  \item{packages}{ Do we list test units available in loaded packages?
    Alternatively one can provide a character vector of package names, and it
	will be used to filter packages (take care: in this case it will look at
	installed packages, not only loaded packages!) }
  \item{objects}{ Do we list test available in objects? Alternatively, one can
    provide a character vector of object names, and it will filter objects in
	'pos' according to this vector }
  \item{pos}{ The environment to look for 'objects' (environment, character
    string with name of an environment, or interger with position of the
	environment in the search path }
  \item{\dots}{ Further arguments to pass to \code{makeUnit()} and
    \code{defineTestsuite()} from the RUnit package }
  \item{name}{ The name of the test suite to build. }
  \item{dir}{ The directory where to create the test unit file }
}

\value{
  \code{svUnit()}, \code{as.svUnit()} and \code{svUnitList} return a 'svUnit'
  object. \code{is.svUnit()} returns \code{TRUE} if the object is an 'svUnit'.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{runUnit}}, \code{\link{svTest}},
	\code{\link[RUnit]{defineTestSuite}} }

\examples{
svUnitList()	# List all currently available test units and test cases

# Two functions that include their test cases
Square <- function(x) return(x^2)
test(Square) <- function() {
	checkEquals(Square(3), 9)
	checkEquals(Square(1:3), c(1, 4, 9))
	checkException(Square("xx"))
}

Cube <- function(x) return(x^3)
test(Cube) <- function() {
	checkEquals(Cube(3), 27)
	checkEquals(Cube(1:3), c(1, 8, 28))
	checkException(Cube("xx"))
}

# A separate test case object
test.R <- svTest(function() {
	checkTrue(1 < 2, "check1")
	v <- 1:3
	w <- 1:3
	checkEquals(v, w)
})

# A function without test cases
foo <- function(x) return(x)

# Look now what tests are available
svUnitList()

# Only objects, no package units
svUnitList(packages = FALSE)

\dontrun{
# Create the test unit file for the objects
unit <- makeUnit(svUnitList(), name = "AllTests")
file.show(unit, delete.file = TRUE)
}

# Filter objects using a list
svUnitList(objects = c("foo", "bar"))

# Create another svUnit object with selected test items
(myunit <- svUnit(c("package:svUnit (VirtualClass)", "test(foo)")))
is.svUnit(myunit)	# Should be!

\dontrun{
# Run all the tests
summary(runTest(svUnitList(), name = "AllTests"))
}

rm(Square, Cube, foo, test.R, myunit, unit)
}

\keyword{ utilities }

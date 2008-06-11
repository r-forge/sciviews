\name{runUnit}
\alias{runUnit}
\alias{unitClear}
\alias{unitError}
\alias{print.svUnitData}
\alias{summary.svUnitData}

\title{ Compile and run a complete test unit }
\description{
  Compile a test unit and run it silently. Increment counters for errors,
  failings, and deactivated items. Manage the errors and warnings in a
  different depending if we run in interactive mode, or not (R CMD check). In
  this last case, make sure to break checking of package in case of errors or
  failings, but not otherwise.
}

\usage{
runUnit(name, dirs, print.errors = !interactive(), warn = print.errors,
	rngKind = "Marsaglia-Multicarry", rngNormalKind = "Kinderman-Ramage")

unitClear()
unitError(errors = TRUE, failures = TRUE, deactivated = TRUE, stopit = TRUE)

\method{print}{svUnitData}(x, \dots)
\method{summary}{svUnitData}(object, \dots)
}

\arguments{
  \item{name}{ The name of the test suite to build and run }
  \item{dirs}{ The directories where to look for \code{runit*.R} test files.
    These test files must be sourceable and must contain one or more
	\code{test.*()} functions implementing the different tests }
  \item{print.errors}{ Do we print explicit messages for each error of failing? }
  \item{warn}{ Do we issue a warning if there are deactivated items? }
  \item{rngKind}{ Name of a valid RNG version (see \code{RNGkind}) }
  \item{rngNormalKind}{	Name of a valid rnorm RNG version (see \code{RNGkind}) }
  \item{errors}{ If \code{TRUE}, check if there where errors in any test of all
    test suites run since last \code{unitClear()} }
  \item{failures}{ If \code{TRUE}, check if there where failures in any test of
    all test suites run since last \code{unitClear()} }
  \item{deactivated}{ If \code{TRUE}, check if there where deactivated tests in
    any test suites run since last \code{unitClear()} }
  \item{stopit}{ Do we stop execution of the code in case of any detected error
    or failure? }
  \item{x}{ A 'svUnitData' object to print }
  \item{object}{ A 'svUnitData' object to summarize }
  \item{\dots}{ Not used for\code{summary()} }
}

\value{
  \code{unitRun()} returns an object of class 'svUnitData', similar to
  'RUnitTestData' in the RUnit package with all results from the tests run.

  \code{unitClear()} returns a list with the number of errors (nErr) and the
  number of deactivated tests (nDeactivated) and the number of failures (nFail)
  invisibly. The function is called for its side effect of clearing these counters.

  \code{unitError()} returns \code{TRUE} if there are any errors and/or failures
  recorded in the global counters. This function is useful for integrating your
  test units with the "R CMD check" mechanism of checking R packages (see the
  manual "Writing R extensions"). Just create an example that run all the test
  suites you want to integrate, and then, finish your example with
  \code{unitError()}. See \code{?unitTests.svUnit} for an example.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{svTest}}, \code{\link{svUnit}},
	\code{\link[RUnit]{defineTestSuite}} }

\examples{
### TODO...
}

\keyword{ utilities }

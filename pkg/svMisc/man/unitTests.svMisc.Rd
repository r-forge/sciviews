\name{unitTests.svMisc}
\alias{unitTests.svUnit}

\title{ Unit tests for the package svMisc }
\description{
  Performs unit tests defined in this package by running
  \code{example(unitTests.svMisc)}. Tests are in \code{runit*.R} files located
  in the '/unitTests' subdirectory or one of its subdirectories ('/inst/unitTests'
  and subdirectories in package sources).
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\examples{
if (require(svUnit)) {
    clearLog()
    runTest(svSuite("package:svMisc"), "svMisc")
    errorLog()
}
}

\keyword{utilities}

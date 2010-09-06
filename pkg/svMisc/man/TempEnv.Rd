\name{TempEnv}
\alias{TempEnv}

\title{ Get an environment dedicated to temporary variables (and create it if
  needed) }
\description{
  This function creates and returns the reference to a TempEnv environment
  located just before \code{Autoloads} on the search path.
}

\usage{
TempEnv()
}

\value{
  TempEnv (an environment object)
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{\code{\link{assignTemp}}, \code{\link{changeTemp}}, \code{\link{getTemp}},
  \code{\link{rmTemp}}, \code{\link{existsTemp}}, \code{\link{addTemp}} }

\examples{
TempEnv()
}

\keyword{ utilities }

\concept{ temporary variables }

\name{assignTemp}
\alias{assignTemp}

\title{ Assign a temporary variable in the TempEnv environment }
\description{
  The function assigns a variable to TempEnv, an environment dedicated to
  temporary variables (especially useful for GUIs).
}

\usage{
assignTemp(x, value, replace.existing = TRUE)
}

\arguments{
  \item{x}{ The name of the variable }
  \item{value}{ The value of the variable }
  \item{replace.existing}{ Do we replace an existing variable? }
}


\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{TempEnv}}, \code{\link{changeTemp}}, \code{\link{getTemp}},
          \code{\link{rmTemp}}, \code{\link{existsTemp}}, \code{\link{addTemp}},
	  \code{\link{tempvar}}}

\examples{
assignTemp("test", 1:10)
# Retrieve this variable
getTemp("test")
}

\keyword{ utilities }

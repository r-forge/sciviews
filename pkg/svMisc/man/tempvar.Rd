\name{tempvar}
\alias{tempvar}

\title{ Get an arbitrary name for a temporary variable }
\description{
  The function ensures that the variable name is cryptic enough and is not
  already used.
}

\usage{
tempvar(pattern = ".var")
}

\arguments{
  \item{pattern}{ the prefix for the variable (the rest is a random number). }
}

\value{
  A string with the name of a variable.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{systemDir}}, \code{\link{systemFile}} }

\examples{
tempvar()
}

\keyword{ utilities }

\concept{ temporary variables }

\name{existsTemp}
\alias{existsTemp}

\title{ Determine if a variable exists in TempEnv }
\description{
  Does a variable exist in the TempEnv environment?
}
\usage{
existsTemp(x, mode = "any")
}

\arguments{
  \item{x}{ the name of the variable (character string). }
  \item{mode}{ the mode of the seeked variable. }
}

\value{
  \code{TRUE} if the variable exists in TempEnv (and is of the correct mode),
  \code{FALSE} otherwise.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{\code{\link{TempEnv}}, \code{\link{assignTemp}}, \code{\link{changeTemp}},
  \code{\link{getTemp}}, \code{\link{rmTemp}}, \code{\link{addTemp}} }

\examples{
assignTemp("test", 1:10)
## Check if this variable exists
existsTemp("test")
## Remove it
rmTemp("test")
## Does it still exist?
existsTemp("test")
}

\keyword{ utilities }

\concept{ temporary variables }

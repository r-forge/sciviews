\name{compareRVersion}
\alias{compareRVersion}

\title{ Compare current R version with a specified one }
\description{
  Determine if R is older (return -1), or not (return 0 if equal, or 1 if newer)
  than a given version number.
}
\usage{
compareRVersion(version)
}

\arguments{
  \item{version}{ a string defining the version to compare to, like '2.0.0' or
  '1.9.1'. }
}

\value{
  -1 if R is older, 0 if equal, 1 if newer. Take care: if you specify version as
  "2.11", and R is version "2.11.0", then the function will return 1 (newer)!
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link[utils]{compareVersion}}, \code{\link[base]{R.version}},
  \code{\link{isAqua}}, \code{\link{isWin}} }

\examples{
compareRVersion("2.11.0") # Note that we strongly advise to use R > 2.11.0!
}

\keyword{ utilities }

\concept{ version comparison }

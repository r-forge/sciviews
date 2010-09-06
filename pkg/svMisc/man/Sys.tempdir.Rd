\name{Sys.tempdir}
\alias{Sys.tempdir}

\title{ Get the system temporary directory }
\description{
  \code{Sys.tempdir()} retrieves the system temporary directory, which is
  usually /tmp under Unix, but could be located elsewhere, especially under
  Windows. It is simply the root directory of \code{tempdir()}.
}

\usage{
Sys.tempdir()
}

\value{
  A string with the path to the system temporary directory.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{Sys.userdir}} }

\examples{
Sys.tempdir()
}

\keyword{ utilities }

\concept{ system directories }

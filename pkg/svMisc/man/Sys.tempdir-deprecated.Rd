\name{Sys.tempdir}
\alias{Sys.tempdir}

\title{ Get the system temporary directory }
\description{
  This function is deprecated in favor of \code{systemDir("sysTemp")}!
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

\seealso{ \code{\link{systemDir}} }

\keyword{ utilities }

\name{isAqua}
\alias{isAqua}

\title{ Is R running with the AQUA GUI (R.app or R64.app)? }
\description{
  Determine if the R UI is AQUA, the standard R GUI under Macintosh.
  This function can also be used under other platforms, but it will always
  return \code{FALSE}.
}

\usage{
isAqua()
}

\value{
  \code{TRUE} if the R UI is AQUA, \code{FALSE} otherwise.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{isMac}}, \code{\link{isRgui}}, \code{\link{isJGR}} }

\examples{
isAqua()
}

\keyword{ utilities }

\concept{ OS system platform }

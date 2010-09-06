\name{isSDI}
\alias{isSDI}

\title{ Is Rgui started in SDI mode under Windows? }
\description{
  Determine if R is running in Rgui under Windows and is in SDI mode.
}

\usage{
isSDI()
}

\value{
  \code{TRUE} if it is Rgui under Windows, and it is stared in SDI mode
  (Single-Document Interface), \code{FALSE} otherwise (either in Rgui in
  MDI mode, or another UI). 
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org>  & Eric Lecoutre }

\note{ See the menu entry 'Edit' -> 'GUI preferences' to change the Rgui mode,
  or start Rgui with the '--SDI' argument line parameter. Under another platform
  than Windows or if it is not Rgui, then \code{isSDI()} always returns
  \code{FALSE} }

\seealso{ \code{\link{isRgui}}, \code{\link{isWin}} }

\examples{
isSDI()
}

\keyword{ utilities }

\concept{ OS system platform }

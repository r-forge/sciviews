\name{isRgui}
\alias{isRgui}

\title{ Is Rgui.exe (under Windows) running? }
\description{
  Determine if the R UI is Rgui, the standard R program under Windows.
  This function can also be used under other platforms, but it will always
  return \code{FALSE}.
}
\usage{
isRgui()
}
\value{
  \code{TRUE} if the R UI is Rgui.exe, \code{FALSE} otherwise.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{isSDI}}, \code{\link{isWin}} }

\examples{
isRgui()
}
\keyword{ utilities }

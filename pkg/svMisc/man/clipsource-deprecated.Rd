\name{clipsource-deprecated}
\alias{clipsource}

\title{ Source code from the clipboard - deprecated }
\description{
  This function reads R code from the clipboard, and then source it. Clipboard
  is managed correctly depending on the OS (Windows, Mac OS X, or *nix)
}
\usage{
    clipsource(primary = TRUE, \dots)
}

\arguments{
  \item{primary}{ only valid on *nix: read the primary (or secondary) clipboard. }
  \item{\dots}{ further parameters passed to \code{source()}. }
}

\value{
  Same result as \code{source()}.
}

\note{
  This function is deprecated in favor of \code{sourceClipboard()}, it will
  disappear in version 1.0-0 of this package!
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{sourceClipboard}}, \code{\link[base]{source}},
  \code{\link[base]{file}} }

\keyword{ utilities }

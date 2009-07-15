\name{cleanLyxRnw}
\alias{cleanLyxRnw}

\title{ Clean up R noweb files produced by LyX with SciViews Sweave module }
\description{
  The SciViews-LyX extension defines \code{rchunk} commands to contain
  R chunks (embedded R code processed by Sweave). Unfortunately, LyX use to
  write two line feed for each line of code, introducing extra lines in the R
  chunks. Moreover, tabulations are interpreted as 8 spaces, while R code use
  to consider a tabulation as equivalent to 4 spaces. \code{cleanLyxRnw()}
  corrects these little problems, and it should not affect R noweb files
  produced by a different software.
}

\usage{
cleanLyxRnw(RnwCon, RnwCon2 = RnwCon)
}

\arguments{
  \item{RnwCon}{ A connection object or a character string corresponding to the
    path to a R noweb file to be read }
  \item{RnwCon2}{ Idem, but where the cleaned up R noweb file should be written
    (by default, on the same file or connection) }
}

\value{
  \code{NULL}, this function is invoked for its side effect.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\keyword{ utilities }

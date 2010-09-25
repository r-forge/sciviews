\name{Source}
\alias{Source}

\title{ Source R code, capture its output and convert it in a different format }

\description{
  This function is deprecated in favor of \code{sourceFormat()} and will
  disappear in the future version 1.0 of this package !
  \code{Source()} is like \code{source()}, but it allows to rework the output
  (for instance to print it in HTML format).
}

\usage{
Source(\dots)
}

\arguments{
  \item{\dots}{ Same arguments as for the \code{sourceFormat()} function. }
}

\details{
  This function is usually called by functions that processes commands send by
  GUI clients.
}

\value{
  The formatted output is returned invisibly.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org}), after code written
  by Tom Short}

\seealso{ \code{\link{sourceFormat}}, \code{\link[base]{source}} }

\keyword{ utilities }

\concept{ Source R code and format it }

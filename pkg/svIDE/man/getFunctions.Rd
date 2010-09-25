\name{getFunctions}
\alias{getFunctions}

\title{ Get all functions in a given environment }
\description{
  Get a list of all visible functions in a given environment.
}

\usage{
getFunctions(pos)
}

\arguments{
  \item{pos}{ the position in the search path. }
}

\value{
  A list of character strings with functions names.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{getKeywords}}, \code{\link{createSyntaxFile}} }

\examples{
getFunctions(1)  # Functions defined in .GlobalEnv
length(getFunctions(length(search())))  # Number of functions in package:base
}

\keyword{ utilities }

\concept{ R code highlighting list functions }

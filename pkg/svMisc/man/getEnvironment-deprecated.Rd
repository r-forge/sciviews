\name{getEnvironment}
\alias{getEnvironment}

\title{ Get an environment, knowing its position }
\description{
  Given a position in the search path, the corresponding environment is returned.
}
\usage{
getEnvironment(pos)
}

\arguments{
  \item{pos}{ The position in the search path. If \code{pos = -1}, then the parent
    environment is returned.}
}
\value{
  An environment.
}

\note{
  This function appears useless since there is the as.environment(pos) function
  in base that does the same. This function will disappear in version 1.0 of the
  svMisc package.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\examples{
\dontrun{
getEnvironment(1)
getEnvironment(length(search())) # base environment
}
}

\keyword{ utilities }
\keyword{ environment }

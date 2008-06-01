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
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\examples{
getEnvironment(1)
getEnvironment(length(search())) # base environment
}

\keyword{ utilities }
\keyword{ environment }

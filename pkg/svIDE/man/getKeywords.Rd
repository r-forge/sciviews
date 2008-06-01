\name{getKeywords}
\alias{getKeywords}

\title{ get all keywords for syntax highlighting }
\description{
  Get all visible keywords in one or several environment, excluding operators
  and reserved keywords.
}
\usage{
getKeywords(pos = 2:length(search()))
}

\arguments{
  \item{pos}{ A vector of integers with all positions in the search path where
    to look at }
}
\value{
  A vector of character strings with keywords.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }
\note{ This function is used by \code{createSyntaxFile()} to list all keyword2
  items (thus excluding reserved keywords and operators) }

\seealso{ \code{\link{getFunctions}}, \code{\link{createSyntaxFile}} }
\examples{
	getKeywords(1:2)
}
\keyword{ utilities }

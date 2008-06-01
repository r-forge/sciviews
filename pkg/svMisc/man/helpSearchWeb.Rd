\name{helpSearchWeb}
\alias{helpSearchWeb}

\title{ Search web documents about R and R functions }
\description{
  Retrieve web documents, messages in R mailing lists, or wiki containing
  \code{apropos} string.
}
\usage{
helpSearchWeb(apropos, type = c("google", "archive", "wiki"), browse = TRUE)
}

\arguments{
  \item{apropos}{ The string to search }
  \item{type}{ The search engine, or location to use }
  \item{browse}{ Do we actually show the page in the Web browser? }
}

\value{
  Returns the URL used invisibly (invoked for its side effect of opening the web
  browser with the search result, when \code{browse = TRUE})
}
\author{ David Forrest <drf@vims.edu> & Philippe Grosjean <phgrosjean@sciviews.org>
after Barry Rowland's original code }

\note{
    The \code{RSiteSearch} function in the 'utils' package is much more complete
    but it does not search specific places, like the R Wiki. So, this function
    is a complement.
}

\seealso{ \code{\link[utils]{RSiteSearch}}, \code{\link[utils]{help.search}} }

\examples{
\dontrun{
helpSearchWeb("volatility")                    # Google search, by default
helpSearchWeb("volatility", type = "archive")  # In the mailing list archive
helpSearchWeb("median mean", type = "wiki")    # In the R Wiki
}
}

\keyword{ utilities }

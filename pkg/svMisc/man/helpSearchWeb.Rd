\name{helpSearchWeb}
\alias{helpSearchWeb}

\title{ Search web documents about R and R functions }
\description{
  Retrieve web documents, messages in R mailing lists, or wiki containing
  \code{apropos} string.
}
\usage{
helpSearchWeb(what, type = c("R", "archive", "wiki", "google"), browse = TRUE,
    msg = browse, \dots)
}

\arguments{
  \item{what}{ the string(s) to search. In case of several strings, or several
    words, any of these words are searched. }
  \item{type}{ the search engine, or location to use. }
  \item{browse}{ do we actually show the page in the Web browser? If
    \code{type = "R"}, this argument is ignored and the result is always
    displayed in the Web browser. }
  \item{msg}{ do we issue a message indicating that a page should be displayed
    shortly in the Web browser? If \code{type = "R"}, this argument is ignored
    and a message is always displayed. }
  \item{\dots}{ further arguments to format the result page in case of
    \code{type = "R"}. These are the same arguments as for
    \code{RSiteSearch()}. }
}

\value{
  Returns the URL used invisibly (invoked for its side effect of opening the Web
  browser with the search result, when \code{browse = TRUE}).
}

\author{ David Forrest <drf@vims.edu> & Philippe Grosjean <phgrosjean@sciviews.org>
  after Barry Rowland's original code }

\note{
  The \code{RSiteSearch()} function in the 'utils' package is used when
  \code{type = "R"}.
}

\seealso{ \code{\link[utils]{RSiteSearch}}, \code{\link[utils]{help.search}} }

\examples{
\dontrun{
helpSearchWeb("volatility")                    # R site search, by default
helpSearchWeb("volatility", type = "google")   # Google search
helpSearchWeb("volatility", type = "archive")  # In the mailing list archive
helpSearchWeb("median mean", type = "wiki")    # In the R Wiki
}
}

\keyword{ utilities }

\concept{ Search help engine archive, google or wiki }

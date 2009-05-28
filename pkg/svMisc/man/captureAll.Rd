\name{captureAll}
\alias{captureAll}

\title{ Run an R expression and capture output and messages in a similar way
  as it would be done at the command line }

\description{
  This function captures results of evaluating an R expression the same way as
  it would be done in a R console. The result is in a character string. Errors,
  warnings and other conditions are treated as usual, including the delayed
  display of the warnings if \code{options(warn = 0)}.
}

\usage{
captureAll(expr)
}

\arguments{
  \item{expr}{ A valid R expression to evaluate }
}

\value{
  Returns a string with the result of the evaluation done in the user workspace.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{Parse}}, \code{\link{clipsource}} }

\examples{
writeLines(captureAll(1+1))
writeLines(captureAll(Parse("search()")))

\dontrun{
writeLines(captureAll(Parse('1:2 + 1:3')))
writeLines(captureAll(Parse("badname")))
}
}

\keyword{ IO }

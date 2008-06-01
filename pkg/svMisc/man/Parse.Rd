\name{Parse}
\alias{Parse}

\title{ Parse a character string as if it was a command entered at the command
  line }

\description{
  Parse R instructions provided as a string and return the expression if it
  is correct, or an object of class 'try-error' if it is an incorrect code, or
  NA if the (last) instruction is incomplete.
}

\usage{
Parse(text)
}

\arguments{
  \item{text}{ The character string vector to parse }
}

\value{
  Returns an expression with the parsed code or \code{NA} if the last
  instruction is correct but incomplete, or an object of class'try-error' with
  the error message if the code is incorrect.
}

\note{
  On the contrary to \code{parse()}, \code{Parse()} recovers from incorrect code
  and also detects incomplete code or strings.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{captureAll}}, \code{\link{clipsource}} }

\examples{
Parse('1+1')
Parse('1+1; log(10)')
# incomplete instruction
Parse('log(')
# incomplete string
Parse('text <- "some text')
# wrong instruction
Parse('log)')
}

\keyword{ IO }

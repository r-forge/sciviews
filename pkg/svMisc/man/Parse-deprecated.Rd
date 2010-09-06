\name{Parse-deprecated}
\alias{Parse}

\title{ Parse a character string as if it was a command entered at the command
  line }

\description{
  Parse R instructions provided as a string and return the expression if it
  is correct, or an object of class 'try-error' if it is an incorrect code, or
  \code{NA} if the (last) instruction is incomplete.
}

\usage{
Parse(text)
}

\arguments{
  \item{text}{ the character string vector to parse into an R expression. }
}

\value{
  Returns an expression with the parsed code or \code{NA} if the last
  instruction is correct but incomplete, or an object of class'try-error' with
  the error message if the code is incorrect.
}

\note{
  This function is deprecated in favor of \code{parseText()}, it will
  disappear in version 1.0-0 of this package!
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{parseText}}, \code{\link{captureAll}},
  \code{\link{sourceClipboard}} }

\keyword{ IO }

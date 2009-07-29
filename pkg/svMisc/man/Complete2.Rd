\name{Complete2}
\alias{Complete2}

\title{ Get a completion list for a R code fragment }
\description{
  Returns names of objects/arguments/namespaces matching a code fragment.
}
\usage{

Complete2(code, print = FALSE, types = c("default", "scintilla"), addition =
FALSE, skip.used.args = TRUE, sep = "\n", type.sep = "?")

}
\arguments{
  \item{code}{ A partial R code to be completed. }
  \item{print}{ logical, print result and return invisibly. See details. }
  \item{types}{ a named list giving names of types. Set to \code{NA} to give only names. See details. }
  \item{addition}{ should only addition string be returned? }
  \item{skip.used.args}{ logical, in case if completion is within function arguments, should the already used named arguments be omitted? }
  \item{sep}{ The separator to use between returned items. }
  \item{type.sep}{ Character string to separate types from name. }
}

\value{
If \code{types} == \code{NA}, a character vector giving the completions,
otherwise a data frame with two columns: "completion", and "type" (factor with
levels given by \code{types} argument).\cr
Attributes:\cr
\code{attr(,"token")} - a completed token.\cr
\code{attr(,"triggerPos")} - number of already typed characters.\cr
\code{attr(,"fguess")} - name of guessed function.\cr
\code{attr(,"isFirstArg")} - is this a first argument?

}

\details{
If \code{print} == \code{TRUE}, results are returned invisibly, and printed in a form:
triggerPos[newline]completions separated by \code{sep}.\cr
If \code{types} are supplied, a completion will consist of name and type, separated by \code{type.sep}.
\code{types} may me a vector of length 5, giving the type codes for "function", "variable", "environment", "argument" and "keyword". If \code{types == "default"}, above type names are given, \code{types == "scintilla"} will give numeric codes that can be used "with scintilla.autoCShow" function.

}


\author{ Kamil Barton }

\seealso{ \code{\link{Complete}}, \code{\link[utils]{rc.settings()}} }
\examples{

## TODO

}
\keyword{ utilities }

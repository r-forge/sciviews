\name{argsTip}
\alias{argsTip}
\alias{callTip}

\title{ Show function arguments in a human-readable way - get a call tip }
\description{
  \code{argsTip()} displays function arguments in a better way than \code{args()}
  does. It is primarily intended for code tips in GUIs.
}

\usage{
argsTip(name, only.args = FALSE, width = getOption("width"))
callTip(code, only.args = FALSE, location = FALSE, description = FALSE,
    methods = FALSE, width = getOption("width"))
}

\arguments{
  \item{name}{ a string with the name of a function. }
  \item{code}{ a fraction of R code ending with the name of a function,
    eventually followed by '('. }
  \item{only.args}{ do we return only arguments of the function
    (\code{arg1, arg2 = TRUE, ...}), or the full call, like
    (\code{myfun(arg1, arg2 = TRUE, ...)}). }
  \item{width}{ reformat the tip to fit that width, except if
    \code{width = NULL}. }
  \item{location}{ if \code{TRUE} then the location (in which package the
    function resides) is appended to the calltip between square brackets. }
  \item{description}{ if \code{TRUE} then a short description of the function is
    added to the callTip (in fact, the title of the corresponding help page, if
    it exists). }
  \item{methods}{ if \code{TRUE} then a short message indicating if this is a
    generic function and that lists, in this case, available methods. }
}

\value{
  A string with the calling syntax of the function, plus additional information,
  depending on the flag used. Note that \code{methods} can considerably slow
  down the execution, especially for generic functions that have many methods
  like \code{print()}, or \code{summary}!
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\note{ \code{argsTip()} is supposed to display S3 and S4 methods, and primitives
  adequately,... but this is not implemented yet in the current version! }

\seealso{ \code{\link[base]{args}}, \code{\link[utils]{argsAnywhere}} }

\examples{
argsTip("ls")
callTip("myvar <- lm(")
}

\keyword{ utilities }

\concept{ Graphical user interface (GUI) control, calltip }

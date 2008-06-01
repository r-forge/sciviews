\name{Args}
\alias{Args}
\alias{CallTip}

\title{ Show function arguments in a human-readable way - get a call tip }
\description{
  \code{Args()} displays function arguments in a better way than \code{args()}
  does. It is primarily intended for code tips in GUIs.
}

\usage{
Args(name, only.args = FALSE)
CallTip(code, only.args = FALSE, location = FALSE)
}

\arguments{
  \item{name}{ A string with the name of a function }
  \item{code}{ A fraction of R code ending with the name of a function,
    eventually followed by '(' }
  \item{only.args}{ Do we return only arguments of the function
    (\code{arg1, arg2 = TRUE, ...}),
  or the full call, like (\code{myfun(arg1, arg2 = TRUE, ...)}). }
  \item{location} { If \code{TRUE} then the location (in which package the
    function resides) is appended to the calltip between square brackets }
}

\value{
  A string with the calling syntax of the function
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }
\note{ \code{Args()} is supposed to display S3/S4 methods, and primitives
  adequately,... but this is not implemented yet in the current version! }

\examples{
	Args("ls")
	CallTip("myvar <- lm(")
}
\keyword{ utilities }

\name{CompletePlus}
\alias{CompletePlus}
\title{ Get completion and additional information from an R code fragment }
\description{
  The function generates completion possibilities and investigate
  within the R help file to gather information about each completion.
}
\usage{
CompletePlus(linebuffer, cursorPosition = nchar(linebuffer), minlength = 2,
simplify = FALSE, types = c("arguments", "functions", "packages"))
}

\arguments{
  \item{linebuffer}{ R code fragment }
  \item{cursorPosition}{ Position of the cursor in the fragment }
  \item{minlength}{ Minimum size the fragment needs to be to perform the
    completion }
  \item{simplify}{ Logical. If TRUE, then the result is printed in strings with
    tabulation as field separators. }
  \item{types}{ Which types of items should we be looking for? }
}

\details{
  The information given back depends on the kind of completion performed. If a
  potential completion ends with the equal sign, then \code{CompletePlus} tries
  to get information on the argument from the guessed function. If the potential
  completion ends with \code{::}, then the \code{CompletePlus} gets information
  about the package. If the potential completion is a function, then
  \code{CompletePlus} retrieves the title of the function as documented in
  the man page, if the function is documented.
}

\value{
  Either a matrix giving completion information. If simplify is set to TRUE,
  nothing is returned but the result is \code{cat} directly to the console.
}

\author{ Romain Francois <rfrancois@mango-solutions.com> }

\seealso{ \code{\link{Complete}}, \code{\link{descFun}} }

\examples{
CompletePlus("dn")
CompletePlus("rnorm(10, me")
}
\keyword{ utilities }

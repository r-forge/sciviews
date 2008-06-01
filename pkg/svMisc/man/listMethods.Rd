\name{listMethods}
\alias{listMethods}

\title{ List all methods associated with a generic function or a class }
\description{
  List all S3 and/or S4 methods for a generic function or for a class.
}
\usage{
listMethods(f = character(), class = NULL, S3 = TRUE, S4 = TRUE,
	mixed = TRUE, filter = getOption("svGUI.methods"))
}

\arguments{
  \item{f}{ The name of the generic function (character string), used only
    when \code{class = NULL} }
  \item{class}{ The name of a class }
  \item{S3}{ If TRUE, list of S3 methods }
  \item{S4}{ If TRUE, list of S4 methods }
  \item{mixed}{ If TRUE, S3 and S4 methods are mixed together in a character
    vector, otherwise, S3 and S4 methods are reported separately in a list }
  \item{filter}{ A list of methods to consider when listing class methods.
    Only classes in this list that are defined for the class are returned.
    Store the list of methods you want in the options \"svGUI.methods\". The
    package proposes a reasonable starting point on loading if this option
    is not defined yet. }
}
\value{
  If \code{mixed = TRUE}, a list with components:
  \item{S3}{The S3 methods for the generic function or the class,
    or \code{character(0)} if none}
  \item{S4}{The S4 methods for the generic function or the class,
    or \code{character(0)} if none}
  Otherwise, a character vector with the requested methods
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{listTypes}}, \code{\link{addItems}} }

\examples{
## Generic functions
listMethods("t.test")               # S3
listMethods("show", mixed = FALSE)	# S4
listMethods("ls") # None, not a generic function!

## Classes
# Only the following methods are considered
getOption("gui.methods")
listMethods(class = "data.frame")
listMethods(class = "lm")

}
\keyword{ utilities }

\name{def}
\alias{def}

\title{ Define a vector of a given mode and length (possibly filling it with default values) }
\description{
  This function makes sure that a vector of a given mode and length is returned.
  If the value provided is NULL, NA, or empty, a default value is used instead.
  If \code{length = NULL}, the length of the vector is not constrained, otherwise,
  it is fixed (possibly cutting or recycling \code{value}).
}
\usage{
    def(value, default = "", mode = "character", length = NULL)
}

\arguments{
  \item{value}{ the value to pass with default }
  \item{default}{ the default value to use, in case of NULL, NA, or length == 0 }
  \item{mode}{ the mode of the result: character, logical, numeric, complex or
    factor. Other modes are NOT coerced! }
  \item{length}{ the desired length of the returned vector; use \code{length = NULL}
    (default) if you don't want to change the length of the vector, i.e., keep same
    length as \code{value}.}
}

\value{
  A vector of given mode and length, with either \code{value} or \code{default}.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{getTemp}}, \code{\link{assignTemp}} }

\examples{
def(1:3, length = 5)	                  # Convert into character and recycle
def(0:2, mode = "logical")                # Numbers to logical
def(c("TRUE", "FALSE"), mode = "logical") # Text to logical
def(NULL, "default text")                 # Default value used
def(character(0), "default text")         # Idem
def(NA, 10, mode = "numeric", length = 2) # Vector of two numbers
}

\keyword{ utilities }

\name{def}
\alias{def}

\title{ Define a vector of a given mode and length (possibly filling it with
  default values) }
\description{
  This function makes sure that a vector of a given mode and length is returned.
  If the value provided is \code{NULL}, or empty, the default value is used
  instead. If \code{length.out = NULL}, the length of the vector is not
  constrained, otherwise, it is fixed (possibly cutting or recycling
  \code{value}).
}
\usage{
def(value, default = "", mode = "character", length.out = NULL)
}

\arguments{
  \item{value}{ the value to pass with default. }
  \item{default}{ the default value to use, in case of \code{NULL}, or
    \code{length(value) == 0}. }
  \item{mode}{ the mode of the resulting object: 'character', 'logical',
    'numeric' (and, if you want to be more precise: 'double', 'integer' or
    'single') or 'complex'. Although not being a mode by itself, you can also
    specify 'factor' to make sure the result is a factor (thus, of mode
    'numeric', storage mode 'integer', with a levels attribute). Other modes are
    ignored, and \code{value} is NOT coerced (silently) in this case, i.e., if
    you don't want to force coercion of the resulting object, use anything
    else. }
  \item{length.out}{ the desired length of the returned vector; use
    \code{length.out = NULL} (default) if you don't want to change the length of
    the vector.}
}

\value{
  A vector of given mode and length, with either \code{value} or \code{default}.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link[base]{mode}}, \code{\link[base]{rep}}
  \code{\link{getTemp}}, \code{\link{assignTemp}} }

\examples{
def(1:3, length.out = 5)	                  # Convert into character and recycle
def(0:2, mode = "logical")                    # Numbers to logical
def(c("TRUE", "FALSE"), mode = "logical")     # Text to logical
def(NULL, "default text")                     # Default value used
def(character(0), "default text")             # Idem
def(NA, 10, mode = "numeric", length.out = 2) # Vector of two numbers
}

\keyword{ utilities }

\concept{ coercion and default values }

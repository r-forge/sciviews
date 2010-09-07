\name{listTypes}
\alias{listTypes}

\title{ List all types for a method }
\description{
  List all types for a method; types are variants for a given method
  defined in a way it is easy to add other variants dynamically (on the contrary
  to a usual \code{type =} or \code{which =} argument, like in \code{plot.ts()}
  or \code{plot.lm()}, respectively.
}
\usage{
listTypes(method, class = "default", strict = FALSE)
}

\arguments{
  \item{method}{ the method name. }
  \item{class}{ the class name. }
  \item{strict}{ do we list only types for the class (\code{TRUE}), or all
    possible types, including for inherited objects, and default ones
    (\code{FALSE}, by default)? }
}
\value{
  A vector with character strings with methods' type names.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\note{ This function is only useful for special generic functions with type
argument like \code{view}, \code{copy} or \code{export}. These functions offer a
mechanism to easily add custom types, and the present function list them. For
S3 objects a type is simply a function whose name is : <method>_<type>.<class>.
So, adding new <type>s for <method> is very easy to implement. }

\seealso{ \code{\link{listMethods}} }

\examples{
listTypes("view")  # All default view types currently defined
listTypes("view", "data.frame")
listTypes("view", "data.frame", TRUE) # None, except if you defined custom views!
}

\keyword{ utilities }

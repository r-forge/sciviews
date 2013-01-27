\name{getTemp}
\alias{getTemp}

\title{ Get a temporary variable from the SciViews:TempEnv environment }
\description{
  The function gets a variable, or an item in a list variable from
  SciViews:TempEnv, an environment dedicated to temporary variables.
}
\usage{
getTemp(x, default = NULL, mode = "any", item = NULL)
}

\arguments{
  \item{x}{ the name of the variable. }
  \item{default}{ the default value to return, in case the variable or the item
    does not exist. }
  \item{mode}{ the mode of the variable or the item (if the variable exists, but
    is not of correct mode, the default value is returned). Use
    \code{mode = "any"} (default value) to retrieve the variable or item
    whatever its mode. }
  \item{item}{ if \code{NULL} (default), the whole variable content is retrieve,
    otherwise, the variable is considered as a list, and the corresponding item
    from that list is returned. In this case, \code{default} and \code{mode}
    arguments correspond to the item, not to the whole variable.}
}

\value{
  The content of the variable, of the item, or the default value if the variable
  or item is not found in SciViews:TempEnv, or of the wrong mode.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{\code{\link{TempEnv}}, \code{\link{assignTemp}}, \code{\link{changeTemp}},
  \code{\link{rmTemp}}, \code{\link{existsTemp}}, \code{\link{addTemp}} }

\examples{
assignTemp("test", 1:10)
## Retrieve this variable
getTemp("test")
## Retrieve a non existing variable (returns default value)
getTemp("nonexistant", default = "default value")
## Set and retrieve items from a list
changeTemp("test2", "item1", 1:5)
getTemp("test2", item = "item1")
## Compare to:
getTemp("test2")
## Remove temporary variables
rmTemp(c("test", "test2"))
}

\keyword{ utilities }

\concept{ temporary variables }

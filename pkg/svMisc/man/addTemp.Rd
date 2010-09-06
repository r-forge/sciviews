\name{addTemp}
\alias{addTemp}

\title{ Add data to an item in a temporary list variable }
\description{
  The function adds data to an item in a list variable located in TempEnv,
  an environment dedicated to temporary variables (especially useful for GUIs).
}

\usage{
addTemp(x, item, value, use.names = TRUE, replace = TRUE)
}

\arguments{
  \item{x}{ the name of the variable containing the list. }
  \item{item}{ the item to add data to in the list. }
  \item{value}{ the value to add in the item, it must be a named vector and
    element matching is done according to name of items. }
  \item{use.names}{ do we match items in the existing vector and the vector we
    add by means of its names or its values?}
  \item{replace}{ do we replace existing items? }
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{\code{\link{TempEnv}}, \code{\link{assignTemp}}, \code{\link{getTemp}},
  \code{\link{existsTemp}}, \code{\link{rmTemp}}, \code{\link{changeTemp}},
  \code{\link{tempvar}}}

\examples{
addTemp("tst", "item1", c(a = 1, b = 2))
## Retrieve this variable
getTemp("tst")
## Add to item1 in this list without replacement
addTemp("tst", "item1", c(a = 45, c = 3), replace = FALSE)
getTemp("tst")
## Same but with replacement of existing items
addTemp("tst", "item1", c(a = 45, c = 3), replace = TRUE)
getTemp("tst")
## Delete the whole variable
rmTemp("tst")
}

\keyword{ utilities }

\concept{ temporary variables }

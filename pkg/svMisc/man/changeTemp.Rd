\name{changeTemp}
\alias{changeTemp}

\title{ Change an item in a temporary list variable }
\description{
  The function changes an item in a list variable located in TempEnv,
  an environment dedicated to temporary variables (especially useful for GUIs).
}

\usage{
changeTemp(x, item, value, replace.existing = TRUE)
}

\arguments{
  \item{x}{ The name of the variable containing the list }
  \item{item}{ The item to change (or create) in the list }
  \item{value}{ The value to put in the list item }
  \item{replace.existing}{ Do we replace an existing item? }
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{TempEnv}}, \code{\link{assignTemp}}, \code{\link{getTemp}},
          \code{\link{existsTemp}}, \code{\link{rmTemp}}, \code{\link{addTemp}},
	  \code{\link{tempvar}}}

\examples{
changeTemp("tst", "item1", 1:10)
# Retrieve this variable
getTemp("tst")
# Create another item in the list
changeTemp("tst", "item2", TRUE)
getTemp("tst")
# Change it
changeTemp("tst", "item2", FALSE)
getTemp("tst")
# Delete it (= assign NULL to it)
changeTemp("tst", "item2", NULL)
getTemp("tst")
# Delete the whole variable
rmTemp("tst")
}

\keyword{ utilities }

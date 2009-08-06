\name{installedPackages}
\Rdversion{1.1}
\alias{installedPackages}
\title{
Installed packages
}
\description{
This is similar to installed.packages but with 
two additional columns indicating if the package is 
loaded and default
}
\usage{
installedPackages(pattern = NULL, ...)
}
\arguments{
  \item{pattern}{filter on the name or the title of the packages}
  \item{...}{arguments for \code{\link[utils]{installed.packages}}}
}
\value{
A matrix similar to the result of \code{\link[utils]{installed.packages}}
with two additional columns
}
\author{
Romain Francois <francoisromain@free.fr>
}
\seealso{
\code{\link{installed.packages}}
}
\keyword{ manip }

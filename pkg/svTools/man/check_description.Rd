\name{check_description}
\Rdversion{1.1}
\alias{check_description}
\title{checks on DESCRIPTION files}
\description{
This performs various checks on the DESCRIPTION files
}
\usage{
check_description(descfile, txt = readLines(descfile))
}
\arguments{
  \item{descfile}{the name of the file}
  \item{txt}{the content of the file}
}
\value{
A data frame with potential problems
}
\author{
Romain Francois <francoisromain@free.fr>
}
\seealso{
\code{\link{completeDescription}} to complete a DESCRIPTION file
}
\keyword{manip}

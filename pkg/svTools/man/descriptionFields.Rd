\name{descriptionFields}
\Rdversion{1.1}
\alias{descriptionFields}
\docType{data}
\title{
List of possible fields in DESCRIPTION files
}
\description{
List of possible fields in DESCRIPTION files and their meaning
}
\usage{data(descriptionFields)}
\format{
  A data frame with 19 observations on the following 3 variables.
  \describe{
    \item{\code{field}}{The name of the field as it should appear on the DESCRIPTION file}
    \item{\code{optional}}{A factor with levels \code{Mandatory} \code{Optional}}
    \item{\code{description}}{A description of each field}
  }
}
\references{
Writing R extensions
}
\examples{
data(descriptionFields)
}
\keyword{datasets}


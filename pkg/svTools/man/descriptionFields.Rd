\name{descriptionFields}
\alias{descriptionFields}
\docType{data}

\title{ List of possible fields in DESCRIPTION files }
\description{
  List of possible fields in DESCRIPTION files and their meaning.
}

\usage{data(descriptionFields)}

\format{
  A data frame with 27 entries on the following 3 variables.
  \describe{
    \item{\code{field}}{ the name of the field as it should appear on the
      DESCRIPTION file. }
    \item{\code{optional}}{ a factor with levels \code{Mandatory} and
      \code{Optional}. }
    \item{\code{description}}{ a description of each field. }
  }
}

\references{
  Writing R extensions
}

\seealso{ \code{\link{lintDescription}}, \code{\link{completeDescription}} }

\examples{
  (data(descriptionFields))
}

\keyword{datasets}

\concept{ Fields in the DESCRIPTION file }

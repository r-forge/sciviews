\name{lintDescription}
\alias{lintDescription}

\title{ Description linter }
\description{
  Check correctness of the content in a DESCRIPTION file.
}

\usage{
lintDescription(descfile, txt = readLines(descfile))
}
\arguments{
  \item{descfile}{ a DESCRIPTION file name. }
  \item{txt}{ the text containing the description; if provided, \code{descfile}
    is ignored. }
}

\value{
  A data frame that contains errors found in the DESCRIPTION file.
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{\code{\link{completeDescription}}}

\keyword{manip}

\concept{ code verification (linter) for DESCRIPTION }

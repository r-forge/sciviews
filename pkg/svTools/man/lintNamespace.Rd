\name{lintNamespace}
\alias{lintNamespace}

\title{ Namespace linter }
\description{
  Check correctness of the code in a NAMESPACE file.
}

\usage{
lintNamespace(namespace, checkPackages = TRUE)
}
\arguments{
  \item{namespace}{ a NAMESPACE file name. }
  \item{checkPackages}{ logical; if \code{TRUE}, packages that are set to be
    imported are checked if they are actually installed. }
}

\value{
  A data frame that contains errors found in the NAMESPACE file.
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{\code{\link{completeNamespace}}}

\keyword{manip}

\concept{ code verification (linter) for NAMESPACE }

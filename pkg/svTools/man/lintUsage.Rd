\name{lintUsage}
\alias{lintUsage}

\title{ Look for error in a R code file }
\description{
  Simple wrapper to the \code{checkUsage()} function of the codetools package
  that calls \code{checkUsage()} on all objects contained in a source file.
}
\usage{
lintUsage(file, encoding = getOption("encoding"))
}

\arguments{
  \item{file}{ file to check. }
  \item{encoding}{ encoding to assume for the file. }
}

\value{
  A data frame of the errors/problems in the file is returned.
}

\author{ Romain Francois <francoisromain@free.fr> }
\seealso{ \code{\link[codetools]{checkUsage}}, \code{\link{lintDescription}},
  \code{\link{lintNamespace}} }

\keyword{ manip }

\concept{ Code correction (linter) }

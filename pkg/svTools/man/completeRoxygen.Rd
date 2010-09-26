\name{completeRoxygen}
\alias{completeRoxygen}
\alias{completeRoxygenParam}

\title{ completion for R oxygen entries }
\description{
  Proposes completions for R oxygen inline documentation of R functions.
}

\usage{
completeRoxygen(line = "#'")
completeRoxygenParam(file, row, line = "#' @param ")
}

\arguments{
  \item{file}{ a file to complete. }
  \item{row}{ location of the cursor (row) in the file. }
  \item{line}{ line of code currently edited. }
}

\value{
  A list with the following items:
  \item{token}{ token that is being completed. }
  \item{completions}{ list of current completions. }
  \item{tooltip}{ further explanation about completion items (for
    \code{completeRoxygen()} only). }
}

\references{
  Roxygen. \url{http://roxygen.org/}
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{ \code{\link{generateRoxygenTemplate}} }

\examples{
completeRoxygen("#'")
completeRoxygen("#' @ex")
}

\keyword{ utilities }

\concept{ completion list for R oxygen inline code documentation }

\name{generateRoxygenTemplate}
\alias{generateRoxygenTemplate}

\title{ Roxygen template generator }
\description{
  Generate a default Roxygen template for this file.
}

\usage{
generateRoxygenTemplate(file, row, column, author = getOption("svTools.roxygen.author"),
    type = c("verbatim", "supperabbrev"))
}

\arguments{
  \item{file}{ code file in which to add a roxygen roclet. }
  \item{row}{ line in the file. }
  \item{column}{ column in the file. }
  \item{author}{ author. The default value uses the option "svTools.roxygen.author". }
  \item{type}{ type of output. \code{"verbatim"} is plain text.
    \code{"superabbrev"} is specific to jedit}
}

\value{
  A character string that contains the roxygen comments to add in the file.
}

\references{
  Roxygen. \url{http://roxygen.org/}
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{ \code{\link{completeRoxygen}} }

\keyword{ manip }

\concept{ inline documentation with oxygen }

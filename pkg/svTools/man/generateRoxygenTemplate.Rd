\name{generateRoxygenTemplate}
\Rdversion{1.1}
\alias{generateRoxygenTemplate}
\title{
Roxygen template generator
}
\description{
Roxygen template generator
}
\usage{
generateRoxygenTemplate(file, row, col, 
	author = getOption("svTools.roxygen.author"), 
	type = c("verbatim", "supperabbrev"))
}
\arguments{
  \item{file}{code file in which to add a roxygen roclet}
  \item{row}{line in the file}
  \item{col}{column in the file}
  \item{author}{author. The default value uses the option "svTools.roxygen.author" }
  \item{type}{type of output. verbatim is plain text. superabbrev is specific to jedit}
}
\value{
A character string that contains the roxygen comments to add in the file
}
\references{
	Roxygen. \url{http://roxygen.org/}
}
\author{Romain Francois <francoisromain@free.fr>
}
\keyword{manip}


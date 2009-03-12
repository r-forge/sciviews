\name{sidekick}
\Rdversion{1.1}
\alias{sidekick}
\title{
	Builds a tree structure of an R source file
}
\description{
	The \code{sidekick} function builds a tree structure of 
	an R code file by analysing output of the R parser
}
\usage{
sidekick(file, encoding = getOption("encoding"))
}
\arguments{
  \item{file}{
	  A file to \code{\link{parse}} and analyse. If \code{file}
	  is a function, it is first dumped into a file.
}
  \item{encoding}{
	  Encoding to use. Default to the encoding option (see \link{options})
}
}
\value{
A Data frame with columns:
\item{id}{}
\item{parent}{}
\item{srcref1}{}
\item{srcref2}{}
\item{srcref3}{}
\item{srcref4}{}
\item{description}{}

}
\author{
	Romain Francois <francoisromain@free.fr>
}

\seealso{
	\code{\link{parse}}
}
\examples{
	sidekick( outer )
}
\keyword{ manip }


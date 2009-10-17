\name{sidekick}
\Rdversion{1.1}
\alias{sidekick}
\alias{sidekick.character}
\alias{sidekick.default}
\alias{sidekick.function}
\title{
	Builds a tree structure of an R source file
}
\description{
	The \code{sidekick} function builds a tree structure of 
	an R code file by analysing output of the R parser
}
\usage{
sidekick( x, ... )
\S3method{sidekick}{character}(x, encoding = getOption("encoding"), delete.file = FALSE, ... )
\S3method{sidekick}{default}(x, ... )
\S3method{sidekick}{function}(x, ... ) 
}
\arguments{
  \item{x}{A file to \code{\link{parse}} and analyse. If \code{x} is a function, it is first dumped into a file.}
  \item{encoding}{Encoding to use. Default to the encoding option (see \link{options})}
  \item{delete.file}{delete file }
  \item{...}{...}
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
	\code{\link[parser]{parser}}
}
\examples{
	\dontrun{sidekick( outer )}
}
\keyword{ manip }


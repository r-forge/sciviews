\name{CompletePlusWrap}
\Rdversion{1.1}
\alias{CompletePlusWrap}
\title{
completion
}
\description{
completion 
}
\usage{
CompletePlusWrap(...)
}
\arguments{
	\item{\dots}{arguments for \code{\link[svMisc]{CompletePlus}}}
}
\value{
A list with these items
\item{data}{A matrix of potential completions. }
\item{token}{The token being completed}
\item{fun}{in case of function completion, the name of the function}
\item{tooltip}{in case of function completion, the function tooltip}
}
\author{
Romain Francois <francoisromain@free.fr>
}
\seealso{
\code{\link[svMisc]{CompletePlus}}
}
\keyword{manip}


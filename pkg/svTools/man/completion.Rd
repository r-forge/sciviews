\name{completion}
\alias{completeCode}
\alias{completeCol}
\alias{completeLty}
\alias{completePch}

\title{ Code or arguments completion }

\description{
  Provide a list of completion candidates for code or arguments like \code{col},
  \code{lty} or \code{pch}. 
}

\usage{
completeCode(\dots)
completeCol(line)
completeLty(line)
completePch(line)
}

\arguments{
  \item{\dots}{ arguments passed to \code{\link[svMisc]{completion}}. }
  \item{line}{ the line of code currently edited. }
}

\value{
  For \code{completeCode()}, a list with these items:
  \item{token}{ the token being completed. }
  \item{completions}{ a matrix of potential completions. }
  \item{fun}{ in case of function completion, the name of the function. }
  \item{tooltip}{ in case of function completion, the function tooltip. }

  For \code{completeCol()}, a list with these items:
  \item{token}{ the token being completed. }
  \item{completions}{ list of color names. }
  \item{col.rgb}{ matrix with RGB values for the corresponding colors. }

  For the other function, the returned list contains:
  \item{token}{ the token being completed. }
  \item{completions}{ list of completion items. }
}

\author{
Romain Francois <francoisromain@free.fr>
}

\seealso{\code{\link[svMisc]{completion}}}

\examples{
completeCode("browse")
completeCol("plot(x, y, col = ")
completeLty("plot(x, y, lty = ")
completePch("plot(x, y, pch = ")
}

\keyword{manip}

\concept{ code completion for editors and IDE }

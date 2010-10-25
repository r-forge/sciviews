\name{lint}
\alias{lint}

\title{ Look for error in a R code file }
\description{
  Simple wrapper to the \code{checkUsage()} function of the codetools package
  that calls \code{checkUsage()} on all objects contained in a source file.
}
\usage{
lint(file, text = NULL, filename = NULL, encoding = getOption("encoding"),
    type = c("data.frame", "flat", "rjson"), sep = "+++")
}

\arguments{
  \item{file}{ file to check. }
  \item{text}{ the R source code (as text) to lint; used only if \code{file} is
    not provided. }
  \item{filename}{ the filename to flag returned errors. }
  \item{encoding}{ encoding to assume for the file. }
  \item{type}{ the type of output to produce. }
  \item{sep}{ in case of flat output, what is the indicator to use as field
    separator ? }
}

\value{
  A data frame, text output or rjson object of the errors/problems in the file
  or the R code in 'text' is returned.
}

\author{ Romain Francois <francoisromain@free.fr> &
  Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link[codetools]{checkUsage}}, \code{\link{lintDescription}},
  \code{\link{lintNamespace}} }

\keyword{ manip }

\concept{ Code correction (linter) }

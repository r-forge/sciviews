\name{cleanLyxRnw}
\alias{cleanLyxRnw}
\alias{tangleLyxRnw}
\alias{weaveLyxRnw}
\alias{knitLyxRnw}
\alias{purlLyxRnw}

\title{ Clean up, weave or tangle Sweave files produced by LyX with the SciViews
  Sweave module }
\description{
  These functions process .Rnw files produced by LyX and the SciViews Sweave
  module (not the standard Sweave module provided with LyX <= 2.0.0!)
  The SciViews-LyX extension defines \code{rchunk} commands to contain
  R chunks (embedded R code processed by Sweave). Unfortunately, LyX use to
  write two line feed for each line of code, introducing extra lines in the R
  chunks. Moreover, tabulations are interpreted as 8 spaces, while R code use
  to consider a tabulation as equivalent to 4 spaces. \code{cleanLyxRnw()}
  corrects these little problems, and it should not affect R noweb files
  produced by a different software.
}

\usage{
cleanLyxRnw(RnwCon, RnwCon2 = RnwCon, encoding = "UTF-8")

weaveLyxRnw(file, driver = RweaveLatex(), syntax = getOption("SweaveSyntax"),
    encoding = "UTF-8", width = 80, useFancyQuotes = TRUE,
    logFile = file.path(tempdir(), ".lyxSweave.log"), \dots)
knitLyxRnw(file, encoding = "UTF-8", width = 80, useFancyQuotes = TRUE,
    logFile = file.path(tempdir(), ".lyxSweave.log"), \dots)

tangleLyxRnw(file, driver = Rtangle(), syntax = getOption("SweaveSyntax"),
    encoding = "UTF-8", width = 80, useFancyQuotes = TRUE, annotate = TRUE,
    logFile = file.path(tempdir(), ".lyxSweave.log"), \dots)
purlLyxRnw(file, encoding = "UTF-8", width = 80, useFancyQuotes = TRUE,
    logFile = file.path(tempdir(), ".lyxSweave.log"), \dots)
}

\arguments{
  \item{RnwCon}{ a connection object or a character string corresponding to the
    path to a R noweb file to be read. }
  \item{RnwCon2}{ idem, but where the cleaned up R noweb file should be written
    (by default, on the same file or connection). }
  \item{encoding}{ the encoding of the .Rnw file. It is UTF-8 by default, but
    you can change it here }
  \item{file}{ the Sweave source file }
  \item{driver}{ the actual function to do the process, see \code{?Sweave} }
  \item{syntax}{ \code{NULL} or an object of class SweaveSyntax or a character
    string with its name,  see \code{?Sweave} }
  \item{width}{ the width used for outputs, 80 characters by default }
  \item{useFancyQuotes}{ do we use fancy quotes in R outputs? }
  \item{annotate}{ is the R code extracted from the .Rnw file annotated? }
  \item{logFile}{ the file to use to log results of weaving/tangling the document }
  \item{\dots}{ further arguments passed to the driver's setup function of
    \code{Sweave()} or \code{Stangle()} }
}

\value{
  For \code{cleanLyxRnw()}, a list for Sweave options found in the document;
  \code{NULL} for the other functions: these functions are invoked for their
  side effects. The function \code{weaveLyxRnw()} uses the standard Sweave
  driver (but it uses knitr for LyX documents that use the SciViews Knitr
  module), while \code{knitLyxRnw()} does the same, but using the knitr driver.
  Similarly, \code{purlLyxRnw()} is the knitr counterpart of
  \code{tangleLyxRnw()} standard tangling function.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\keyword{ utilities }

\concept{ Litterate programming, weaving, tangling from LyX using Sweave }

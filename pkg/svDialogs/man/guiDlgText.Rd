\name{guiDlgText}
\alias{guiDlgText}

\title{ A simple text display/editor window }
\description{
  Display or edit the content of ASCII files.
}

\usage{
guiDlgText(text, file = NULL, title = deparse(substitute(text)), edit = TRUE,
    submit = TRUE, parent = -1, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{text}{ the text to display. }
  \item{file}{ the name of a file, if the text is contained in a file. }
  \item{title}{ the title of the window. }
  \item{edit}{ do we allow to edit this text? }
  \item{submit}{ if this text is R code, allow to submit it to R. }
  \item{parent}{ which window is the parent of this text window? }
  \item{GUI}{ which GUI toolkit to use to display this window? }
}

\value{
  The modified text, or the path to the file containing the modified text.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgGrid}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

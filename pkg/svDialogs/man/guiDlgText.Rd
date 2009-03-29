\name{guiDlgText}
\alias{guiDlgText}

\title{ A simple text display/editor window }
\description{
  Display or edit the content of ASCII files
}
\usage{
guiDlgText(text, file = NULL, title = deparse(substitute(text)), edit = TRUE,
    submit = TRUE, parent = -1, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{text}{ The text to display }
  \item{file}{ The name of a file, if the text is contained in a file }
  \item{title}{ The title of the window }
  \item{edit}{ Do we allow to edit this text? }
  \item{submit}{ If this text is R code, allow to sublit it to R }
  \item{parent}{ Which window is the parent of this text window }
  \item{GUI}{ Which GUI toolkit to use to display this window? }
}

\value{
  The modified text, or the path to the file containing the modified text.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgGrid}} }

\examples{
#### TO DO...
}

\keyword{ misc }

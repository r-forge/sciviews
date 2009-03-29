\name{guiDlgView}
\alias{guiDlgView}

\title{ A view window }
\description{
  Display a view window. A view is an HTML presentation of an R object).
}
\usage{
guiDlgView(file, CSSfile, title = "View", report = TRUE, parent = -1,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{file}{ The path of the file that contains the view }
  \item{CSSfile}{ The CSS file (Cascaded Style Sheet) to use }
  \item{title}{ The title of the view window }
  \item{report}{ Do we allow to report this view? }
  \item{parent}{ Which window is the paren t of this view window }
  \item{GUI}{ Which GUI toolkit to use for this view window }
}

\value{
  Nothing
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgText}} }

\examples{
#### TO DO...
}

\keyword{ misc }

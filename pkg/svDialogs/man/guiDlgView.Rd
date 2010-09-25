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
  \item{file}{ the path of the file that contains the view. }
  \item{CSSfile}{ the CSS file (Cascaded Style Sheet) to use. }
  \item{title}{ the title of the view window. }
  \item{report}{ do we allow to report this view? }
  \item{parent}{ which window is the paren t of this view window? }
  \item{GUI}{ which GUI toolkit to use for this view window? }
}

\value{
  Returns nothing.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgText}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

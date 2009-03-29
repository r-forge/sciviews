\name{guiSetStyle.tcltk}
\alias{guiSetStyle.tcltk}

\title{ Change the style of compatible tcltk dialog boxes }
\description{
  This functions switches to a different style for compatible tcltk dialog boxes
  (only flexible dialog boxes defined in this package, currently).
}
\usage{
guiSetStyle.tcltk(style = c("classic", "SciViews", "Rcmdr", "large"), ask = FALSE)
}

\arguments{
  \item{style}{ The style to use }
  \item{ask}{ Do we ask the user to choose a style (not implemented yet)? }
}

\value{
  This function is invoked for its side effect to change the default style of
  tcltk dialog boxes
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlg}} }

\examples{
##### TO DO...
}

\keyword{misc}

\name{guiPane.tcltk}
\alias{guiPane.tcltk}
\alias{guiPane.entry.tcltk}
\alias{guiPane.list.tcltk}

\title{ Construct a 'pane', that is a zone in a flexible dialog box }
\description{
  This function constructs a 'pane'. Panes are then assembled to form a flexible
  dialog box. It is normally not called directly by the user.
}

\usage{
guiPane.tcltk(dlg, item, ...)
guiPane.entry.tcltk(paneFrame, butArg, onArgEdit, varUseIt, dlg, item, ...)
guiPane.list.tcltk(paneFrame, butArg, onArgEdit, varUseIt, dlg, item, ...)
}

\arguments{
  \item{dlg}{ A flexible dialog box }
  \item{paneFrame}{ The frame where this pane should be incrusted }
  \item{butArg}{ Arguments for buttons }
  \item{onArgEdit}{ Edit it on arg? }
  \item{varUseIt}{ var uses it? }
  \item{item}{ An item in this dialog box }
  \item{\dots}{ further arguments passed to the function }
}

\value{
  Build a pane in a flexible dialog box
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlg}} }

\examples{
#### TO DO...
}

\keyword{misc}

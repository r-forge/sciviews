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
guiPane.tcltk(dlg, item, \dots)
guiPane.entry.tcltk(paneFrame, butArg, onArgEdit, varUseIt, dlg, item, \dots)
guiPane.list.tcltk(paneFrame, butArg, onArgEdit, varUseIt, dlg, item, \dots)
}

\arguments{
  \item{dlg}{ a flexible dialog box. }
  \item{paneFrame}{ the frame where this pane should be incrusted. }
  \item{butArg}{ arguments for buttons. }
  \item{onArgEdit}{ edit it on arg? }
  \item{varUseIt}{ var uses it? }
  \item{item}{ an item in this dialog box. }
  \item{\dots}{ further arguments passed to the function. }
}

\value{
  Build a pane in a flexible dialog box.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlg}} }

\examples{
### TODO...
}

\keyword{misc}

\concept{ GUI API dialog boxes }

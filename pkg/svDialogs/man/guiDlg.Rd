\name{guiDlg}
\alias{guiDlg}
\alias{display.guiDlg}

\title{ Create a flexible dialog box }
\description{
  This function creates a flexible dialog boxe, constituted by one or several 'panes'
}

\usage{
guiDlg(title = "Input", message = NULL, help = NULL, sep = NULL, width = 50,
    labelwidth = 0, panes = list(list(type = "entry", message = "Enter data:",
    default = NULL)), GUI = getOption("guiWidgets"))

\method{display}{guiDlg}(x, parent = 0, GUI = getOption("guiWidgets"),
    debug = FALSE, \dots)
}

\arguments{
  \item{title}{ the title of the dialog box. }
  \item{message}{ the message to display on top of the dialog box. }
  \item{help}{ the help topic to trigger with the button 'help'. }
  \item{sep}{ do we use separators? }
  \item{width}{ the width of the dialog box. }
  \item{labelwidth}{ the width reserved for labels. }
  \item{panes}{ a list with the panes to add to this flexible dialog box. }
  \item{GUI}{ which GUI toolkit do we use to display this dialog box? }
  \item{x}{ a guiDlg object that accepts a display method }
  \item{parent}{ which window is the perent of this flexible dialog box? }
  \item{debug}{ do we debug this dialog box? }
  \item{\dots}{ further arguments passed to the display method. }
}

\value{
  Returns a guiDlg object that can be shown using \code{display} method.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{display}}, \code{\link{guiEval}}, \code{\link{guiPane.tcltk}} }

\examples{
### TODO...
}

\keyword{misc}

\concept{ GUI API dialog boxes }

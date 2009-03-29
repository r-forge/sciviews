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
  \item{title}{ The title of the dialog box }
  \item{message}{ The message to display on top of the dialog box }
  \item{help}{ The help topic to trigger with the button 'help' }
  \item{sep}{ Do we use separators? }
  \item{width}{ The width of the dialog box }
  \item{labelwidth}{ The width reserved for labels }
  \item{panes}{ A list with the panes to add to this flexible dialog box }
  \item{GUI}{ Which GUI toolkit do we use to display this dialog box? }
  \item{x}{ A guiDlg object that accepts a display method }
  \item{parent}{ Which window is the perent of this flexible dialog box? }
  \item{debug}{ Do we debug this dialog box? }
  \item{\dots}{ Further arguments passed to the display method }
}

\value{
  Returns a guiDlg object that can be shown using \code{display} method.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{display}}, \code{\link{guiEval}}, \code{\link{guiPane.tcltk}} }

\examples{
### TO DO...
}

\keyword{misc}

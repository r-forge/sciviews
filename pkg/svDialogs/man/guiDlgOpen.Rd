\name{guiDlgOpen}
\alias{guiDlgOpen}

\title{ An open file(s) dialog box }
\description{
  Allows to select one or more existing files to be opened.
}

\usage{
guiDlgOpen(title = "Select file", defaultFile = "", defaultDir = "",
    multi = FALSE, filters = c("All files (*.*)", "*.*"), parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{title}{ the title of the dialog box. }
  \item{defaultFile}{ the file name to display by default. }
  \item{defaultDir}{ the default dir where to open the dialog box. }
  \item{multi}{ is it allowed to select several files at once? }
  \item{filters}{ the filters to use. It is a n*2 matrix of characters, with
    first column being the label and the second being the mask. For instance:
	\"Text files\", \"*.txt\". }
  \item{parent}{ the parent of this dialog box (not implemented yet). }
  \item{GUI}{ which GUI widgets do you want to use (tcltk, ...). }
}

\value{
  A list with the path to the selected files.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgSave}}, \code{\link{guiDlgDir}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

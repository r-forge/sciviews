\name{guiDlgSave}
\alias{guiDlgSave}

\title{ a save to file dialog box }
\description{
  Use this dialog box to ask a name for saving a file
}

\usage{
guiDlgSave(title = "Save As", defaultFile = "", defaultDir = "",
    defaultExt = "", filters = c("All files (*.*)", "*.*"), parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{title}{ the title of the dialog box }
  \item{defaultFile}{the default file name }
  \item{defaultDir}{ the default directory where to open this dialog box }
  \item{defaultExt}{ the default extension for the file }
  \item{filters}{ the filters to use. It is a n*2 matrix of characters, with
      first column being the label and the second being the mask. For instance:
	  \"Text files\", \"*.txt\". }
  \item{parent}{ the parent of this dialog box (not implemented yet) }
  \item{GUI}{ which GUI widgets do you want to use (tcltk, ...) }
}

\value{
  The path to the file where to save data.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgOpen}} }

\examples{
#### TO DO...
}

\keyword{ misc }

\name{guiDlgDir}
\alias{guiDlgDir}

\title{ A select directory dialog box }
\description{
  Allows to easily select a directory.
}

\usage{
guiDlgDir(title = "Select a directory", dir = getwd(), new = TRUE,
    parent = 0, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{title}{ the title of the dialog box. }
  \item{dir}{ the default directory. }
  \item{new}{ is a new directory allowed? }
  \item{parent}{ the parent of this dialog box (not implemented yet). }
  \item{GUI}{ which GUI widgets do you want to use (tcltk, ...). }
}

\value{
  The choosen directory, or an empty string if the cancel button was clicked.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgOpen}},  \code{\link{guiDlgSave}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

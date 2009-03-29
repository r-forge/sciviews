\name{guiDlgProgress}
\alias{guiDlgProgress}

\title{ A progress window }
\description{
  Display the progression of a long task
}
\usage{
guiDlgProgress(value, range = c(0, 100), message = "Please wait...",
    title = "Progression", percent = TRUE, cancel = TRUE, icon = "none",
	parent = -1, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{value}{ The current value of the progession }
  \item{range}{ The range for the progression }
  \item{message}{ The message to display on top of the progression bar }
  \item{title}{ The title of the dialog box }
  \item{percent}{ Is it a progression in percent? }
  \item{cancel}{ Is the cancel button enabled? }
  \item{icon}{ An icon to display on the top left part of the dialog box }
  \item{parent}{ Which window is the parent of this dialog box? }
  \item{GUI}{ Which GUI toolkit to use to display this dialog box? }
}

\value{
  Nothing
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgMessage}} }

\examples{
#### TO DO...
}

\keyword{ misc }

\name{guiDlgProgress}
\alias{guiDlgProgress}

\title{ A progress window }
\description{
  Display the progression of a long task.
}
\usage{
guiDlgProgress(value, range = c(0, 100), message = "Please wait...",
    title = "Progression", percent = TRUE, cancel = TRUE, icon = "none",
    parent = -1, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{value}{ the current value of the progession. }
  \item{range}{ the range for the progression. }
  \item{message}{ the message to display on top of the progression bar. }
  \item{title}{ the title of the dialog box. }
  \item{percent}{ is it a progression in percent? }
  \item{cancel}{ is the cancel button enabled? }
  \item{icon}{ an icon to display on the top left part of the dialog box. }
  \item{parent}{ which window is the parent of this dialog box? }
  \item{GUI}{ which GUI toolkit to use to display this dialog box? }
}

\value{
  Returns nothing.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgMessage}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

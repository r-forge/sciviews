\name{guiDlgMessage}
\alias{guiDlgMessage}

\title{ Display a message box }
\description{
  A classical message box with icon, text, and one to three buttons.
}

\usage{
guiDlgMessage(message, title = "Message",
    type = c("ok", "okcancel", "yesno", "yesnocancel"),
    default = 1, icon = c("info", "question", "error", "warning"), parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{message}{ the message to display in the dialog box. }
  \item{title}{ the title of the dialog box. }
  \item{type}{ the type of dialog box: 'ok', 'okcancel', 'yesno' or
    'yesnocancel'. }
  \item{default}{ the default button (if more than one). }
  \item{icon}{ the icon: info, question, error or warning. }
  \item{parent}{ the parent of this dialog box (not implemented yet). }
  \item{GUI}{ which GUI widgets do you want to use (tcltk ...). }
}

\value{
  A string with the caption of the button that the user pressed.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgInput}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

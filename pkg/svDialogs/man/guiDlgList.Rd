\name{guiDlgList}
\alias{guiDlgList}

\title{ A list selection dialog box }
\description{
  Select an item in a list.
}

\usage{
guiDlgList(items, multi = FALSE, message = if (multi) "Select item(s):" else
    "Select one item:", title = "Selection", default = 1, nsel = NULL,
    new = FALSE, sort = FALSE, width = 50, parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{items}{ the list of items. }
  \item{multi}{ is it a multiple selection dialog box? }
  \item{message}{ the message to display on top of the list. }
  \item{title}{ the title of the dialog box. }
  \item{default}{ the default selected item. }
  \item{nsel}{ maximum number of selected items allowed. }
  \item{new}{ do we allow to create new items? }
  \item{sort}{ do we sort the list? }
  \item{width}{ the width of the dialog box. }
  \item{parent}{ which window is the parent of this dialog box? }
  \item{GUI}{ which GUI toolkit do we use for this dialog box? }
}

\value{
  A list with selected items.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgDoubleList}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

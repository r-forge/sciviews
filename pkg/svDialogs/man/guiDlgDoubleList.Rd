\name{guiDlgDoubleList}
\alias{guiDlgDoubleList}

\title{ A double list dialog box }
\description{
  Select items in two (un)related lists at once
}
\usage{
guiDlgDoubleList(list1, list2, title = "Select", default1 = "", default2 = "",
    multi = c(TRUE, TRUE), new = c(FALSE, FALSE), sort = c(TRUE, TRUE),
    transfer = FALSE, parent = 0, GUI = getOption("guiWidgets"))
}

\arguments{
  \item{list1}{ the first list items. }
  \item{list2}{ the second list items. }
  \item{title}{ a title for this dialog box. }
  \item{default1}{ selected items by default for the first list. }
  \item{default2}{ selected items by default for the second list. }
  \item{multi}{ do we allow multiple selection for first and second list. }
  \item{new}{ do we allow to create new items for first and second list. }
  \item{sort}{ do we sort first and second list. }
  \item{transfer}{ the transfer mode allows to transfer items form one list to
    the other. }
  \item{parent}{ which window is the parent of this dialog box? }
  \item{GUI}{ which GUI toolkit would we use? }
}

\value{
  A list of two lists with selected items in both lists.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgList}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

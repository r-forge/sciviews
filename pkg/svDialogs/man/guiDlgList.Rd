\name{guiDlgList}
\alias{guiDlgList}

\title{ A list selection dialog box }
\description{
  Select an item in a list
}

\usage{
guiDlgList(items, multi = FALSE, message = if (multi) "Select item(s):" else
    "Select one item:", title = "Selection", default = 1, nsel = NULL,
	new = FALSE, sort = FALSE, width = 50, parent = 0,
	GUI = getOption("guiWidgets"))
}

\arguments{
  \item{items}{ The list of items }
  \item{multi}{ Is it a multiple selection dialog box? }
  \item{message}{ The message to display on top of the list }
  \item{title}{ The title of the dialog box }
  \item{default}{ The default selected item }
  \item{nsel}{ Maximum number of selected items allowed }
  \item{new}{ Do we allow to create new items? }
  \item{sort}{ Do we sort the list? }
  \item{width}{ The width of the dialog box }
  \item{parent}{ Which window is the parent of this dialog box? }
  \item{GUI}{ Which GUI toolkit do we use for this dialog box? }
}

\value{
  A list with selected items
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgDoubleList}} }

\examples{
#### TO DO...
}

\keyword{ misc }

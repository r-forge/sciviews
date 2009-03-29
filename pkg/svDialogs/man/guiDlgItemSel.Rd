\name{guiDlgItemSel}
\alias{guiDlgItemSel}

\title{ A select item(s) dialog box }
\description{
  Select item(s) in a list or a data frame
}
\usage{
guiDlgItemSel(list, classes = NULL, title = "Select items", default = "",
    default.items = "", all.names = FALSE, multi = FALSE, sort = TRUE,
    sort.items = FALSE, subset = FALSE, save.restore = FALSE, parent = 0,
	GUI = getOption("guiWidgets"))
}

\arguments{
  \item{list}{ The list to display in the dialog box }
  \item{classes}{ Classes to use }
  \item{title}{ The title of the dialog box }
  \item{default}{ The default value }
  \item{default.items}{ The default items selected }
  \item{all.names}{ Do we use all.names? }
  \item{multi}{ Is a multiple selection allowed? }
  \item{sort}{ Do we sort the list? }
  \item{sort.items}{ Do we sort items in the list? }
  \item{subset}{ Do we allow subsetting the list? }
  \item{save.restore}{ Do we save restore information? }
  \item{parent}{ Which window is the parent of this dialog box? }
  \item{GUI}{ Which GUI toolkit do we use? }
}

\value{
  A list containing selected items
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgVarSel}} }

\examples{
#### TO DO...
}

\keyword{ misc }

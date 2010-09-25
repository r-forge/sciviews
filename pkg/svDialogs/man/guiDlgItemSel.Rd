\name{guiDlgItemSel}
\alias{guiDlgItemSel}

\title{ A select item(s) dialog box }
\description{
  Select item(s) in a list or a data frame.
}
\usage{
guiDlgItemSel(list, classes = NULL, title = "Select items", default = "",
    default.items = "", all.names = FALSE, multi = FALSE, sort = TRUE,
    sort.items = FALSE, subset = FALSE, save.restore = FALSE, parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{list}{ the list to display in the dialog box. }
  \item{classes}{ classes to use. }
  \item{title}{ the title of the dialog box. }
  \item{default}{ the default value. }
  \item{default.items}{ the default items selected. }
  \item{all.names}{ do we use all.names? }
  \item{multi}{ is a multiple selection allowed? }
  \item{sort}{ do we sort the list? }
  \item{sort.items}{ do we sort items in the list? }
  \item{subset}{ do we allow subsetting the list? }
  \item{save.restore}{ do we save restore information? }
  \item{parent}{ which window is the parent of this dialog box? }
  \item{GUI}{ which GUI toolkit do we use? }
}

\value{
  A list containing selected items.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgVarSel}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

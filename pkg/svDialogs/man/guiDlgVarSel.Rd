\name{guiDlgVarSel}
\alias{guiDlgVarSel}

\title{ A select variable dialog box }
\description{
  Present a list of variables of a given class and allow to choose one or
  several of them.
}
\usage{
guiDlgVarSel(list, classes = NULL, title = "Select a variable", default = "",
    all.names = FALSE, multi = FALSE, new = FALSE, sort = TRUE, parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{list}{ a list of variables. }
  \item{classes}{ classes for the variables to search for. }
  \item{title}{ a title of the dialog box. }
  \item{default}{ the default selected item. }
  \item{all.names}{ do we search for all names (including variables starting with '.')? }
  \item{multi}{ do we allow multiple selection? }
  \item{new}{ do we allow to create new variables? }
  \item{sort}{ do we sort the list? }
  \item{parent}{ which window is the parent of this dialog box? }
  \item{GUI}{ which GUI toolkit do we use? }
}

\value{
  A list with selected variables names.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgItemSel}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

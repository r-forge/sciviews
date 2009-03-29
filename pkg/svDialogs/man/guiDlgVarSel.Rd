\name{guiDlgVarSel}
\alias{guiDlgVarSel}

\title{ A select variable dialog box }
\description{
  Present a list of variables of a given class and allow to choose one or several
}
\usage{
guiDlgVarSel(list, classes = NULL, title = "Select a variable", default = "",
    all.names = FALSE, multi = FALSE, new = FALSE, sort = TRUE, parent = 0,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{list}{ A list of variables }
  \item{classes}{ Classes for the variables to search for }
  \item{title}{ A title of the dialog box }
  \item{default}{ The default selected item }
  \item{all.names}{ Do we search for all names (including variables starting with '.')? }
  \item{multi}{ Do we allow multiple selection? }
  \item{new}{ Do we allow to create new variables? }
  \item{sort}{ Do we sort the list? }
  \item{parent}{ Which window is the parent of this dialog box? }
  \item{GUI}{ Which GUI toolkit do we use? }
}

\value{
  A list with selected variables names
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgItemSel}} }

\examples{
#### TO DO...
}

\keyword{ misc }

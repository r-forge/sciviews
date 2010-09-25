\name{guiDlgGrid}
\alias{guiDlgGrid}

\title{ A grid (data display/editor) window }
\description{
  Display or edit matrices or data frames with this grid window.
}
\usage{
guiDlgGrid(table, title = deparse(substitute(table)), edit = TRUE,
    edit.vars = TRUE, add.vars = TRUE, add.rows = TRUE, parent = -1,
    GUI = getOption("guiWidgets"))
}

\arguments{
  \item{table}{ The table to display or edit in the grid. }
  \item{title}{ The title of the grid window. }
  \item{edit}{ can we edit its content? }
  \item{edit.vars}{ can we edit the name of its variables? }
  \item{add.vars}{ can we add new variables? }
  \item{add.rows}{ can we add rows? }
  \item{parent}{ which window is the parent of the grid window? }
  \item{GUI}{ which GUI toolkit do we use? }
}

\value{
  A modified version of the table if \code{edit == TRUE}.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlgText}} }

\examples{
### TODO...
}

\keyword{ misc }

\concept{ GUI API dialog boxes }

\name{guiRefresh}
\alias{guiRefresh}
\alias{guiAutoRefresh}

\title{ Refresh GUI (Komodo) elements, like active object lists and object browser }
\description{
  These function manage to refresh the list of active objects in Komodo and also
  the data displayed in the Komodo R object browser. They should not be called
  directly by the end-user.
}
\usage{
guiRefresh(force = FALSE)
guiAutoRefresh(\dots)
}

\arguments{
  \item{force}{ do we force refresh, even if data have not changed? }
  \item{\dots}{ any argument (ignored, but useful for \code{addTaskCallback()}). }
}

\value{
  Both functions return \code{TRUE} on success.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{koCmd}} }

\keyword{misc}

\concept{ interprocess commnunication Komodo }

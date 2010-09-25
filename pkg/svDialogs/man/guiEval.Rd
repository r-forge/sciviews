\name{guiEval}
\alias{guiEval}

\title{ Evaluate R code constructed using a flexible dialog box }
\description{
  This function is usually called by a flexible dialog box to execute R code
  that was build with it.
}

\usage{
guiEval(code, ident = "GUI ")
}

\arguments{
  \item{code}{ a string wuth some R code. }
  \item{ident}{ do we identify this execution (change the prompt)? }
}

\value{
  The result of the evaluated R code.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlg}}, \code{\link{display}} }

\examples{
### TODO...
}

\keyword{misc}

\concept{ GUI API dialog boxes }

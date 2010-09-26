\name{completeNamespace}
\alias{completeNamespace}

\title{ Namespace completion }
\description{
  Provides a completion list in the context of a NAMESPACE file.
}

\usage{
completeNamespace(line)
}

\arguments{
  \item{line}{ the line currently edited in the NAMESPACE file. }
}

\value{
  A list with the possible completion items
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{\code{\link{lintNamespace}}}

\examples{
completeNamespace("import(")
completeNamespace("importFrom(")
completeNamespace("export(")  # Not yet!
}

\keyword{manip}

\concept{ code completion for NAMESPACE }

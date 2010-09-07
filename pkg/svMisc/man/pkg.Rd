\name{pkg}
\alias{pkg}

\title{ A very silent and multipackage require() function }
\description{
  This function loads one or several R packages as silently as possible and
  it returns \code{TRUE} only if all packages are loaded successfully. If
  at least one loading fails, a short message is printed.
}
\usage{
    pkg(..., warn = TRUE)
}

\arguments{
  \item{\dots}{ the name of one or several R packages to load (character
    strings). }
  \item{warn}{ If \code{TRUE}, issue a warning if one or several packages are
    not loaded. }
}

\value{
  \code{TRUE} if all packages are loaded correctly, \code{FALSE} otherwise. This
  function is designed to concisely and quitely indicate package requirements in
  GUI menu or other GUI actions.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link[base]{require}} }

\examples{
## This should work...
if (all(pkg("tools", "methods"))) cat("Fine!\n")
## ... but this not
if (!all(pkg("tools", "badname", warn = FALSE))) cat("Not fine!\n")
}

\keyword{ utilities }

\concept{ package requirement and loading }

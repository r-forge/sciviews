\name{r}
\alias{r}

\title{ A very silent and multipackage require() function }
\description{
  This function is deprecated in favor of \code{pkg()} (more informative
  name that is less susceptible to be used elsewhere)!
  This function loads one or several R packages as silently as possible and
  it returns \code{TRUE} only if all packages are loaded successfully. If
  at least one loading fails, a short message is printed.
}
\usage{
    r(...)
}

\arguments{
  \item{\dots}{ the name of one or several R packages to load (character
    strings). }
}

\value{
  \code{TRUE} if all packages are loaded correctly, \code{FALSE} otherwise. This
  function is designed to concisely and quietly indicate package requirements in
  GUI menu or other GUI actions.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{pkg}} }

\keyword{ utilities }

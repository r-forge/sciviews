\name{pkgDesc}
\alias{pkgDesc}
\alias{pkgInstalled}
\alias{pkgLoaded}
\alias{pkgWebDesc}

\title{ Get installed or loaded packages, or their description }
\description{
  This is similar to \code{installed.packages()} but with two additional columns
  indicating if the package is loaded and default. Description of packages can
  be retrieved from the local library, or from the Web (default repository).
}

\usage{
pkgLoaded()
pkgInstalled(pattern = NULL, \dots)
pkgDesc(pkg, lib.loc = NULL, fields = NULL, encoding = "")
pkgWebDesc(pkg, repos = getOption("repos"))
}

\arguments{
  \item{pattern}{ filter on the name or the title of the packages. }
  \item{\dots}{ arguments for \code{\link[utils]{installed.packages}}. }
  \item{pkg}{ character. The name of a R package. }
  \item{lib.loc}{ the local library where the package is localted, or
    \code{NULL} (by default) to search in all known libraries. }
  \item{fields}{ which fields do we retrieve. If \code{NULL} (by default), all
    fields in the DESCRIPTION file are returned. }
  \item{encoding}{ the encoding to use, or \code{""} for default one. }
  \item{repos}{ the repository where to look for the package description. }
}

\value{
  A matrix similar to the result of \code{\link[utils]{installed.packages}}
  with two additional columns for \code{pkgInstalled()}. A character string
  for \code{pkgLoaded()}, \code{pkgDesc()} and \code{pgkWebDesc()}.
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{ \code{\link{installed.packages}} }

\examples{
pkgLoaded()
pkgInstalled()
pkgDesc("utils")
\dontrun{
pkgWebDesc("svTools")
}
}

\keyword{ manip }

\concept{ package management and description }

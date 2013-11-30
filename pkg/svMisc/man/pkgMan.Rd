\name{pkgMan}
\alias{pkgManDescribe}
\alias{pkgManDetach}
\alias{pkgManGetAvailable}
\alias{pkgManGetInstalled}
\alias{pkgManGetMirrors}
\alias{pkgManInstall}
\alias{pkgManLoad}
\alias{pkgManRemove}
\alias{pkgManSetCRANMirror}

\title{ Functions to manage R side of the SciViews R package manager }
\description{
  These functions should not be used directly by the end-user. They implement
  the R-side code for the SciViews R package manager.
}
\usage{
pkgManDescribe(pkgName, print.it = TRUE)
pkgManInstall(pkgs, install.deps = FALSE, ask = TRUE)
pkgManGetInstalled(sep = ";", eol = "\t\n")
pkgManGetAvailable(page = "next", pattern = "", n = 50,
    keep = c("Package", "Version", "InstalledVersion", "Status"),
    reload = FALSE, sep = ";", eol = "\t\n")
pkgManLoad(pkgName)
pkgManDetach(pkgName)
pkgManRemove(pkgName)
pkgManGetMirrors()
pkgManSetCRANMirror(url)
}

\arguments{
  \item{pkgName}{ the name of one R package (character string). }
  \item{print.it}{ Should the result be printed? }
  \item{pkgs}{ a list of packages to install. }
  \item{install.deps}{ do we also install dependencies? }
  \item{ask}{ do we prompt the user for package installation? }
  \item{sep}{ field separator to use. }
  \item{eol}{ end-of-line sequence to use. }
  \item{page}{ which page to get? }
  \item{pattern}{ selection pattern. }
  \item{n}{ the number of items to retrieve. }
  \item{keep}{ the columns to keep in the resulting data frame. }
  \item{reload}{ do we force reload of the data and ignore cache version? }
  \item{url}{ the URL to use for the current CRAN mirror. }
}

\value{
  These functions return data that is intended to be used by the SciViews R
  package manager.
}

\author{ Kamil Barton <kamil.barton@uni-wuerzburg.de> }

\seealso{ \code{\link{package}} }

\keyword{ utilities }

\concept{ Sciviews R package manager }

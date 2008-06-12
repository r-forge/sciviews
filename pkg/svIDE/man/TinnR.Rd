\name{TinnR}
\alias{trObjSearch}
\alias{trObjList}

\title{ Function for the Tinn-R object browser }
\description{
  These functions provide features required to implement the Tinn-R object browser.
}
\usage{
trObjSearch(path = NULL)
trObjList(id = "default", envir = .GlobalEnv, all.names = TRUE,
  pattern = "", group = "", path = NULL)
}

\arguments{
  \item{path}{ The path where to write a temporary file with the requested information }
  \item{id}{ The id of the object browser (you can run several ones concurrently) }
  \item{envir}{ An environment, its name or position in the search path }
  \item{all.names}{ Do we display all names (including hidden variables starting with '.')? }
  \item{pattern}{ A pattern to match for selecting variables }
  \item{group}{ The group to which variables belong }
}
\details{
  \code{trObjSearch} list search paths.
  \code{guiObjList} lists objects in a given environment.
  These functions are not intended to be called directly by the end-user. They
  are used internally by Tinn-R to get data for its own R objects explorer. Note
  that, for Tinn-R to be able to run these commands and to communicate with R,
  you have to load the svIDE package. You must also activate one, or both
  communcation means: sockets, by loading the svSocket package, or DDE, by
  starting the \code{guiDDEInstall()} function from the svIDE package (you can
  activate both as well). Finally, you need also functions from the svIO package.
  The best way to get R operational to communicate with Tinn-R from start is to
  add the following commands to '/etc/profile.site' in the R install directory:
  \code{library(svIDE); library(svSocket); library(svIO); guiDDEInstall()}
}
\value{
  Either nothing if \code{path} is not null (data are written in a file given
  by \code{path}), or a data frame with the results.
}

\author{Jose Claudio Faria (\email{joseclaudio.faria@terra.com.br}) &
  Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDDEInstall}}, \code{\link[svMisc]{obsSearch}},
  \code{\link[svMisc]{obsList}} }

\keyword{misc}

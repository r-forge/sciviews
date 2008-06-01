\name{objBrowse}
\alias{objBrowse}
\alias{objClear}
\alias{objDir}
\alias{objInfo}
\alias{objList}
\alias{objMenu}
\alias{objSearch}

\title{ Function to implement an object browser }
\description{
  These functions provide features required to implement a complete object
  browser in a GUI client.
}

\usage{
objBrowse(id = "default", envir = .GlobalEnv, all.names = NULL, pattern = NULL,
	group = NULL, sep = "\t", path = NULL, regenerate = FALSE)
objClear(id = "default")
objDir()
objInfo(id = "default", envir = .GlobalEnv, object = "", path = NULL)
objList(id = "default", envir = .GlobalEnv, object = "", all.names = FALSE,
    pattern = "", group = "", sep = "\t", path = NULL, compare = TRUE)
objMenu(id = "default", envir = .GlobalEnv, objects = "", sep = "\t",
	path = NULL)
objSearch(sep = "\t", path = NULL, compare = TRUE)
}

\arguments{
  \item{id}{ The id of the object browser (you can run several ones
    concurrently, providing you give them different ids) }
  \item{envir}{ An environment, or the name of the environment, or the position
    in the \code{search()} path }
  \item{all.names}{ Do we display all names (including hidden variables starting
    with '.')? }
  \item{pattern}{ A pattern to match for selecting variables }
  \item{group}{ A group to filter }
  \item{sep}{ Separator to use between items in the file (if path is not NULL) }
  \item{path}{ The path where to write a temporary file with the requested
    information. Use \code{path = NULL} (default) if you don't pass this
    data to your GUI client by mean of a file }
  \item{regenerate}{ Do we force to regenerate the information? }
  \item{object}{ The currently selected object in the object browser }
  \item{objects}{ A list with selected items in the object browser }
  \item{compare}{ If \code{compare == TRUE}, result is compared with last cached
    value and the client is updated only if something changed }
}
\details{
  \code{objBrowse} do the horsework. \code{objDir} gets the temporary directory
    where exchange files are stored, in case you exchange data through files.
    You can use a better way to communicate with your GUI (you have to provide
    your code) and disable writing to files by using \code{path = NULL}.
  \code{objList} lists objects in a given environment.
  \code{objSearch} lists the search path.
  \code{objClear} clears any reference to a given object browser.
  \code{objInfo} computes a tooltip info for a given object.
  \code{objMenu} computes a context menu for selected object(s) in the object
    explorer managed by the GUI client.
}
\value{
  Depending on the function, a list, a string, or a reference to an external,
  temporary file is returned invisibly.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{Complete}}, \code{\link{CallTip}} }

\examples{
# Create various context menus
data(iris)
(objInfo(object = "iris"))
data(trees)
# For one object
(objMenu(objects = "iris"))
# For multiple objects
(objMenu(objects = c("iris", "trees")))
# For inxistant object (return "")
(objInfo(object = "noobject"))
(objMenu(objects = "noobject"))
rm(iris, trees)

# For environments
(objInfo(envir = ".GlobalEnv"))
(objMenu(envir = ".GlobalEnv"))
(objInfo(envir = "TempEnv"))
(objMenu(envir = "TempEnv"))
(objInfo(envir = "package:datasets"))
(objMenu(envir = "package:datasets"))
# For an environment that does not exist on the search path (return "")
(objInfo(envir = "noenvir"))
(objMenu(envir = "noenvir"))
}

\keyword{misc}

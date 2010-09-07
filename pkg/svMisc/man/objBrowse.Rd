\name{objBrowse}
\alias{objBrowse}
\alias{objClear}
\alias{objDir}
\alias{objInfo}
\alias{objList}
\alias{objMenu}
\alias{objSearch}
\alias{print.objList}
\alias{write.objList}

\title{ Functions to implement an object browser }
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
objList(id = "default", envir = .GlobalEnv, object = NULL, all.names = FALSE,
    pattern = "", group = "", all.info = FALSE, sep = "\t", path = NULL,
    compare = TRUE, \dots)

objMenu(id = "default", envir = .GlobalEnv, objects = "", sep = "\t",
    path = NULL)
objSearch(sep = "\t", path = NULL, compare = TRUE)

\method{print}{objList}(x, sep = NA, eol = "\n", header = !attr(x, "all.info"),
    raw.output = !is.na(sep), \dots)

write.objList(x, path, sep = "\t", \dots)
}

\arguments{
  \item{id}{ the id of the object browser (you can run several ones
    concurrently, providing you give them different ids). }
  \item{envir}{ an environment, or the name of the environment, or the position
    in the \code{search()} path. }
  \item{all.names}{ do we display all names (including hidden variables starting
    with '.')? }
  \item{pattern}{ a pattern to match for selecting variables. }
  \item{group}{ a group to filter. }
  \item{path}{ the path where to write a temporary file with the requested
    information. Set to NULL (default) if you don't pass this data to your GUI
	client by mean of a file. }
  \item{regenerate}{ do we force to regenerate the information? }
  \item{object}{ name of the object selected in the object browser,
	components/arguments of which should be listed. }
  \item{objects}{ a list with selected items in the object browser }
  \item{all.info}{ do we return all the information (envir as first column or
    not (by default). }
  \item{compare}{ if TRUE, result is compared with last cached value and the
    client is updated only if something changed. }
  \item{sep}{ separator to use between items (if path is not NULL). }
  \item{x}{ object returned by \code{objList}. }
  \item{eol}{ separator to use between object entries, default is to list each
	item in a separate line. }
  \item{header}{ if TRUE, two-line header is printed, of the form: \cr
	Environment = environment name \cr
	Object = object name \cr
	Default is not to print header if \code{all.info} is true. }
  \item{raw.output}{ if TRUE, a compact, better suited for parsing output is
    produced. }
  \item{\dots}{ further arguments, passed to \code{write.table}. }
}

\details{
  \code{objBrowse()} does the horsework. \code{objDir()} gets the temporary
  directory where exchange files are stored, in case you exchange data through
  files. You can use a better way to communicate with your GUI (you have to
  provide your code) and disable writing to files by using \code{path = NULL}.
  
  \code{objList()} lists objects in a given environment, elements of a recursive
  object or function argument.
  
  \code{objSearch()} lists the search path.
  
  \code{objClear()} clears any reference to a given object browser.
  
  \code{objInfo()} computes a tooltip info for a given object.
  
  \code{objMenu()} computes a context menu for selected object(s) in the object
  explorer managed by the GUI client.
  
  \code{print.objList()} print method for \code{objList} objects.
}

\value{
  Depending on the function, a list, a string, a reference to an external,
  temporary file or \code{TRUE} in case of success or \code{FALSE} otherwise
  is returned invisibly.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org}) and
  Kamil Barton (\email{kbarton@zbs.bialowieza.pl})}

\seealso{ \code{\link{Complete}}, \code{\link{CallTip}} }

\examples{
## Create various context menus
data(iris)
(objInfo(object = "iris"))
data(trees)
## For one object
(objMenu(objects = "iris"))
## For multiple objects
(objMenu(objects = c("iris", "trees")))
## For inxistant object (return "")
(objInfo(object = "noobject"))
(objMenu(objects = "noobject"))
rm(iris, trees)

## For environments
(objInfo(envir = ".GlobalEnv"))
(objMenu(envir = ".GlobalEnv"))
(objInfo(envir = "TempEnv"))
(objMenu(envir = "TempEnv"))
(objInfo(envir = "package:datasets"))
(objMenu(envir = "package:datasets"))
## For an environment that does not exist on the search path (return "")
(objInfo(envir = "noenvir"))
(objMenu(envir = "noenvir"))
}

\keyword{misc}

\concept{ Graphical User Interface (GUI), object explorer }

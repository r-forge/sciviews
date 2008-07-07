\name{descFun}
\alias{descFun}
\alias{descArgs}

\title{ Get textual help on function or function arguments }
\description{
  Textual help on functions or their arguments is extracted for text online help
  for a given function. By default, all arguments from the online help are
  returned for \code{descArgs()}. If the file contains help for several function,
  one probably get also some irrelevant information. Use of 'args' to limit
  result is strongly encouraged.
}

\usage{
descFun(fun, package, lib.loc = NULL)
descArgs(fun, args = NULL, package = NULL, lib.loc = NULL)
}

\arguments{
  \item{fun}{ A character string with the name of a function (several
    functions accepted for \code{descFun()} }
  \item{args}{ Either \code{NULL} (by default) to return the description of all
    arguments from the corresponding man page, or a character vector with names
	of the arguments to search for }
  \item{package}{ A character string with the name of the package that contains
    \code{fun}, or \code{NULL} for searching in all loaded packages }
  \item{lib.loc} { A character vector of directory names of \R libraries, or
    \code{NULL}. The default value of \code{NULL} corresponds to all libraries
	currently known. If the default is used, the loaded packages are searched
	before the libraries. }
}

\value{
  A string with the description of the function or of its arguments. If the man
  page is not found, a vector of empty strings is returned. Empty strings are
  also returned for arguments that are not found in the man page.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{CompletePlus}} }

\examples{
descFun("ls", "base")
descFun("library", "base")
descArgs("ls")
descArgs("library", args = c("package", "pos"))
}
\keyword{ utilities }

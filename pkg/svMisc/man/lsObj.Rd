\name{lsObj}
\alias{lsObj}
\encoding{utf-8}


\title{ R object component browser helper functions }
\description{
  This function is not intended to be used at the command line (except for
  debugging purposes). It executes a command string to a (compatible) GUI client.
}
\usage{
lsObj (objname, envir = .GlobalEnv, sep = ",")
}

\arguments{
	\item{objname}{ name of the object as character string }
	\item{envir} {an environment, or the name of the environment, or the position in the search() path}
	\item{sep}{ a character string to separate the items. If set to NA, a data frame is returned}
}

\value{
	For each element in object \dQuote{objname} (or argument, if object was function), following values are returned: an environment, name, full name (of type i.e. \code{object$name}, \code{object$name} for S4 objects slots or\code{formals(object)$name} for function arguments), dimensions or default value (arguments), class, mode, logical - is component recursive?.\cr
	If \code{sep} is NA, a data frame is returned, otherwise a character vector with values separated with \code{sep}.
}


\author{Kamil Bartoń (\email{kbarton@zbs.bialowieza.pl})}

\seealso{ \code{\link{objList}} }

\keyword{misc}

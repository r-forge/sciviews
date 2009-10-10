\name{isHelp}
\alias{isHelp}

\title{ Is there a help file and example to run associated with an object? }
\description{
  Determine if 'topic' has a help file and example to run.
}
\usage{
isHelp(topic, package = NULL, lib.loc = NULL)
}

\arguments{
  \item{topic}{ name or literal character string: the online help topic to
    look for. }
  \item{package}{ a character vector giving the package names to look into for
    help or example code, or \code{NULL}. By default, all packages in the search
	path are used. }
  \item{lib.loc}{ a character vector of directory names of \R libraries, or
    \code{NULL}. The default value of \code{NULL} corresponds to all libraries
	currently known. If the default is used, the loaded packages are searched
	before the libraries. }
}

\value{
  A logical vector with two elements. The first one indicating if there is a
  help file, and the second one indicating if there are examples associated
  with this help file.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\note{
  This code is largely inspired from the first part of \code{example()}.
}

\examples{
isHelp("help")		# Help and example
isHelp("Rtangle")	# Help but no example
isHelp("notopic")	# No help or example
}
\keyword{ utilities }

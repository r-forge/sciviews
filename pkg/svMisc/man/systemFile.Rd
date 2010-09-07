\name{systemFile}
\alias{systemFile}
\alias{systemDir}

\title{ Get a system file or directory }
\description{
  Get system files or directories, in R subdirectories, in package
  subdirectories, or elsewhere on the disk (including executables that are
  accessible on the search path).
}

\usage{
systemFile(\dots, exec = FALSE, package = NULL, lib.loc = NULL)
systemDir(\dots, exec = FALSE, package = NULL, lib.loc = NULL)
}

\arguments{
  \item{\dots}{ one or several executables if \code{exec = TRUE}, or subpath to
    a file or dir in a package directory if \code{package != NULL}, or a list of
	path and subpaths for testing the existence of a file on disk, or a list of
	directory components to retrieve in 'temp', 'sysTemp', 'user', 'home',
	'bin', 'doc', 'etc' and/or 'share' to retrieve special system directories. }
  \item{exec}{ if \code{TRUE} (default) search for executables on the search
    path. It superseedes all other arguments. }
  \item{package}{ the name of one package to look for files or subdirs in its
    main directory (use \code{exec = FALSE} to search inside package dirs). }
  \item{lib.loc}{ a character vector with path names of \R libraries or
    \code{NULL} (search all currently known libraries in this case). }
}

\value{
  A string with the path to the directories or files, or \code{""} if they are
  not found, or of the wrong type (a dir for \code{systemFile()} or or a file
  for \code{systemDir()}).
}

\note{
  These function aggregate the features of several \R functions in package
  base: system.file(), R.home(), tempdir(), Sys.which(), and aim to provide a
  unified and convenient single interface to all of them. We make sure also to
  check that returned components are respectively directories and files for
  \code{systemDir()} and \code{systemFile()}.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link[base]{file.path}}, \code{\link[base]{file.exists}} }

\examples{
systemFile("INDEX", package = "base")
systemFile("help", "AnIndex", package = "splines")
systemFile(package = "base")  # This is a dir, not a file!
systemFile("zip", exec = TRUE)
systemFile("ftp", "ping", "zip", "nonexistingexe", exec = TRUE)
systemDir("temp")             # The R temporary directory
systemDir("sysTemp")          # The system temporary directory
systemDir("user")             # The user directory
systemDir("home", "bin", "doc", "etc", "share")  # Various R dirs
systemDir("zip", exec = TRUE) # Look for the dir of an executable
systemDir("ftp", "ping", "zip", "nonexistingexe", exec = TRUE)
systemDir(package = "base")   # The root of the 'base' package
systemDir(package = "stats")  # The root of package 'stats'
systemDir("INDEX", package = "stats") # This is a file, not a dir!
systemDir("help", package = "splines")
}

\keyword{ utilities }

\concept{ system files and directories }

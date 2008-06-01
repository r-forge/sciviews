\name{guiCmd}
\alias{guiCmd}
\alias{guiImport}
\alias{guiExport}
\alias{guiLoad}
\alias{guiReport}
\alias{guiSave}
\alias{guiSetwd}
\alias{guiSource}


\title{ Execute a command in the GUI client }
\description{
  This function is not intended to be used at the command line (except for
  debugging purposes). It executes a command string to a (compatible) GUI client.
}
\usage{
guiCmd(command, ...)
guiImport(...)
guiExport(...)
guiLoad(...)
guiReport(...)
guiSave(...)
guiSetwd(...)
guiSource(...)
}

\arguments{
  \item{command}{ The command string to execute in the GUI client }
  \item{\dots}{ Parameters provided for the command to execute in the GUI client }
}

\value{
  The result of the command if it succeed, or \code{NULL} if the command cannot
  be run (i.e., \code{.guiCmd()} is not defined in \code{TempEnv}).
}

\details{
  You must define a function \code{.guiCmd()} in the \code{TempEnv} environment
  that will take first argument as the name of the command to execute (like
  \code{source}, \code{save}, \code{import}, etc), and \dots with arguments to the
  command to send. Depending on your GUI, you should have code that delegates
  the GUI elements (ex: display a dialog asking for a .Rdata file to source)
  and then, execute the command in R with the selected file as attribute.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{assignTemp}} }

\keyword{misc}

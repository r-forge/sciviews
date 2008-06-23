\name{guiInstall}
\alias{guiInstall}
\alias{guiUninstall}

\title{ Install and uninstall hooks for communicating with the GUI client (Komodo) }
\description{
  Install functions in TempEnv and callbacks required to communicate with Komodo
  Edit with the SciViews-K extension (see http://www.sciviews.org/SciViews-K).
}
\usage{
guiInstall()
guiUninstall()
}

\value{
  Nothing.
}

\details{
  The minimum instruction to set up everything in R to communication with Komodo
  and SciViews-K extension installed is to use:
  \code{option(ko.serve = 8888); require(svGUI)}. When the \code{ko.serve}
  option is set, svGUI load svSocket, starts the socket server litening to the
  port you give in \code{ko.serve} (8888 by default), and install the hooks and
  callbacks required to fully communicate with Komodo.

  Before loading svGUI, you can also set \code{option(ko.port = 7052)} or
  another port number where the Komodo SciViews-K server is listening (7052 is
  the default value). If the Komodo client is running on a different machine,
  you should also set \code{ko.host = "xxx.xxx.xxx.xxx"}, where xxx.xxx.xxx.xxx
  is the IP address of the Komodo client's machine, before loading svGUI (note
  that running R and Komodo on separate machines is not supported yet, but this
  is a planned feature and corresponding configurations are already recognized;
  just, distant server is currently locked until we will build a better security
  mechanism in the server (SSL, TSL, ...).

  All these operations are done by Komodo if you start R from Komodo with
  SciViews-K extension installed.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{koCmd}} }

\keyword{misc}

\name{sendSocketServer}
\alias{sendSocketServer}

\title{ Send data to an existing R socket server and disconnect. }

\description{
  The text is send to one R socket server and evaluated there as a command in
  \code{.GlobalEnv}. Results (text as it should be printed on the console) is
  returned to the client and the client then disconnects automatically.
}

\usage{
sendSocketServder(text, serverhost = "localhost", serverport = 8888)
}

\arguments{
  \item{text}{ The text (command) to send and evaluate in the server. }
  \item{serverhost}{ The name or address of the host where the R socket server
    is located. }
  \item{serverport}{ The port of the R socket server. }
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{sendSocketClients}}, \code{\link{closeSocketClients}},
  \code{\link{processSocket}} }

\examples{
\dontrun{
# Start a R socket server in an instance #1 of R
# require(svSocket)
# startSocketServer()
#
# Now, start an instance #2 of R on the same machine and do:
require(svSocket)
cat(sendSocketServer("ls()"))
# You should read, at least, iris
cat(sendSocketServer("x <- 2"))
# Nothing happens, but switch to R #1 and type
# x
# to see the result
}
}

\keyword{ IO }

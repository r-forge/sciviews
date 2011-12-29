\name{koCmd}
\alias{koCmd}

\title{ Connect to the SciViews-K (Komodo Edit/IDE) socket server and run
  javascript code in Komodo }

\description{
  If Komodo Edit/IDE with the SciViews-K extension is running on your machine,
  you can connect to its socket server and run javascript code in it with this
  function.
}

\usage{
koCmd(cmd, data = NULL, async = FALSE, host = getOption("ko.host"),
    port = getOption("ko.port"), kotype = getOption("ko.kotype"), timeout = 2,
    type = c("js", "rjsonp", "output"), pad = NULL, \dots)
}

\arguments{
  \item{cmd}{ the javascript you want to execute in Komodo Edit, in a character
    string vector. }
  \item{data}{ if a named list, replace <<<name>>> in cmd for each name of the
    list by its component first. If a character string, replace <<<data>>> in
    cmd. If \code{NULL} (be default), do nothing to cmd before submitting it.
    See the last examples for using data. }
  \item{async}{ not used yet! }
  \item{host}{ the host where Komodo is located. Currently, only \code{localhost}
    is accepted. Can be changed by setting \code{options(ko.host = ....)}. }
  \item{port}{ The socket port where the SciViews-K server is listening, by
    default, it is port 7052. Can be changed by setting
    \code{options(ko.port = ....)}. }
  \item{kotype}{ the type of Komodo server in use. Currently
    (SciViews-K >= 0.9-25), it can be either \code{"socket"} or \code{"file"}. }
  \item{timeout}{ number of seconds to wait for response. }
  \item{type}{ which type of Komodo command do we send? If \code{type = "js"}
    (by default), \code{cmd} is considered to be JavaScript code to be evaluated
    in Komodo. If \code{type = "rjsonp"}, \code{cmd} is parsed as RJson object
    with padding (included in a JavaScript function call) and will be evaluated
    as such in Komodo. if \code{type = "output"}, the string in \code{cmd} is
    considered to be some R output and will be displayed in the Komodo local
    R console (no evaluation). }
  \item{pad}{ a string naming the JavaScript function to run in Komodo, with
    the constructed Rjson object as argument. If \code{NULL} (by default),
    the Rjson object is evaluated directly without padding. }
  \item{\dots}{ further arguments to pass to \code{toRjson()}. }
}

\value{
  Returns the results of the evaluation of the javascript code in Komodo Edit/IDE
  if \code{async = FALSE}. Note that \code{async = TRUE} is not supported yet.

  If there is an error, or \code{cmd} is an invalid javascript code, 
  a character string containing javascript error message is returned
  (this is changed from version 0.9-47, previously a 'try-error' was
  returned).  
}

\details{
  Komodo Edit (http://www.openkomodo.com/) is an Open Source (MPL, GPL & LGPL)
  editor based on the excellent Mozilla platform and the powerful Scintilla text
  editor widget. It runs on many Linux distributions, on Windows and on Mac OS
  X. Komdo IDE is a commercial equivalent, but with many tools for developers,
  especially targetting languages like Perl, Tcl, Python, Ruby, etc. We are
  currently in the process of rewriting SciViews-R
  (see http://www.sciviews.org/SciViews-R) in a platform independent solution
  using Komodo with a specific extension called SciViews-K and using SciViews-R
  packages (svKomodo, svMisc, svHttp, svSocket, ...) for supporting interaction
  between Komodo and R.

  \code{koCmd()} can only talk to Komdo if the SciViews-K socket server is
  installed. This server is contained in the SciViews-K extension that you can
  download from http://www.sciviews.org/SciViews-K. See Komodo documentation to
  know how to install this extension (drag and drop of the extension on the
  Komodo window works in most platforms).

  We may automatize the installation from R in the future, at least on Windows
  and Macintosh.
}

\note{
  Because of serious security issues, the SciViews-K server only allows
  connections from local clients (running on the same computer). This limitation
  would be relatively easy to eliminate, but at your own risks!

  Data are returned from Komodo to R by using the javascript function
  \code{sv.socket.serverWrite()}, see the examples bellow.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link[svSocket]{startSocketServer}},
  \code{\link[svSocket]{processSocket}} }

\examples{
\dontrun{
## Make sure you have started Komodo Edit or IDE with the SciViews-K extension
## installed on the same machine, and the socket server started and then...

## Send JavaScript commands to Komodo
## Alert box in Komodo, and then reply to R
koCmd(c('alert("Hello from R!");',
    'sv.socket.serverWrite("Hello from OpenKomodo (" + ko.interpolate.currentFilePath() + ")");'))

## Open a web page wih Komodo configuration
koCmd("ko.open.URI('about:config','browser');")

## Get info from Komodo
koCmd("sv.socket.serverWrite(ko.logging.getStack());")

## Passing a large amount of data to Komodo, and then, back to R
koCmd(paste('sv.socket.serverWrite("', rep(paste(iris, collapse = "\\\\n"), 10), '");', sep = ""))

## It is easier to use 'data =' instead of paste() for constructing the JS command
koCmd('alert("<<<data>>>");', data = search())

## Using a named list for data to replace in the cmd
koCmd('alert("This is R version <<<major>>>.<<<minor>>>");', R.version)

## Sending incorrect javascript instruction
koCmd('nonexistingJSfunction();')
## Should return something like:
## "ReferenceError: nonexistingJSfunction is not defined"


## Sending RjsonP (Rjson with padding) instruction to Komodo
koCmd("Hello with RjsonP!", type = "rjsonp", pad = "alert")

## This is more useful to pass complex R objects to Komodo
koCmd(head(iris), type = "rjsonp", pad = "sv.socket.serverWrite")


## Send simple text (no evaluation) to the Komodo R console
koCmd("Hello again from R!", type = "output")
}
}

\keyword{ IO }

\concept{ interprocess commnunication Komodo }

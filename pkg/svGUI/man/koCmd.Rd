\name{koCmd}
\alias{koCmd}

\title{ Connect to the SciViews-K (Komodo Edit) socket server and run javascript
  code in Komodo }

\description{
  If Komodo Edit with the SciViews-K extension is running on your machine, you
  can connect to its socket server and run javascript code in it with this
  function.
}

\usage{
koCmd(cmd, data = NULL, async = FALSE, host = getOption("ko.host"),
    port = getOption("ko.port"), timeout = 1)
}

\arguments{
  \item{cmd}{ The javascript you want to execute in Komodo Edit, in a character
    string vector. }
  \item{data}{ If a names list, replace <<<name>>> in cmd for each name of the
    list by its component first. If a character string, replace <<<data>>> in
    cmd. If \code{NULL} (be default), do nothing to cmd before submitting it.
    See the last examples for using data. }
  \item{async}{ Not used yet! }
  \item{host}{ The host where Komodo is located. Currently, only \code{localhost}
    is accepted. Can be changed by setting \code{options(ko.host = ....)}. }
  \item{port}{ The socket port where the SciViews-K server is listening, by
    default, it is port 7052. Can be changed by setting
    \code{options(ko.port = ....)}. }
  \item{timeout}{ Number of seconds to wait for response. }
}

\value{
  Returns the results of the evaluation of the javascript code in Komodo Edit if
  \code{async = FALSE}. Note that \code{async = TRUE} is not supported yet.

  If there is an error, or \code{cmd} is an invalid javascript code, 
  a character string containing javascript error message is returned.
  (Note: this changed from version 0.9-47, previously a 'try-error' was returned)  
}

\details{
  Komodo Edit (http://www.openkomodo.com/) is an Open Source (MPL, GPL & LGPL)
  editor based on the excellent Mozilla platform and the powerful Scintilla text
  editor widget. It runs on many Linux distributions, on Windows and on Mac OS X.
  Komdo IDE is a commercial equivalent, but with many tools for developers,
  especially targetting languages like Perl, Tcl, Python, Ruby, etc. We are
  currently in the process of rewriting SciViews-R
  (see http://www.sciviews.org/SciViews-R) in a platform independent solution
  using Komodo with a specific extension named SciViews-K and the SciViews-R
  bundle.

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

  Data are returned to R by using the javascript function
  \code{sv.socket.serverWrite()}, see the examples bellow.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link[svSocket]{startSocketServer}},
  \code{\link[svSocket]{processSocket}} }

\examples{
\dontrun{
# Make sure you have started Komodo Edit with the SciViews-K extension installed
# on the same machine you run R, and the socket server started and then...

# Alert box in Komodo, and then reply to R
koCmd(c('alert("Hello from R!");',
    'sv.socket.serverWrite("Hello from OpenKomodo (" + ko.interpolate.currentFilePath() + ")");'))

# Open a web page wih Komodo configuration
koCmd("ko.open.URI('about:config','browser');")

# Get info from Komodo
koCmd("sv.socket.serverWrite(ko.logging.getStack());")

# Passing a large amount of data to Komodo, and then, back to R
koCmd(paste('sv.socket.serverWrite("', rep(paste(iris, collapse = "\\\\n"), 10), '");', sep = ""))

# It is easier to use 'data =' instead of paste() for constructing the JS command
koCmd('alert("<<<data>>>");', data = search())

# Using a named list for data to replace in the cmd
koCmd('alert("This is R version <<<major>>>.<<<minor>>>");', R.version)

# Sending incorrect javascript instruction
 koCmd('nonexistingJSfunction();')
# Should return something like:
# "ReferenceError: nonexistingJSfunction is not defined"

}
}

\keyword{ IO }

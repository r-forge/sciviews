\name{guiDDEInstall}
\alias{guiDDEInstall}
\alias{guiCallTip}
\alias{guiComplete}

\title{ install a DDE server (Windows only) for external IDE/code editor }
\description{
  These functions install and manage a DDE server to return context-sensitive
  calltips or completion lists to external IDE/code editors under Windows.
}
\usage{
guiDDEInstall()
guiCallTip(code, file = NULL, only.args = FALSE, max.width = 60, location = FALSE)
guiComplete(code, file = NULL, givetype = FALSE, sep = "|")
}

\arguments{
  \item{code}{ A piece of R code (in a character string) to analyze }
  \item{file}{ A file where to return the result ("", or NULL for none). You
    can use "clipboard" to send the result to the clipboard under Windows only }
  \item{only.args}{ Do we return the whole calltip or only the function arguments? }
  \item{max.width}{ Reformat the calltip to max.with (use 0 for not reformatting it) }
  \item{location} { If \code{TRUE} then the location (in which package the
    function resides) is appended to the calltip between square brackets }
  \item{givetype}{ Return also the type of each object in the completion list (possibly
    to use set a different icon in the list displayed by the external program) }
  \item{sep}{ The separator to use between the item and its type in the list }
}

\value{
  These functions should be used to interact with an external program. Their result
  is returned invisibly for debugging purposes and is not intended to be use in R.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }
\note{ DDE is a communication protocol that exists only under Windows. Consequently,
       those functions cannot be used (yet) on other platforms.

       On loading of the package, if the \code{option(use.DDE = TRUE)} is defined, the
       DDE server (\code{guiDDEInstall()}) is automatically installed when the package
       is loaded. Also if \code{options(IDE = "[path.to.exe]")}  is defined,
       then that IDE is automatically started afterward.
}

\seealso{ \code{\link[svMisc]{CallTip}}, \code{\link[svMisc]{Complete}} }

\examples{
	\dontrun{
        ## DDE exchange protocol is available ONLY under Windows!

        ## Also, this cannot be run by examples() but should be OK when pasted
        ## into an interactive R session with the tcltk package loaded

        ## Here is how you can test these features under Windows
        options(use.DDE = TRUE)
        library(svIDE) # This should automatically start the
        # DDE server named 'TclEval SciViewsR', according to the option set
        
        # Get some data in the user workspace
        data(trees)
        a <- 1
        b <- "some text in the first instance of R"

        #######################################################
        # To test these functions in an external program, we need now
        # to start a second instance of R. In this second instance, enter:
        library(tcltk)
        .Tcl("package require dde")
        .Tcl("dde services TclEval {}")
        # You should get 'TclEval SciViewsR' in the list
        # if the server in the first instance is running
        
        # Now, request a calltip for the function 'ls'
        # This is done in two steps:
        # 1) Execute the command 'guiCallTip' with this code chunk as argument
        .Tcl("dde execute TclEval SciViewsR {guiCallTip {res <- ls(}}")
        # 2) Retrieve the calltip from the variable SciViewsR_CallTip
        .Tcl("dde request TclEval SciViewsR SciViewsR_CallTip")

        # Another way to trigger DDE commands (for programs that do not support
        # DDE is to use 'execdde.exe' of the tcltk2 package (see ?tk2dde)

        # It is also possible to copy the calltip to a file, or to the clipboard
        # by specifying it after the command (also the two additional arguments
        # have their default values changed)
        .Tcl("dde execute TclEval SciViewsR {guiCallTip {library(} clipboard TRUE 40 TRUE}")
        # Look at what is in the clipboard
        cat(readClipboard(), "\n")

        # The process is similar to get completion lists
        .Tcl("dde execute TclEval SciViewsR {guiComplete {iris$}}")
        .Tcl("dde request TclEval SciViewsR SciViewsR_Complete")

        # Get the list of variables in the user workspace of the first R instance
        # into the clipboard (use also the other arguments to get the type of objects)
        .Tcl("dde execute TclEval SciViewsR {guiComplete {} clipboard TRUE { - }}")
        # Look at what is in the clipboard
        cat(readClipboard(), "\n")
    }
}
\keyword{ utilities }



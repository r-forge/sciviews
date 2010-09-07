\name{progress}
\alias{progress}

\title{ Display progression of a long calculation on the console and/or in a
  GUI }
\description{
  Display progression level of a long-running task in the console. Two mode can
  be used: either percent of achievement (55\%), or the number of items or steps
  done on a total (1 file on 10 done...). This is displayed either through a
  message, or through a text-based "progression bar" on the console, or a true
  progression bar widget in a GUI.
}
\usage{
progress(value, max.value = NULL, progress.bar = FALSE, char = "|",
    init = (value == 0), console = TRUE, gui = TRUE)
}

\arguments{
  \item{value}{ current value of the progression (use a value higher than
    \code{max.value} to dismiss the progression indication automatically. }
  \item{max.value}{ maximum value to be achieved. }
  \item{progress.bar}{ should we display a progression bar on the console? If
    \code{FALSE}, a temporary message is used. }
  \item{char}{ the character to use to fill the progress bar in the console. not
    used for the alternate display, or for GUI display of progression.}
  \item{init}{ do we have to initialize the progress bar? It is usually done the
    first time the function is used, and the default value
	\code{init = (value == 0)} is correct most of the time. You must specify
	\code{init = TRUE} in two cases: (1) if the first value to display is
	different from zero, and (2) if your code issues some text on screen during
	progression display. Hence, you must force redraw of the progression bar. }
  \item{console}{ do we display progression on the console? }
  \item{gui}{ do we display progression in a dialog box, or any other GUI widget?
    See "details" and "examples" hereunder to know how to implement your own GUI
    progression indicator. }
}

\details{
  The function \code{progress()} proposes different styles of pregression
  indicators than the standard \code{txtProgressBar} in package 'utils'.
  
  The function uses backspace (\\8) to erase characters at the console.
  
  With \code{gui = TRUE}, the function looks for all functions defined in the
  '.progress' list located in 'TempEnv' environment. Each function is executed
  in turn with following call: \code{theGUIfunction(value, max.value)}. You are
  responsible to create \code{theGUIfunction()} and to add it as an element in
  the .progress list in TempEnv. See also example (5) hereunder.
  
  If your GUI display of the progression offers the possibility to stop
  calculation (for instance, using a 'Cancel' button), you are responsible to
  pass this info to your code doing the long calculation and to stop it there.
  Example (5) shows how to do this.
}

\value{
  This function returns NULL invisibly. It is invoked for its side effects.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\note{ In a GUI, it is preferable to use a non modal dialog box with a progress
widget, or to display such a progress widget in the status bar of your main
window. }

\examples{
## 1) A simple progress indicator in percent
for (i in 0:101) {
	progress(i)
	Sys.sleep(0.05)
	if (i == 101) cat("Done!\n")
}

## 2) A progress indicator with 'x on y'
for (i in 0:31) {
	progress(i, 30)
	Sys.sleep(0.2)
	if (i == 31) cat("Done!\n")
}

## 3) A progress bar in percent
for (i in 0:101) {
	progress(i, progress.bar = TRUE)
	Sys.sleep(0.05)
	if (i == 101) cat("Done!\n")
}

## 4) A progress indicator with 'x on y'
for (i in 0:21) {
	progress(i, 20, progress.bar = TRUE)
	Sys.sleep(0.2)
	if (i == 21) cat("Done!\n")
}

## 5) A progression dialog box with Tcl/Tk
\dontrun{
if (require(tcltk)) {
    guiProgress <- function(value, max.value) {
        ## Do we need to destroy the progression dialog box?
        if (value > max.value) {
            try(tkdestroy(getTemp("guiProgressWindow")), silent = TRUE)
            ## Clean temporary variables
            rmTemp(c("guiProgressState", "guiProgressWindow", "guiProgressCancel"))
            ## ...and exit
            return(invisible(FALSE))
        } else if (existsTemp("guiProgressWindow") &&
            !inherits(try(tkwm.deiconify(tt <- getTemp("guiProgressWindow")),
                silent = TRUE), "try-error")) {
            ## The progression dialog box exists
            ## Focus on it and change progress value
            tkfocus(tt)
            State <- getTemp("guiProgressState")
            tclvalue(State) <- value
        } else {
            ## The progression dialog box must be (re)created
            ## First, make sure there is no remaining "guiProgressStop"
            rmTemp("guiProgressCancel")
            ## Create a Tcl variable to hold current progression state
            State <- tclVar(value)
            assignTemp("guiProgressState", State)
            ## Create the progression dialog box
            tt <- tktoplevel()
            assignTemp("guiProgressWindow", tt)
            tktitle(tt) <- "Waiting..."
            sc <- tkscale(tt, orient = "h", state = "disabled", to = max.value,
                label = "Progress (%):", length = 200, variable = State)
            tkpack(sc)
            but <- tkbutton(tt, text = "Cancel", command = function() {
                ## Set a flag telling to stop running calculation
                assignTemp("guiProgressCancel", TRUE) # Content is not important!
                ## Destroy the window
                tkdestroy(tt)
            })
            tkpack(but)
        }
        return(invisible(TRUE))
    }
    ## Register it as function to use in progress()
    changeTemp(".progress", "guiProgress", guiProgress, replace.existing = FALSE)
    rm(guiProgress) # Don't need this any more
    ## Test it...
    for (i in 0:101) {
    	progress(i) # Could also set console = FALSE for using the GUI only
    	Sys.sleep(0.1)
    	## The code to stop long calc when user presses "Cancel"
    	if (existsTemp("guiProgressCancel")) {
    	    progress(101, console = FALSE) # Make sure to clean up everything
    	    break
    	}
    	if (i == 101) cat("Done!\n")
    }
    ## Unregister the GUI for progress
    changeTemp(".progress", "guiProgress", NULL)
}
}
}

\keyword{ utilities }

\concept{ Graphical user inteface (GUI) long process progression and feedback }

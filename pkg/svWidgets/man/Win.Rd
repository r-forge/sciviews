\name{Win}
\alias{WinAdd}
\alias{WinDel}
\alias{WinGet}
\alias{WinNames}
\alias{print.guiWin}

\title{ Manipulate Windows }
\description{
  R can combine various windows (native, Tk, Gtk, etc.). There could be problems
  when a GUI uses various kinds of windows together. For instance, it is very
  difficult to define a modal window that is modal for the whole application.
  These functions manage windows and ease their clean creation and destruction.
}
\usage{
WinAdd(name = "win1", type = "tkWin", parent = .TkRoot, title = NULL,
    pos = NULL, bind.delete = TRUE, \dots)
WinDel(window)
WinGet(window)
WinNames()

\method{print}{guiWin}(x, \dots)
}

\arguments{
  \item{name}{ name for a new  window }
  \item{type}{ type of window to create. Currently, only Tk windows (\"tkWin\")
    are supported }
  \item{parent}{ parent of this window }
  \item{title}{ title of the window }
  \item{pos}{ where to place the window. A string like '+XX+YY' where XX is the
    horizontal position in pixels, and YY is the vertical position. Using
    negative values place the window relative to the right or bottom side of the
    screen. Specifying \code{NULL} (by default) allows for automatic placement
    of the window. }
  \item{bind.delete}{ do we automatically bind \code{WinDel()} to the windows
    delete event (strongly advised for correct housekeeping)? }
  \item{\dots}{ additional options to pass to the window creator, or the print()
    method. }
  \item{window}{ the name of a 'guiWin' object .}
  \item{x}{ an object of class 'guiWin'. }
}

\details{
  The list of windows and pointers to their handles are stored in '.guiWins'
  in the \code{SciViews:TempEnv} environnement.
}

\value{
  \code{WinAdd()} and \code{WinGet()} return the handle to the window (invisibly
    for \code{WinAdd()}.
  \code{WinNames()} return the list of all windows registered in .guiWins.
  \code{WinDel()} returns invisibly \code{TRUE} if the window is found and
    deleted, \code{FALSE} otherwise.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{tkWinAdd}}, \code{\link{MenuReadPackage}} }

\examples{
\dontrun{
## These cannot be run by examples() but should be OK when pasted
## into an interactive R session with the tcltk package loaded

## Creating and destroying a Tk window and inspecting the list
WinNames()
WinAdd("tt", title = "My win", pos ="-40+20")
WinNames()
tkwm.deiconify(WinGet("tt")) # Standard tcltk functions on the window
WinDel("tt")
WinNames()
}
}

\keyword{ utilities }

\concept{ GUI windows management system }

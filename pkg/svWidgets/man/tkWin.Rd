\name{tkWin}
\alias{tkWinAdd}
\alias{tkWinDel}

\title{ Conveniently manipulate Tk windows }
\description{
  These functions provide an easy way to create and manipulate Tk windows
  under R. Note that the corresponding \code{WinXXX()} function also manipulate
  Tk windows the same way, but are capable of manipulating other windows as
  well (in the future). One should, thus, preferably use \code{WinXXX()}!
}
\usage{
tkWinAdd(name = "win1", parent = .TkRoot, title = NULL, pos = NULL,
    bind.delete = TRUE, \dots)
tkWinDel(window)
}

\arguments{
  \item{name}{ name for a new  Tk window. }
  \item{parent}{ parent of this window. }
  \item{title}{ title of the window. }
  \item{pos}{ where to place the window. A string like '+XX+YY' where XX is the
    horizontal position in pixels, and YY is the vertical position. Using
    negative values place the window relative to the right or bottom side of the
    screen. Specifying \code{NULL} (by default) allows for automatic placement
    of the window. }
  \item{bind.delete}{ do we automatically bind \code{tkWinDel()} to the window
    delete event (strongly advised for correct housekeeping)? }
  \item{\dots}{ additional options to pass to the window creator. }
  \item{window}{ the name of a 'tkguiWin' object. }
}

\details{
  Do not use these functions directly. Prefer the corresponding \code{WinXXX()}
  functions that will call them if Tk windows are concerned.
}

\value{
  \code{tkWinAdd()} returns the handle of the newly created window invisibly.
  \code{tkMenuDel()} returns invisibly \code{TRUE} if the window is found and
    deleted, \code{FALSE} otherwise.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{WinAdd}} }

\keyword{ utilities }

\concept{ GUI windows management in Tcl/Tk }

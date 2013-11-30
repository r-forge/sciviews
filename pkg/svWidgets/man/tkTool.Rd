\name{tkTool}
\alias{tkToolAdd}
\alias{tkToolAddItem}
\alias{tkToolDel}
\alias{tkToolDelItem}
\alias{tkToolItems}
\alias{tkToolChangeItem}
\alias{tkToolStateItem}
\alias{tkToolInvoke}

\title{ Conveniently manipulate Tk toolbars }
\description{
  These functions provide an easy way to create and manipulate Tk toolbars
  under R. Note that the corresponding \code{toolXXX()} function also manipulate
  Tk toolbars the same way, but are capable of manipulating other toolbars as
  well (not currently, but that could be implemented in the future). One should,
  thus, preferably use \code{toolXXX()}!
}

\usage{
tkToolAdd(toolbar, side = "top")
tkToolAddItem(toolbar, item, action, image = "", options = "")
tkToolDel(toolbar)
tkToolDelItem(toolbar, item)
tkToolItems(toolbar)
tkToolChangeItem(toolbar, item, action = "", options = "")
tkToolStateItem(toolbar, item, active = TRUE)
tkToolInvoke(toolbar, item)
}

\arguments{
  \item{toolbar}{ name of a Tk toolbar. }
  \item{side}{ where to place the toolbar in the window (\"top\", \"bottom\",
    \"left\", or \"right\")? }
  \item{item}{ name of a toolbutton. }
  \item{action}{ action the toolbutton triggers (R code). }
  \item{image}{ name of a Tk image to display in the toolbutton. }
  \item{options}{ additional options, for instance 'state = "disable"' to
	disable the toolbutton at creation. }
  \item{active}{ do we enable or disable the toolbutton? }
}

\details{
  Do not use these functions directly. Prefer the corresponding \code{toolXXX()}
  functions that will call them if Tk toolbars or toolbutton are provided.
}

\value{
  \code{tkToolAdd()} and \code{tkToolAddItem()} return the handle of the newly
    created toolbar or toolbutton invisibly.
  \code{tkToolDel()} and \code{tkToolDelItem()} return invisibly \code{TRUE} if
    the resource is found and deleted, \code{FALSE} otherwise.
  \code{tkToolItems()} returns the list of all items in a given toolbar.
  \code{tkToolInvoke()} returns invisibly \code{TRUE} if the toolbutton was
    invoked, \code{FALSE} otherwise.
  \code{tkToolStateItem()} returns the new state of the toolbutton.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{toolAdd}} }

\keyword{ utilities }

\concept{ GUI toolbar resources management in Tcl/Tk }

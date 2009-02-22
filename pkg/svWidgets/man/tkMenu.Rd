\name{tkMenu}
\alias{tkMenuAdd}
\alias{tkMenuAddItem}
\alias{tkMenuDel}
\alias{tkMenuDelItem}
\alias{tkMenuItems}
\alias{tkMenuChangeItem}
\alias{tkMenuStateItem}
\alias{tkMenuInvoke}

\title{ Conveniently manipulate Tk menus }
\description{
  These functions provide an easy way to create and manipulate Tk menus
  under R. Note that the corresponding \code{MenuXXX()} function also manipulate
  Tk menus the same way, but are capable of manipulating other menus as well.
  One should, thus, preferably use \code{MenuXXX()}!
}
\usage{
  tkMenuAdd(menu, tearoff = FALSE)
  tkMenuAddItem(menu, item, action, image = "", accel = "", options = "")
  tkMenuDel(menu)
  tkMenuDelItem(menu, item)
  tkMenuItems(menu)
  tkMenuChangeItem(menu, item, action = "", options = "")
  tkMenuStateItem(menu, item, active = TRUE)
  tkMenuInvoke(menu, item)
}

\arguments{
  \item{menu}{ Name of a menu }
  \item{tearoff}{ Should the menu be detachable? }
  \item{item}{ Name of a menu item }
  \item{action}{ Action the menu triggers (R code) }
  \item{image}{ Name of an image to display at left of the menu item }
  \item{accel}{ Accelerator (keystroke) to use to trigger this menu item }
  \item{options}{ Additional options, for instance 'state = "disable"' to
	disable the menu at creation. }
  \item{active}{ Do we enable or disable the menu item? }
}

\details{
  Do not use these functions directly. Prefer the corresponding \code{MenuXXX()}
  functions that will call them if Tk menus or menu items are provided.
}

\value{
  \code{tkMenuAdd()} and \code{tkMenuAddItem()} return the handle of the newly
    created menu/menu item invisibly.
  \code{tkMenuDel()} and \code{tkMenuDelItem()} return invisibly \code{TRUE} if
    the resource is found and deleted, \code{FALSE} otherwise.
  \code{tkMenuItems()} returns the list of all items in a given menu.
  \code{tkMenuInvoke()} returns invisibly \code{TRUE} if the menu item was
    invoked, \code{FALSE} otherwise.
  \code{tkMenuStateItem()} returns the new state of the menu.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{MenuAdd}} }

\keyword{ utilities }

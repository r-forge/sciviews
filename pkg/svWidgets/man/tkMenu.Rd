\name{tkMenu}
\alias{tkMenuAdd}
\alias{tkMenuAddItem}
\alias{tkMenuDel}
\alias{tkMenuDelItem}
\alias{tkMenuItemCall}
\alias{tkMenuItems}
\alias{tkMenuChangeItem}
\alias{tkMenuStateItem}
\alias{tkMenuInvoke}

\title{ Conveniently manipulate Tk menus }
\description{
  These functions provide an easy way to create and manipulate Tk menus
  under R. Note that the corresponding \code{menuXXX()} function also manipulate
  Tk menus the same way, but are capable of manipulating other menus as well.
  One should, thus, preferably use \code{menuXXX()}!
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
tkMenuItemCall(expr)
}

\arguments{
  \item{menu}{ name of a menu. }
  \item{tearoff}{ should the menu be detachable? }
  \item{item}{ name of a menu item. }
  \item{action}{ action the menu triggers (R code). }
  \item{image}{ name of an image to display at left of the menu item. }
  \item{accel}{ accelerator (keystroke) to use to trigger this menu item. }
  \item{options}{ additional options, for instance 'state = "disable"' to
    disable the menu at creation. }
  \item{active}{ do we enable or disable the menu item? }
  \item{expr}{ an expression to execute corresponding to the menu item call. }
}

\details{
  Do not use these functions directly. Prefer the corresponding \code{menuXXX()}
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
  \code{tkMenuItemCall()} is usually not called directly by the end-user, but
    rather through a menu. It is a user-visible function so that it is possible
    to substitute it with a custom function to manage menu item calls
    differently in a custom GUI, for instance.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{menuAdd}} }

\keyword{ utilities }

\concept{ GUI menu management in Tcl/Tk }

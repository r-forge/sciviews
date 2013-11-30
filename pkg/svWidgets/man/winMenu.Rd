\name{winMenu}
\alias{winMenuChangeItem}
\alias{winMenuStateItem}
\alias{winMenuInvoke}

\title{ Additional winMenuXXX() functions }
\description{
  A couple of winMenuXXX() functions are defined in the package 'utils'
  to manipulate custom menus of Rgui (under windows only). Here are some
  additional ones. Note that you should preferably use the corresponding
  menuXXX() function defined in this package (they work with windows menus
  as well as other menus, like Tk.
}
\usage{
winMenuChangeItem(menu, item, action, options = "")
winMenuStateItem(menu, item, active = TRUE)
winMenuInvoke(menu, item)
}

\arguments{
  \item{menu}{ name of a menu. }
  \item{item}{ name of a menu item. }
  \item{action}{ action the menu triggers (R code). }
  \item{options}{ additional options. Only supports "enable" or "disable",
    currenty. }
  \item{active}{ do we enable or disable the menu item? }
}

\details{
  These functions are used only under Windows, and when RgGui.exe is executed.

  These functions complement the winMenuXXX() functions in package 'utils'.
  Do prefer to use the corresponding menuXXX() functions that work with all
  types of menus (currently, only Windows RGui and Tk, but more could be added
  in the future).
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{menuChangeItem}}, \code{\link{menuStateItem}},
  \code{\link{menuInvoke}} }

\keyword{ utilities }

\concept{ Windows RGui menus management }

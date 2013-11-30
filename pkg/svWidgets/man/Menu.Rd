\name{Menu}
\alias{menuAdd}
\alias{menuAddItem}
\alias{menuDel}
\alias{menuDelItem}
\alias{menuNames}
\alias{menuInvoke}
\alias{menuItems}
\alias{menuType}
\alias{menuChangeItem}
\alias{menuStateItem}
\alias{menuRead}
\alias{menuReadPackage}
\alias{print.guiMenu}

\title{ Conveniently manipulate menus, whatever the window }
\description{
  These functions provide an unifying way of dealing with menus in R.
  It is inspired from the winMenuXXX() functions under Windows that allow
  easy manipulation of custom menus in Rgui.exe. Currently, they support all
  the functionnalities of winMenuXXX() functions and they bring a convenient
  similar layer on top of Tk menus to manipulate them in a similar way.
}
\usage{
menuAdd(menu, \dots)
menuAddItem(menu, item, action, image = "", accel = "", options = "")
menuDel(menu)
menuDelItem(menu, item)
menuNames()
menuItems(menu)
menuType(menu, warn = TRUE)
menuInvoke(menu, item)
menuChangeItem(menu, item, action = "", options = "")
menuStateItem(menu, item, active = TRUE)
menuRead(file = "Menus.txt")
menuReadPackage(package, subdir = "gui", file = "Menus.txt")

\method{print}{guiMenu}(x, \dots)
}

\arguments{
  \item{menu}{ name of a menu. }
  \item{item}{ name of a menu item. }
  \item{action}{ action the menu triggers (R code). }
  \item{image}{ name of an image to display at left of the menu item. }
  \item{accel}{ accelerator (keystroke) to use to trigger this menu item. }
  \item{options}{ additional options, for instance "disable" to
	disable the menu at creation. }
  \item{warn}{ do we issue a warning if the type of menu is not recognized? }
  \item{active}{ do we enable or disable the menu item? }
  \item{file}{ a file containing menu specifications to read. }
  \item{package}{ name of a package from where to load menu specifications. }
  \item{subdir}{ subdirectory in the package where the menu specifications are
    stored. By default, it is the "gui" subdirectory. }
  \item{x}{ an object of class 'guiMenu'. }
  \item{\dots}{ further arguments passed to the function. }
}

\details{
  These functions care about creating, deleting and managing custom menus.
  Informations and handles to the various menus created with these functions
  are stored in the .guiMenus variable, located in the \code{SciViews:TempEnv}
  environment.
}

\value{
  \code{menuAdd()} and \code{menuAddItem()} return the handle to the newly
    created menu/menu item invisibly.
  \code{menuDel()} and \code{menuDelItem()} return invisibly \code{TRUE} if the
    resource is found and deleted, \code{FALSE} otherwise.
  \code{menuNames()} returns the list of all menus registered in .guiMenus in
    the \code{SciViews:TempEnv} environment.
  \code{menuInvoke()} returns invisibly \code{TRUE} if the menu item was
    invoked, \code{FALSE} otherwise.
  \code{menuRead()} and \code{menuReadPackage()} return invisibly the list of
    menus that are imported and created.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{tkMenuAdd}}, \code{\link{imgReadPackage}} }

\examples{
\dontrun{
## These cannot be run by examples() but should be OK when pasted
## into an interactive R session with the tcltk package loaded
## Run these commands one at a time and look at menus...


### Under RGui and Windows only! ###
## Create menus in Rgui, using a specification file
menuReadPackage("svWidgets")
menuNames()
(menuItems("$ConsoleMain/Testit"))

## Create menus manually in Rgui
menuAdd("$ConsoleMain/Testit2")
menuAddItem("$ConsoleMain/Testit2", "Trial", "ls()")
menuNames()
(menuItems("$ConsoleMain/Testit2"))
menuStateItem("$ConsoleMain/Testit2", "Trial", FALSE)
menuStateItem("$ConsoleMain/Testit2", "Trial", TRUE)
## Buggy? -> menuChangeItem("$ConsoleMain/Testit2", "Trial", "search()")
(menuItems("$ConsoleMain/Testit2"))


### Under any system supporting Tcl/Tk ###
## Create and manipulate Tk menus
winAdd("tt", title = "A Tk window with menus", pos ="-40+20")
menuAdd("$Tk.tt/Misc")
menuNames()
(menuItems("$Tk.tt/Misc"))  # Still nothing in it
menuAddItem("$Tk.tt/Misc", "List &variables", "print(ls(envir = .GlobalEnv))")
menuAddItem("$Tk.tt/Misc", "Say &yo!", "cat('yo!\n')")

menuDelItem("$Tk.tt/Misc", "Say &yo!")
menuAddItem("$Tk.tt/Misc", "-")
menuAddItem("$Tk.tt/Misc", "&Say yo! twice", "cat('yo! yo!\n')")
(menuItems("$Tk.tt/Misc"))

imgReadPackage("svWidgets")  # Make sure images are loaded
menuAdd("$Tk.tt/Misc/Sub&Menu")
menuAddItem("$Tk.tt/Misc/Sub&Menu", "T&rial", "cat('Trial trigerred!\n')")
menuAddItem("$Tk.tt/Misc", "Tria&l2", "cat('Trial with image and accel!\n')",
	image = "$Tk.butOpen", accel = "Ctrl+T")
menuNames()
(menuItems("$Tk.tt/Misc"))
menuStateItem("$Tk.tt/Misc", "Tria&l2", FALSE)
menuStateItem("$Tk.tt/Misc", "Tria&l2", TRUE)
menuStateItem("$Tk.tt/Misc", "Sub&Menu", FALSE)
menuStateItem("$Tk.tt/Misc", "Sub&Menu", TRUE)
menuChangeItem("$Tk.tt/Misc", "Tria&l2", options = "underline = 1")
## This is the way to change binding
tkbind(WinGet("tt"), "<Control-r>", function() menuInvoke("$Tk.tt/Misc", "Tria&l2"))
menuChangeItem("$Tk.tt/Misc", "Tria&l2", action = 'cat("new action for Tria&l2!\n")')
menuInvoke("$Tk.tt/Misc", "Tria&l2")
(menuItems("$Tk.tt/Misc"))
menuDelItem("$Tk.tt/Misc", "Tria&l2")
menuDel("$Tk.tt/Misc")
menuNames()
## The following command generates an error!
(menuItems("$Tk.tt/Misc"))
winDel("tt")
}
}

\keyword{ utilities }

\concept{ GUI menus management }

\name{Tool}
\alias{toolAdd}
\alias{toolAddItem}
\alias{toolDel}
\alias{toolDelItem}
\alias{toolNames}
\alias{toolInvoke}
\alias{toolItems}
\alias{toolType}
\alias{toolChangeItem}
\alias{toolStateItem}
\alias{toolRead}
\alias{toolReadPackage}
\alias{print.guiTool}

\title{ Conveniently manipulate toolbars, whatever the window }
\description{
  These functions provide an unifying way of dealing with (simple) toolbars
  in R. Currently, they support only Tcl/Tk toolbars and toolbuttons, but other
  graphical toolboxes could be supported too in the future.
}
\usage{
toolAdd(toolbar, side = "top")
toolAddItem(toolbar, item, action, image = "", options = "")
toolDel(toolbar)
toolDelItem(toolbar, item)
toolNames()
toolItems(toolbar)
toolType(toolbar, warn = TRUE)
toolInvoke(toolbar, item)
toolChangeItem(toolbar, item, action = "", options = "")
toolStateItem(toolbar, item, active = TRUE)
toolRead(file = "Tools.txt")
toolReadPackage(package, subdir = "gui", file = "Tools.txt")

\method{print}{guiTool}(x, \dots)
}

\arguments{
  \item{toolbar}{ name of a toolbar. }
  \item{side}{ where to place the toolbar in the window (\"top\", \"bottom\",
    \"left\", or \"right\")? }
  \item{item}{ name of a toolbar item (a toolbutton). }
  \item{action}{ action the toolbutton triggers (R code). }
  \item{image}{ name of an image to display in the toolbutton. }
  \item{options}{ additional options, for instance "disable" to
	disable the toolbutton at creation. }
  \item{warn}{ do we issue a warning if the type of menu is not recognized? }
  \item{active}{ do we enable or disable the toolbutton? }
  \item{file}{ a file containing toolbars specifications to read. }
  \item{package}{ name of a package from where to load toolbars specifications. }
  \item{subdir}{ subdirectory in the package where the toolbars specifications
    are stored. By default, it is the "gui" subdirectory. }
  \item{x}{ an object of class 'guiTool'. }
  \item{\dots}{ further arguments (currently not used). }
}

\details{
  These functions care about creating, deleting and managing custom toolbars.
  Informations and handles to the various toolbars created with these functions
  are stored in the .guiTools variable, located in the \code{SciViews:TempEnv}
  environment.

  Use 'img' resources to load images to display in the toolbuttons.
}

\value{
  \code{toolAdd()}, \code{toolAddItem()} return the handle to the newly created
    toolbar or toolbutton invisibly.
  \code{toolDel()} and \code{toolDelItem()} return invisibly \code{TRUE} if the
    resource is found and deleted, \code{FALSE} otherwise.
  \code{toolNames()} returns the list of all toolbars registered in .guiTools in
    the \code{SciViews:TempEnv} environment.
  \code{toolInvoke()} returns invisibly \code{TRUE} if the toolbutton was
    invoked, \code{FALSE} otherwise.
  \code{toolRead()} and \code{toolReadPackage()} return invisibly the list of
    toolbars that are imported and created.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{tkToolAdd}}, \code{\link{imgReadPackage}} }

\examples{
\dontrun{
## These cannot be run by examples() but should be OK when pasted
## into an interactive R session with the tcltk package loaded
## Run these commands one at a time

winAdd("tt", title = "A Tk window with toolbars", pos ="-40+20")
imgReadPackage("svWidgets")     # Make sure images are loaded
## Create a toolbar and populate it
toolAdd("$Tk.tt/Main")
toolNames()
(toolItems("$Tk.tt/Main"))   # Still nothing in it
toolAddItem("$Tk.tt/Main", "List variables",
    action = "print(ls(envir = .GlobalEnv))", image = "$Tk.butCopy")
toolAddItem("$Tk.tt/Main", "Say yo!", action = "cat('yo!\n')")
toolAddItem("$Tk.tt/Main", "-")
toolAddItem("$Tk.tt/Main", "Search",
    action = "print(search())", image = "$Tk.butPaste")
(toolItems("$Tk.tt/Main"))
## Change state of buttons in the toolbar
toolStateItem("$Tk.tt/Main", "Search", FALSE)
toolStateItem("$Tk.tt/Main", "Search", TRUE)
toolStateItem("$Tk.tt/Main", "Say yo!", FALSE)
toolStateItem("$Tk.tt/Main", "Say yo!", TRUE)
## Invoke a button
toolInvoke("$Tk.tt/Main", "Say yo!")
## Remove a button and add another one (always at the end!)
toolDelItem("$Tk.tt/Main", "Say yo!")
toolAddItem("$Tk.tt/Main", "Say yo! twice", "cat('yo! yo!\n')")
(toolItems("$Tk.tt/Main"))
toolDel("$Tk.tt/Main")
toolNames()
(toolItems("$Tk.tt/Main"))
winDel("tt")
}
}

\keyword{ utilities }

\concept{ GUI toolbar management and resources }

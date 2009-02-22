\name{Tool}
\alias{ToolAdd}
\alias{ToolAddItem}
\alias{ToolDel}
\alias{ToolDelItem}
\alias{ToolNames}
\alias{ToolInvoke}
\alias{ToolItems}
\alias{ToolType}
\alias{ToolChangeItem}
\alias{ToolStateItem}
\alias{ToolRead}
\alias{ToolReadPackage}
\alias{print.guiTool}

\title{ Conveniently manipulate toolbars, whatever the window }
\description{
  These functions provide an unifying way of dealing with (simple) toolbars
  in R. Currently, they support only Tcl/Tk toolbars and toolbuttons, but other
  graphical toolboxes could be supported too in the future.
}
\usage{
  ToolAdd(toolbar, side = "top")
  ToolAddItem(toolbar, item, action, image = "", options = "")
  ToolDel(toolbar)
  ToolDelItem(toolbar, item)
  ToolNames()
  ToolItems(toolbar)
  ToolType(toolbar, warn = TRUE)
  ToolInvoke(toolbar, item)
  ToolChangeItem(toolbar, item, action = "", options = "")
  ToolStateItem(toolbar, item, active = TRUE)
  ToolRead(file = "Tools.txt")
  ToolReadPackage(package, subdir = "gui", file = "Tools.txt")

  \method{print}{guiTool}(x, \dots)
}

\arguments{
  \item{toolbar}{ Name of a toolbar }
  \item{side}{ Where to place the toolbar in the window (\"top\", \"bottom\",
    \"left\", or \"right\")? }
  \item{item}{ Name of a toolbar item (a toolbutton) }
  \item{action}{ Action the toolbutton triggers (R code) }
  \item{image}{ Name of an image to display in the toolbutton }
  \item{options}{ Additional options, for instance "disable" to
	disable the toolbutton at creation. }
  \item{warn}{ Do we issue a warning if the type of menu is not recognized? }
  \item{active}{ Do we enable or disable the toolbutton? }
  \item{file}{ A file containing toolbars specifications to read }
  \item{package}{ Name of a package from where to load toolbars specifications }
  \item{subdir}{ Subdirectory in the package where the toolbars specifications
    are stored. By default, it is the "gui" subdirectory. }
  \item{x}{ An object of class 'guiTool' }
  \item{\dots}{ Further arguments (currently not used) }
}

\details{
  These functions care about creating, deleting and managing custom toolbars.
  Informations and handles to the various toolbars created with these functions
  are stored in the .guiTools variable, located in the 'TempEnv' environment.

  Use 'Img' resources to load images to display in the toolbuttons.
}

\value{
  \code{ToolAdd()}, \code{ToolAddItem()} return the handle to the newly created
    toolbar or toolbutton invisibly.
  \code{ToolDel()} and \code{ToolDelItem()} return invisibly \code{TRUE} if the
    resource is found and deleted, \code{FALSE} otherwise.
  \code{ToolNames()} returns the list of all toolbars registered in .guiTools in
    the 'TempEnv' environment.
  \code{ToolInvoke()} returns invisibly \code{TRUE} if the toolbutton was
    invoked, \code{FALSE} otherwise.
  \code{ToolRead()} and \code{ToolReadPackage()} return invisibly the list of
    toolbars that are imported and created.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{tkToolAdd}}, \code{\link{ImgReadPackage}} }

\examples{
  \dontrun{
## These cannot be run by examples() but should be OK when pasted
## into an interactive R session with the tcltk package loaded
## Run these commands one at a time

WinAdd("tt", title = "A Tk window with toolbars", pos ="-40+20")
ImgReadPackage("svWidgets")     # Make sure images are loaded
# Create a toolbar and populate it
ToolAdd("$Tk.tt/Main")
ToolNames()
(ToolItems("$Tk.tt/Main"))   # Still nothing in it
ToolAddItem("$Tk.tt/Main", "List variables",
	action = "print(ls(envir = .GlobalEnv))", image = "$Tk.butCopy")
ToolAddItem("$Tk.tt/Main", "Say yo!", action = "cat('yo!\n')")
ToolAddItem("$Tk.tt/Main", "-")
ToolAddItem("$Tk.tt/Main", "Search",
	action = "print(search())", image = "$Tk.butPaste")
(ToolItems("$Tk.tt/Main"))
# Change state of buttons in the toolbar
ToolStateItem("$Tk.tt/Main", "Search", FALSE)
ToolStateItem("$Tk.tt/Main", "Search", TRUE)
ToolStateItem("$Tk.tt/Main", "Say yo!", FALSE)
ToolStateItem("$Tk.tt/Main", "Say yo!", TRUE)
# Invoke a button
ToolInvoke("$Tk.tt/Main", "Say yo!")
# Remove a button and add another one (always at the end!)
ToolDelItem("$Tk.tt/Main", "Say yo!")
ToolAddItem("$Tk.tt/Main", "Say yo! twice", "cat('yo! yo!\n')")
(ToolItems("$Tk.tt/Main"))
ToolDel("$Tk.tt/Main")
ToolNames()
(ToolItems("$Tk.tt/Main"))
WinDel("tt")
  }
}

\keyword{ utilities }

\name{menuAdd}
\alias{menuAdd}
\alias{menuAddItem}
\alias{menuDel}
\alias{menuDelItem}
\alias{menuNames}
\alias{menuItems}

\title{ Manage custom R menus }
\description{
  Create, populate and rework custom R menus.
}

\usage{
menuAdd(menuname)
menuAddItem(menuname, itemname, action)
menuDel(menuname)
menuDelItem(menuname, itemname)
menuNames()
menuItems(menuname)
}

\arguments{
  \item{menuname}{ a character string naming a menu. }
  \item{itemname}{ a character string naming a menu item on an existing menu. }
  \item{action}{ a character string describing the action when that menu is
    selected, or \code{"none"} for no action. Use \code{"enable"} or
    \code{"disable"} to activate or desactivate an existing menu item. }
}

\details{
  On Windows, the function manages custom menus in RGui the same way as
  \code{winMenuAdd()} and similar function do. Menus are added to the right
  and new menu entries are added to the bottom of the menu. It is currently
  not possible to add menus for Rterm.exe under Windows.
  
  On Mac OS X, AppleScript custom application folder is used by default. It
  can be used only with R.app and you can access it through Mac script menu
  displayed in menu bar (to activate it, open Utilities -> AppleScript editor,
  then, go to Preferences... and check 'Show script menu in menu bar'). Custom
  R menus will be visible as folders in this menu bar item only when R.app or
  R64.app is the formost application. there is an alternate interface using the
  XMenu menu bar applet. It works with both R.app and R run in a terminal, but
  you have to install and customize it first. Install XMenu from
  http://xmenu.en.softonic.com/mac. You should use the custom commands only for
  R custom menus, because svDialogs will erase everything in it everytime the
  package starts!
  Configure XMenu to display only User-Defined items, and name it \"R\". Select
  \"Folders before files\". For icons, best rendering is obtained with \"None,
  Big font\". For menu titles, select \"Text\" for entries that look like real
  menus. Be sure to check also "Start at login". Selection of XMenu instead of
  AppleScript menus is not automatic, but it can be enabled in two different
  ways: (1) by entering \code{option(useXMenu = TRUE)}, or by placing a \"R\"
  file or folder in '~/Library/Application Support/XMenu'.
  
  On Unix/Linux, under Gnome, you must install xvkbd and the file-browser-applet
  for Gnome. Under Ubuntu, you make:
  sudo apt-get install file-browser-apple
  sudo apt-get install xvkbd
  You need to log out and in again to make the applet available. Then, you need
  to install and configure a file browser applet in a panel right-click in a
  panel, select 'add to Panel...' and drag&drop a 'File Browser'. Right-click on
  the file browser and select 'Preferences'. In the preference box, eliminate
  the default entry (Home) and add all subdirectories from
  ~/Scripts/Applications/R. You can access R menus from there, and it sends
  corresponding commands to the focused window (e.g., a terminal running R)
  If you know of a similar applet for KDE or Unity on Ubunut, please, contact
  me!
  
  On both Mac OS X and Unix/Linux, menus and menu items are sorted
  alphabetically. So, to respect a given order, choose the name of your menus
  and menu items carefully. Possibly prepend items with space(s) to push them
  up in the list.
  
  Action is treated as R input (echoed at the command line, parsed and
  executed), except if it is \code{"none"}. In this case, no action is
  done when the menu item is selected (merely as a placeholder for future
  menu actions). You can change the action of an existing menu by reissuing
  the command with a different action argument.
  
  If the menuname parameter of \code{menuAddItem()} does not exists, it is
  automatically created. For creating submenus, separate successive menu
  names with slashes. Use \code{"-"} as name for separation menus under
  Windows.
}

\value{
  These function return \code{NULL} invisibly. They are used for their
  side-effect of creating, changing, or deleting custom R menus.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\seealso{ \code{\link{guiDlg}}, \code{\link{guiEval}} }

\examples{
\dontrun{
## Add a menu and two entries
menuAdd("Test")
menuAddItem("Test", "List objects", "ls()")
menuAddItem("Test", "List search paths", "search()")
## Add a submenu implicitly
menuAddItem("Test/Submenu", "Current working dir", "setwd()")

## Remove Test menu and submenus
menuDel("Test")
}
}

\keyword{misc}

\concept{ Custom menus }

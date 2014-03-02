\name{svDialogstcltk-package}
\alias{svDialogstcltk-package}
\alias{svDialogstcltk}
\docType{package}

\title{ SciViews GUI API - Dialog boxes using Tcl/Tk }
\description{
  Use Tcl/Tk dialog boxes for your GUI.
}
\details{
  \tabular{ll}{
    Package: \tab svDialogstcltk\cr
    Type: \tab Package\cr
    Version: \tab 0.9-4\cr
    Date: \tab 2014-03-02\cr
    License: \tab GPL 2 or above, at your convenience\cr
  }
  
  This package provides a Tcl/Tk alternative to dialog boxes implemented in
  the svDialogs package. There is no function for direct use, but methods
  implementing the various \code{dlgXXX()} functions of svDialogs.
  
  When the package is loaded, it inserts a new \code{tcltkGUI} dependency in
  the \code{.GUI} object (if it is not defined yet). That way, every call to
  \code{.GUI} dispatches first to the current Tcl/Tk implementation of the
  dialog boxes. For your own, separate GUI (say called \code{myGUI}), you have
  to create the binding by yourself by calling
  \code{guiWidgets(myGUI) <- "tcltkGUI"}.
}

\author{
  Philippe Grosjean

  Maintainer: Ph. Grosjean <phgrosjean@sciviews.org>
}

\keyword{ package }
\keyword{ utilities }

\concept{ GUI API dialog boxes }

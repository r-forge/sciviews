\name{svDialogs-package}
\alias{svDialogs-package}
\alias{svDialogs}
\docType{package}

\title{ SciViews GUI API - Dialog boxes }
\description{
  Use native or pseudo-native dialog boxes for your GUI, including an automatic
  function assistant.
}
\details{
  \tabular{ll}{
    Package: \tab svDialogs\cr
    Type: \tab Package\cr
    Version: \tab 0.9-45\cr
    Date: \tab 2011-11-11\cr
    License: \tab GPL 2 or above, at your convenience\cr
  }
  % TODO: add description of main functions here. Also add examples
}

\author{
  Philippe Grosjean

  Maintainer: Ph. Grosjean <phgrosjean@sciviews.org>
}

\examples{
## TODO...

### Example of a custom function for an imput box that deleguates
#dlgInput.wxGUI <- function (message = "Enter a value",
#default = "", ..., gui = svGUI) {
#	warning("No input box implemented yet with wxWidgets in R!")
#	NextMethod("dlgInput", gui)	
#}

}

\keyword{ package }
\keyword{ utilities }

\concept{ GUI API dialog boxes }

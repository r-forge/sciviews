\name{NEWS}
\title{NEWS file for the svDialogstcltk package}

\section{Changes in version 0.9-2}{
	\itemize{
    \item{ NEWS file reworked to support new Rd format. }
  }
}

\section{Changes in version 0.9-2}{
	\itemize{
    \item{ An \code{imports} for \pkg{svGUI} was missing in the
			\preformatted{NAMESPACE} file. }
  }
}

\section{Changes in version 0.9-1}{
	\itemize{
    \item{ \code{xxxx.tcltkWidgets()} is now rewritten as \code{xxxx.tcltkGUI()}
			to match convention used in \pkg{svDialogs} (\code{nativeGUI}). }
			
		\item{ The message argument in \code{dlgDir.tcltkGUI()} is replaced by title
			to match change made in \pkg{svDialogs} 0.9-48. }
			
		\item{ There are new \code{dlgOpen.tcltkGUI()} and \code{dlgSave.tcltkGUI()}
			functions. }
	}
}

\section{Changes in version 0.9-0}{
	\itemize{
    \item{ This is the first version on R-forge. It is a refactoring from the
			old \pkg{svDialogs} functions that are replaced there by native dialog
			boxes, as much as possible. }
  }
}

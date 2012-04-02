\name{NEWS}
\title{NEWS file for the svKomodo package}

\section{Changes in version 0.9-56}{
	\itemize{
    \item{ NEWS file reworked to use the new Rd format. }
  }
}

\section{Changes in version 0.9-55}{
	\itemize{
    \item{ On some machines, \code{system("locate Komodo ...")} fails. Added
			some more checking in this situation. }
			
    \item{ In \code{.onLoad()}, slight reworking of the \code{svPager()}
			function to avoid calling \code{.Internal(file.show(....))}. }			
	}
}

\section{Changes in version 0.9-54}{
	\itemize{
    \item{ Startup code is changed... a part of the code in
			\preformatted{svStart.R} in the SciViews-K plugin is now executed here! }
		
		\item{ Save and load SciViews config in
			\preformatted{~/.SciViewsConfig.RData} file, so that it is possible to
			reconfigure R for SciViews just by reloading the present package. }
	}
}

\section{Changes in version 0.9-53}{
	\itemize{
    \item{ \code{koCmd()} can now use either socket or file for communication
			with Komodo. }
	}
}

\section{Changes in version 0.9-52}{
	\itemize{
    \item{ The package is created from \pkg{svGUI} 0.9-51 (functions that
			concern interaction with Komodo Edit/IDE). \code{guiInstall()},
			\code{guiUninstall()}, \code{guiRefresh()} & \code{guiAutoRefresh()} are
			also renamed \code{koXXX()}, in order to better match their purpose (to
			communicate with Komodo Edit/IDE only), while the previous implementation
			was intended for more general purpose. Since, it was never used elsewhere,
			narrowing its scope allows to simplify the code greatly! }
			
	  \item{ The callback mechanism to run commands from a client is now moved
			from \pkg{svSocket} package to here, so that it can also be used in the
			\pkg{svHttp} package. }
			
		\item{ \code{koRefresh()} now look at the "changed" attribute of the object
			returned by \code{objList()}, and so, can make the difference between no
			changes, and changes, but the environment got no more objects. }
			
		\item{ For additional changes in these functions in \pkg{svGUI} up to
			version 0.9-51, see its corresponding \preformatted{NEWS} file. }
  }
}

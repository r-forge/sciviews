\name{NEWS}
\title{NEWS file for the svKomodo package}

\section{Changes in version 0.9-62}{
  \itemize{
    \item{ Starting from R revision >= 67550, the HTML help port is now retrieved using
      tools::startDynamicHelp(NA). }
  }
}

\section{Changes in version 0.9-62}{
  \itemize{
    \item{ Author field rebuild in DESCRIPTION file }
    \item{ \code{.onAttach()} reworked to eliminate \code{:::} (not allowed by CRAN) }
	\item{ \code{utils::rc.settings} are adjusted in \code{.onAttach()} and
	  restored in \code{.onUnload()} }
  }
}

\section{Changes in version 0.9-61}{
  \itemize{
    \item{ Simplification of internal code to get Komodo location. It does not require
        a specific version of \code{locate} on Unix/Linux any more. }
  }
}

\section{Changes in version 0.9-60}{
  \itemize{
    \item{ \code{.onAttach()} is reworked for not issuing warning messages in Mac OS X. }
  }
}

\section{Changes in version 0.9-59}{
  \itemize{
    \item{ R is now configured to be used with SciViews Komodo (Komodo Edit +
	    SciViews-K) when the package is attached. It was previously configured
		when it was loaded. }
    \item{ Temporary objects are now stored in SciViews:TempEnv instead of
	    TempEnv and consequently, svMisc >= 0.9-68 is needed. }
    \item{ Further protection before looking for komodo with locate: (1) if
	    locate is not there, do not try to use it, and (2) do not use it on
		Mac OS X. }
  }
}

\section{Changes in version 0.9-58}{
  \itemize{
    \item{ The package was not loading correctly when not on \code{.libPaths}. Fixed. }
  }
}

\section{Changes in version 0.9-57}{
  \itemize{
    \item{ svKomodo creates now at loading a \code{.Last.sys()} function in
      \code{SciViews:TempEnv} indicating to Komodo Edit that R has quit. This
      is required to update R menus there. }
	
    \item{ The SciViews-K configuration file is not saved from here anymore
      (CRAN now does not accept packages that write files elsewhere than in R
      temp dir). This configuration file is now created by the SciViews-K Komodo
      plugin, in \preformatted{svStart.R}. }
  }
}

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

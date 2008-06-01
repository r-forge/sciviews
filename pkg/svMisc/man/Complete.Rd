\name{Complete}
\alias{Complete}

\title{ Get a completion list for a R code fragment }
\description{
  A list with matching items is returned in a string.
}
\usage{
Complete(code, givetype = FALSE, sep = "\t")
}
\arguments{
  \item{code}{ A fraction of R code needing completion }
  \item{givetype}{ Do we append the type of each entry to the list?
    Not supported in this version }
  \item{sep}{ The separator to use between returned items }
}

\value{
  A string with the completion list (items separated by 'sep'), or
  an unique string completing unambiguously the current code, starting with
  'sep'
}

\details{
    The completion list is context-dependent, and it is calculated as if the
	code was entered at the command line.
    
    If the code ends with \code{$}, then the function look for
	items in a list or data.frame whose name is the last idfentifier.
    
    If the code ends with \code{@}, then the function look for slots of the
    corresponding S4 object.
	
	If the code ends with \code{::}, then it looks for objects in a namespace.
    
    If the code ends with a partial identifier name, the function returns all
    visible matching keywords.
    
    There are other situations where the completion can be calculated, see
	the help of \code{rc.settings()}.
}

\note{
  This function uses \code{utils:::.win32consoleCompletion()} as completion
  engine, then, it makes the result compatible with old version of
  \code{Complete()}. 
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{CallTip}}, \code{\link[utils]{rc.settings()}} }
\examples{
    ## a data.frame
    data(iris)
	Complete("item <- iris$")
	Complete("item <- iris[[", TRUE)
	
	## An S4 object
    setClass("track", representation(x = "numeric", y = "numeric"))
    t1 <- new("track", x=1:20, y=(1:20)^2)
    Complete("item2 <- t1@", TRUE)
    
    ## A namespace
	Complete("utils::")
	
	## A partial identifier
    Complete("item3 <- va", TRUE)
    
    ## Otherwise, a list with the content of .GlobalEnv
    Complete("item4 <- ")
}
\keyword{ utilities }

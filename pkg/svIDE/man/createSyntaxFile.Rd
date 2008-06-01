\name{createSyntaxFile}
\alias{createSyntaxFile}
\alias{createCallTipFile}

\title{ Create a syntax definition or a calltip file for R language }
\description{
  A .svl syntax file describes the syntax of the language for SciViews GUIs.
  It is used mainly for syntax coloring of text in editors.
  The calltip file (by default, Rcalltips.txt) is a database with formal calls
  of R functions, to be used by code editors to display function calltips.
}
\usage{
createSyntaxFile(svlfile = "R.svl", pos = 2:length(search()))
createCallTipFile(file = "Rcalltips.txt", pos = 2:length(search()),
    field.sep = "=", only.args = FALSE, return.location = FALSE)
}

\arguments{
  \item{svlfile}{ The name or location of the .svl file you want to create }
  \item{file}{ The name or location of the calltip file you want to create }
  \item{pos}{ A vector of integers indicating which positions in the search path should be recorded in the file }
  \item{field.sep}{ The field separator to use between the function name and its calltip in the file }
  \item{only.args}{ Do we record the full calltip (\code{myfun(arg1, arg2 = TRUE, ...)}), or only the function arguments (\code{arg1, arg2, ...}) }
  \item{return.location}{ When \code{TRUE}, the package where this function is located in returned between square brackets at the end of the line }
}
\value{
  These functions return nothing. They are invoked for their side effects of creating a file.
}
\author{ Philippe Grosjean <phgrosjean@sciviews.org> }
\note{ SciViews-R uses a file named 'R.svl' and located in <SciViewsDir>/bin/languages.
  This function generates such a file. Do resist to the temptation to generate a
  very long list of keywords by loading many packages. SciViews cannot handle a
  list longer that 32k, that is roughly, 2000 - 2500 keywords.
  
  \code{createCallTipFile()} sometimes issues warnings because it cannot get arguments
    from some keywords. You can ignore these warnings.
}

\seealso{ \code{\link{getFunctions}}, \code{\link{getKeywords}} }
\examples{
  \dontrun{
    # Create a syntax highlighting file for all currently loaded R packages
    createSyntaxFile("Rtemp.svl")
    # Show and delete it
    file.show("Rtemp.svl", delete.file = TRUE)
    
    # Create a calltips file for all currently loaded R packages
    createCallTipFile("Rtemp.ctip", return.location = TRUE)
    # Show and delete it
    file.show("Rtemp.ctip", delete.file = TRUE)
    
    # You can also customize the calltip file and select the package
    # Here we include only functions from base package (the last item
    # in the search path)
    createCallTipFile("Rtemp2.ctip", pos = length(search()),
        field.sep = ";", only.args = TRUE)
    # Show and delete it
    file.show("Rtemp2.ctip", delete.file = TRUE)
  }

}
\keyword{ utilities }

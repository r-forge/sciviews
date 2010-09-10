\name{Complete}
\alias{Complete}

\title{ Get a completion list for a R code fragment }
\description{
  Returns names of objects/arguments/namespaces matching a code fragment.
}
\usage{
Complete(code, print = FALSE, types = c("default", "scintilla"),
    addition = FALSE, skip.used.args = TRUE, sep = "\n", type.sep = "?")
}
\arguments{
  \item{code}{ a partial R code to be completed. }
  \item{print}{ logical, print result and return invisibly. See details. }
  \item{types}{ a named list giving names of types. Set to \code{NA} to give
    only names. See details. }
  \item{addition}{ should only addition string be returned? }
  \item{skip.used.args}{ logical, in case if completion is within function
    arguments, should the already used named arguments be omitted? }
  \item{sep}{ the separator to use between returned items. }
  \item{type.sep}{ character string to separate types from names. }
}

\value{
If \code{types} == \code{NA}, a character vector giving the completions,
otherwise a data frame with two columns: "completion", and "type" (factor with
levels given by \code{types} argument).\cr
Attributes:\cr
\code{attr(,"token")} - a completed token.\cr
\code{attr(,"triggerPos")} - number of already typed characters.\cr
\code{attr(,"fguess")} - name of guessed function.\cr
\code{attr(,"isFirstArg")} - is this a first argument?
}

\details{
  This function is deprecated in favor of \code{completion()}. It will
  disappear in version 1.0 of the svMisc package!
  
  The completion list is context-dependent, and it is calculated as if the
  code was entered at the command line.

  If the code ends with \code{$} or \code{[[}, then the function look for
  items in a list or data.frame whose name is the last identifier.

  If the code ends with \code{@}, then the function look for slots of the
  corresponding S4 object.

  If the code ends with \code{::}, then it looks for objects in a namespace.

  If the code ends with a partial identifier name, the function returns all
  visible matching keywords.

  If the code is empty or parses into an empty last token, the list of objects
  currently in the global environment is returned. Take care: depending on the
  context, this could be incorrect (but it should work for code entered or
  sourced at the command line).

  There are other situations where the completion can be calculated, see
  the help of \code{rc.settings()}.

  If \code{print} == \code{TRUE}, results are returned invisibly, and printed
  in a form: triggerPos[newline]completions separated by \code{sep}.\cr

  If \code{types} are supplied, a completion will consist of name and type,
  separated by \code{type.sep}. \code{types} may me a vector of length 5,
  giving the type codes for "function", "variable", "environment", "argument"
  and "keyword". If \code{types == "default"}, above type names are given;
  \code{types == "scintilla"} will give numeric codes that can be used
  with "scintilla.autoCShow" function (SciViews-K Komodo Edit plugin).
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> & Kamil Barton }

\seealso{ \code{\link{completion}}, \code{\link{CallTip}} }

\keyword{ utilities }

\concept{ Graphical user interface (GUI) control, completion }

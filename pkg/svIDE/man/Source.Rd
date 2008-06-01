\name{Source}
\alias{Source}

\title{ Source R code, capture its output and convert it in a different format }

\description{
  \code{Source()} is like \code{source()}, but it allows to rework the output
  (for instance to print it in HTML format).
}

\usage{
Source(file, out.form = getOption("R.output.format"), local = FALSE,
    echo = FALSE, print.eval = TRUE, verbose = getOption("verbose"),
    prompt.echo = getOption("prompt"), max.deparse.length = 150,
    chdir = FALSE, prompt = FALSE)
}

\arguments{
  \item{file}{ a connection or a character string giving the name of the file or
    URL to read from. }
  \item{out.form}{ a string indicating which output format to use (for instance,
    "html"). }
  \item{local}{ if 'local' is 'FALSE', the statements scanned are evaluated in
    the user's workspace (the global environment), otherwise
    in the environment calling 'source'. }
  \item{echo}{ logical; if 'TRUE', each expression is printed after parsing,
    before evaluation.}
  \item{print.eval}{ logical; if 'TRUE', the result of 'eval(i)' is printed for
    each expression 'i'; defaults to 'echo'. }
  \item{verbose}{ if 'TRUE', more diagnostics (than just 'echo = TRUE') are
    printed during parsing and evaluation of input, including extra info for
	each expression.}
  \item{prompt.echo}{ character; gives the prompt to be used if 'echo = TRUE'. }
  \item{max.deparse.length}{ integer; is used only if 'echo' is 'TRUE' and gives
    the maximal length of the "echo" of a single expression. }
  \item{chdir}{ logical; if 'TRUE', the R working directory is changed to the
    directory containing 'file' for evaluating }
  \item{prompt}{ should a prompt be printed at the end of the evaluation return? }
}

\details{
  This function is usually called by functions that processes commands send by
  GUI clients.
}

\value{
  The formatted output is returned invisibly.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org}), after code written
  by Tom Short}

\seealso{ \code{\link[base]{source}} }

\keyword{ utilities }


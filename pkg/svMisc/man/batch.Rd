\name{batch}
\alias{batch}

\title{ Run a function in batch mode }
\description{
  A function can be run in batch mode if it never fails (replace errors by
  warnings) and return \code{TRUE} in case of success, or \code{FALSE}
  otherwise.
}

\usage{
batch(items, fun, ..., show.progress = !isAqua() && !isJGR(),
    suppress.messages = show.progress, verbose = TRUE)
}

\arguments{
  \item{items}{ the items (usually, arguments vector of character strings) on
    which to apply \code{fun} sequentially. }
  \item{fun}{ the function to run (must return \code{TRUE} or \code{FALSE} and
    issue only warnings and messages to be a good candidate, batchable, function). }
  \item{\dots}{ further arguments to pass the \code{fun}. }
  \item{show.progress}{ do we show progression as item x on y... message? This
    uses the \code{progress()} function. }
  \item{suppress.messages}{ are messages from the batcheable function suppressed?
    Only warnings will be issued. Recommended if \code{show.progress = TRUE}. }
  \item{verbose}{ display start and end messages if \code{TRUE} (default). }
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{\code{\link{progress}}}

\examples{
## Here is a fake batcheable process
fakeProc <- function (file) {
    message("Processing ", file, "...")
    flush.console()
    Sys.sleep(0.5)
    if (runif(1) > 0.7) { # Fails
        warning("fakeProc was unable to process ", file)
        return(invisible(FALSE))
    } else return(invisible(TRUE))
}

## Run it in batch mode on five items
files <- paste("file", 1:5, sep = "")
batch(files, fakeProc)
}

\keyword{ utilities }

\concept{ batch processing }

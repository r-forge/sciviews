\name{bibRNews}
\alias{bibRNews}
\docType{data}

\title{ A list of papers that where published in R News }
\description{
  List all publications in R News (note: it is now replaced by the R Journal).
}

\usage{data(bibRNews)}

\format{
  A data frame with 205 entries on the following 10 variables
  \describe{
    \item{\code{author}}{ the author(s) of the paper. }
    \item{\code{title}}{ the title of the paper. }
    \item{\code{journal}}{ this is always R News in this case. }
    \item{\code{year}}{ the year of publication. }
    \item{\code{volume}}{ the journal volume. }
    \item{\code{number}}{ the journal number in this volume. }
    \item{\code{pages}}{ pages for this paper. }
    \item{\code{month}}{ the month of publication of this volume. }
    \item{\code{url}}{ a link to the downloadable PDF version. }
    \item{\code{issue}}{ volume/number - year, month. }
  }
}

\references{
  Writing R extensions
}

\seealso{ \code{\link{searchBiblio}} }

\examples{
  (data(bibRNews))
}

\keyword{datasets}

\concept{ BibTeX bibliography, R News }

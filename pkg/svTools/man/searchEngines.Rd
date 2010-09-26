\name{searchEngines}
\alias{searchBiblio}
\alias{searchGraph}
\alias{searchMailing}
\alias{searchPackage}
\alias{searchWiki}
\alias{browse}
\alias{browse.search}
\alias{print.search}

\title{ Various search engines for R documents }

\description{
  Documentation about R is widespread and not always easy to find. These
  functions look for documents in various places.
}

\usage{
searchBiblio(query, max = 30, url = "http://journal.r-project.org/RJournal.bib",
    add.bibRNews = TRUE, \dots)
searchMailing(query, max = 30, groups = "*", prefix = "gmane.comp.lang.r")
searchGraph(query, max = 30)
searchPackage(query, max = 30)
searchWiki(query, max = 30)

\S3method{print}{search}(x, detailed = TRUE, \dots)
browse(object, \dots)
\S3method{browse}{search}(object, item = 1, \dots)
}

\arguments{
  \item{query}{ one or several topics to search for. }
  \item{max}{ maximum number of items to return. }
  \item{url}{ the url from where the BibTeX file describing R Jounal
    articles can be downloaded. }
  \item{add.bibRNews}{ also add data for R News (local cached version)? }
  \item{\dots}{ further arguments passed to the function or method. }
  \item{groups}{ the mailing lists and newsgroups sections to search. }
  \item{prefix}{ the gmane tree for the discussion archives. }
  \item{x}{ a 'search' object. }
  \item{detailed}{ do we print a detailled list of found items? }
  \item{object}{ a 'search' object. }
  \item{item}{ the index of the found item to browse. }
}

\value{
  All the \code{searchXXX()} functions return a 'search' object that inherits
  from 'data.frame'. It contains the 'type' or search, the 'item' found, the
  'page' in the item, a 'snippet' of the relevant text, a 'score' for this hit
  and the 'url' where the containt can be obtained.
  
  The \code{print()} method presents the results in a more readable way, and one
  can \code{browse()} one item in the list.
}

\author{ Romain Francois <francoisromain@free.fr> }

\seealso{ \code{\link{bibRNews}}, \code{\link[utils]{RSiteSearch}} }

\examples{
\dontrun{
searchBiblio("mean")
searchMailing("mean")
searchGraph("mean")
searchPackage("mean")
(res <- searchWiki("mean"))
browse(res, 1)  # Display the first item
rm(res)
}
}

\keyword{ utilities }

\concept{ search R documents on the Internet }

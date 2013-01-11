\name{header}
\alias{header}

\title{ Create a svDoc header to be processed with Asciidoc }
\description{
  SciViews docs have a couple of obligatory first lines. After one line
  specifying how to process the document if it is made executables
  (\code{#! /usr/bin/Rscript -e svDoc::render...}), one must call
  \code{Rdoc()} to create a correct header to be processed by Asciidoc and
  Sweave. Usually, you follow this instruction by \code{require(SciViews)},
  which you need to deal with doc chunks (\code{!!"... !<<>>="}), and you start
  then the document with a doc chunk (usually with the abstract). See example.
}

\usage{
header(title, author = NULL, email = NULL, revnumber = NULL, revdate = NULL,
    revremark = NULL, copyright = "cc-by", encoding = "UTF-8", lang = "en",
    pagetitle = NULL, description = "SciViews Rdoc", keywords = NULL,
    theme = "SciViews", max.width = 640, width = NULL,
    toc = c("top", "side", "manual", "none"), toc.title = NULL, toclevels = 2,
    numbered = TRUE, data.uri = TRUE, frame = "topbot", grid = "rows",
    align = "center", halign = "center", pygments = FALSE, slidefontsizeadjust = 0,
    SweaveInit = { options(width = 80); options(SweaveHooks = list(fig = function()
        par(col.lab = "#434366", col.main = "#434366"))) }
)
}

\arguments{
  \item{title}{ a character string with the title of your SciViews doc. If you
    want a document with no title, indicate \code{NULL} }
  \item{author}{ a character string with the name of the author. You can specify
    first [middle] [last], and each item cannot contain spaces (replace them
    by underscores _). Optional (use \code{NULL} for no authors displayed) }
  \item{email}{ a character string with a valid email address. Optional (use
    \code{NULL} for no email to be displayed). Note also that, if author is not
    provided, email will never be displayed. }
  \item{revnumber}{ a character string with the revision number of your SciViews
    doc. If \code{NULL}, it is omitted. }
  \item{revdate}{ a character string with the revision date of your SciViews
    doc. It must be Month Year format, e.g., \code{January 2013}. From a Date
    object, you got the right format using \code{format(myDate, format = '\%B \%Y')}.
    If \code{NULL}, current date is used. }
  \item{revremark}{ a character string with one or more sentences describing the
    current revision. If \code{NULL}, it is omitted. }
  \item{copyright}{ a character string with either a complete copyright like
    cc-by, John Does, 2013, or just the first part (cc-by) and the author and
    year will be appended automatically. If \code{NULL}, it is omitted. }
  \item{encoding}{ a character string with the encoding of your SciViews doc.
    It is not advised to change from the default, UTF-8. Make sure you save
    your document in UTF-8 encoding before you process it! }
  \item{lang}{ the (main) language used in your SciViews doc. By default, it is
    English (en), but Asciidoc can also use de, el, es, fr, hu, it, nl, pt, ru
    or uk. }
  \item{pagetitle}{ a character string with the title that should appear in the
    browser's tab. If \code{NULL}, it is the same one as the Rdoc title. }
  \item{description}{ a character string with the description of the document
    to use in the head section of the HTML document. If \code{NULL}, it is
    omitted. }
  \item{keywords}{ a character string with one or more keywords to use in the
    head section of the HTML document. If \code{NULL}, it is omitted. } 
  \item{theme}{ the theme to use with the Asciidoc HTML file. By default, it is
    \code{"SciViews"}. }
  \item{max.width}{ the maximum width of the page, in pixels or in percent.
    If \code{NULL}, it is omited. }
  \item{width}{ the width of the page, in pixels or in percent. If \code{NULL},
    it is omited. }
  \item{toc}{ should a table of contents be generated? With \code{"top"}, it is
    automatically placed at the top of the document, with \code{"side"}, it is
    placed at left (unless otherwise specified in the CSS style). With
    \code{"manual"}, it is generated but not placed automatically. Use
    \code{toc::[]} on one line in a doc chunk to indicate where to place it.
    Finally, with \code{"none"}, the tabel of contents is not generated. }
  \item{toc.title}{ the title of your table of contents. If \code{NULL}, the
    default (Table of Contents, or its translation in the main language of the
    SciViews Rdoc) is used. }
  \item{toclevels}{ how deep in title levels should the table of contents be
    generated (1, 2, 3 or 4)? By default, it is 2. }
  \item{numbered}{ should the titles be numbered (\code{TRUE}, by default), or
    not (\code{FALSE})? }
  \item{data.uri}{ should figures, scripts and styles be embedded in the main
    HTML document, using data-uri fields (\code{TRUE} by default)? }
  \item{frame}{ frames to draw for tables. By default (\code{"topbot"}) at the
    top and the bottom of the table. }
  \item{grid}{ which grid should be drawn for tables. By default (\code{"rows"}),
    only row grid lines are drawn. }
  \item{align}{ default alignment of figures and whole tables (\code{"center"}
    by default). }
  \item{halign}{ horizontal alignment of text inside table cells (\code{"center"},
    by default). }
  \item{pygments}{ should pygments be used for syntax highlighting of code?
    \code{FALSE} by default. }
  \item{slidefontsizeadjust}{ adjustment of font size in slidy and slidy2
    documents. }
  \item{SweaveInit}{ code to be run in the init code chunk, related to sweave.
    Reasonable defaults are provided. See ?sweave. }
}

\value{
  The header is returned invisibly.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{RdocToRnw}} }

\examples{
## A minimal svDoc contained in a string:
## TODO...
}

\keyword{ utilities }

\concept{ Literate programming, weaving, tangling Asciidoc files }

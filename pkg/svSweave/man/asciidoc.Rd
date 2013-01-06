\name{asciidoc}
\alias{RdocToRnw}
\alias{RdocConvert}
\alias{RdocThemes}
\alias{makeRdoc}

\title{ Transform SciViews Rdocs into R noweb or HTML files }
\description{
  SciViews Rdocs are R-compatible scripts that embed Sweave code and doc
  blocks to format text between R chunks. These functions convert such scripts
  into R noweb files that can be processed by Sweave, or in the case of
  Asciidoc version, into HTML files after running Sweave and Asciidoc.
}

\usage{
RdocToRnw(RdocFile, RnwFile, encoding)
RdocConvert(RdocFile, theme, format, show.it, figs.dir, keep.RnwFile,
    keep.TxtFile, encoding, asciidoc)
RdocThemes()
makeRdoc(RdocFile, encoding)
}

\arguments{
  \item{RdocFile}{ a character string corresponding to the path to a SciViews
    Rdoc file to be converted. }
  \item{RnwFile}{ idem, but the R noweb file to create. Default to same file,
    but with \code{.Rnw} extension. }
  \item{encoding}{ the encoding of the .R and .Rnw files. It is \code{UTF-8} by
    default, but you can change it here. }
  \item{theme}{ the theme to use with the Asciidoc HTML file. By default, it is
    \code{sciviews}. }
  \item{format}{ export format to use. Either \code{"html"} (default, synonym of
    \code{"html11"}), \code{"html4"}, \code{"html5"}, \code{"slidy"},
    \code{"wordpress"}, \code{"docbook"}, \code{"docbook45"}, or \code{"latex"}
    (see the AsciiDoc man page). }
  \item{show.it}{ is the resulting HTML file shown in the default browser.
    Default value depends if R is run interactively or not. }
  \item{figs.dir}{ subdirectory where to place figures (R plots) when compiling
    Sweave files. Default is \code{"figures"}. Just check that the directory
    exists (otherwise, Sweave fails to produce the plots). }
  \item{keep.RnwFile}{ is the generated R noweb file kept at the end? }
  \item{keep.TxtFile}{ is the generated Asciidoc \code{.txt} file kept at the
    end? }
  \item{asciidoc}{ path to the asciidoc Python script; By default, the version
    included in this package is used. }
}

\value{
  The text of the R noweb data is returned invisibly by \code{RdocToRnw()}.
  \code{NULL} is returned by \code{RdocConvert()} (this function is invoked for
  its side effect. \code{RdocThemes()} returns the list of themes
  available for your HTML documents. Finally, \code{makeRdoc()} is a convenient
  function to automatically build a report from a SciViews Rdoc.
}

\details{
  Python version 2.4 or higher is required to run the Asciidoc compilation
  files.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{RdocHeader}} }

\keyword{ utilities }

\concept{ Literate programming, weaving, tangling Asciidoc files }

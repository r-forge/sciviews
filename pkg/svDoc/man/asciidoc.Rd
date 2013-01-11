\name{asciidoc}
\alias{svDocToRnw}
\alias{svDocConvert}
\alias{svDocThemes}
\alias{render...}

\title{ Transform SciViews docs into R noweb or HTML files }
\description{
  SciViews docs are R-compatible scripts that embed Sweave code and doc
  blocks to format text between R chunks. These functions convert such scripts
  into R noweb files that can be processed by Sweave, or in the case of
  Asciidoc version, into HTML files after running Sweave and Asciidoc.
}

\usage{
svDocToRnw(svDocFile, RnwFile, encoding)
svDocConvert(svDocFile, theme, format, show.it, figs.dir, keep.RnwFile,
    keep.TxtFile, encoding, asciidoc)
svDocThemes()
render...(svDocFile, encoding)
}

\arguments{
  \item{svDocFile}{ a character string corresponding to the path to a SciViews
    doc file to be converted. }
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
  The text of the R noweb data is returned invisibly by \code{svDocToRnw()}.
  \code{NULL} is returned by \code{svDocConvert()} (this function is invoked for
  its side effect). \code{svDocThemes()} returns the list of themes
  available for your HTML documents. Finally, \code{render...()} is a convenient
  function to automatically build a SciViews document.
}

\details{
  Python version 2.4 or higher is required to run the Asciidoc compilation
  files.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{header}} }

\keyword{ utilities }

\concept{ Literate programming, weaving, tangling Asciidoc files }

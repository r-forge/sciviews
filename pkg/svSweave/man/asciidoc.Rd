\name{asciidoc}
\alias{RasciidocToRnw}
\alias{RasciidocToHtml}
\alias{RasciidocThemes}
\alias{svBuild}

\title{ Transform SciViews R scripts into R noweb or HTML files }
\description{
  SciViews R scripts are R-compatible scripts that embed Sweave code and doc
  blocks to format text between R chunks. These functions convert such scripts
  into R noweb files that can be processed by Sweave, or in the case of
  Asciidoc version, into HTML files after running Sweave and Asciidoc.
}

\usage{
RasciidocToRnw(Rfile, RnwFile, encoding)
RasciidocToHtml(Rfile, theme, show.it, figsDir, keepRnwFile, keepTxtFile, encoding, asciidoc)
RasciidocThemes()
svBuild(Rfile, encoding)
}

\arguments{
  \item{Rfile}{ a character string corresponding to the path to a SciViews R
    script file to be converted. }
  \item{RnwFile}{ idem, but the R noweb file to create. Default to same file, but
    with \code{.Rnw} extension. }
  \item{encoding}{ the encoding of the .R and .Rnw files. It is \code{UTF-8} by
    default, but you can change it here. }
  \item{theme}{ the theme to use with the Asciidoc HTML file. By default, it is
    \code{sciviews}. }
  \item{show.it}{ is the resulting HTML file shown in the default browser.
    Default value depends if R is run interactively or not. }
  \item{figsDir}{ subdirectory where to place figures (R plots) when compiling
    Sweave files. Default is \code{"figures"}. Just check that the directory
    exists (otherwise, Sweave fails to produce the plots). }
  \item{keepRnwFile}{ is the generated R noweb file kept at the end? }
  \item{keepTxtFile}{ is the generated Asciidoc \code{.txt} file kept at the end? }
  \item{asciidoc}{ path to the asciidoc Python script; By default, the version
    included in this package is used. }
}

\value{
  The text of the R noweb data is returned invisibly by \code{RasciidocToRnw()}.
  \code{NULL} is returned by \code{RasciidocToHtml()} (this function is invoked for
  its side effect. \code{RasciidocThemes()} returns the list of themes
  available for your HTML documents. Finally, \code{svBuild()} is a convenient
  function to automatically build a report from a SciViews R script.
}

\details{
  Python version 2.4 or higher is required to run the Asciidoc compilation
  files.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\keyword{ utilities }

\concept{ Literate programming, weaving, tangling Asciidoc files }

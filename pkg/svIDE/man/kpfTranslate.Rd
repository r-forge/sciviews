\name{kpfTranslate}
\alias{kpf2pot}
\alias{kpz2pot}
\alias{kpfTranslate}
\alias{kpzTranslate}

\title{
  Create a POT file or use a PO file to allow translating Komodo project
  (.kpf) or package (.kpz)
}

\description{
  Komodo Edit/IDE (code editor programs) use projects and packages for easy
  customization. However, these projects/packages are static elements that do
  not allow to use translation facilites easily. The \code{kpX2pot()} and
  \code{kpXTranslate()} functions provide a mechanism to use poEdit (a program
  designed to translate strings for software) to ease and automatise translation
  of such Komodo projets/packages (see details section for the procedure).
}

\usage{
kpf2pot(kpfFile, potFile)
kpz2pot(kpzFile, potFile)
kpfTranslate(kpfFile, langs, poFiles, kpf2Files)
kpzTranslate(kpzFile, langs, poFiles, kpz2Files)
}

\arguments{
  \item{kpfFile}{ A Komodo project file with a .kpf extension to be translated }
  \item{kpzFile}{ A Komodo package file with a .kpz extension to be translated }
  \item{potFile}{ The name of a .pot file providing strings to be translated,
    if not provided, it is the same name as the .kpf/.kpz file, but with a .pot
    extension instead }
  \item{langs}{ The language(s) to translate to, for instance, 'fr' for French,
    'de' for German, 'it' for Italian, 'en_GB' for Great Britain's English,
    etc. }
  \item{poFiles}{ The path to the .po files containing the translations. If not
    provided, it is assumed to be the basename of the .kpf/.kpz file without
    extension, plus '-', plus langs and with a .po extension. For instance, the
    default translation file for \code{myproject.kpf} into French is named
    \code{myproject-fr.po}. }
  \item{kpf2Files}{ The Komodo project files to create with the translations. If
    not provided, it is assumed to be the same as the initial project file, but
    with '-lang' appended to the base name. For instance, the French
    translation of \code{myproject.kpf} would be \code{myproject-fr.kpf} in the
    same directory, by default. }
  \item{kpz2Files}{ Same as kpf2Files, but for Komodo package files with a .kpz
    extension. }
}
\value{
  These functions return invisibly \code{TRUE} if the targetted files are
  created, or \code{FALSE} otherwise. Use \code{any(kpfTranslate("myfile.kpf"))}
  to check that ALL translations are done.
}

\details{ 
  Komodo Edit/IDE are code editor programs that can be used to edit R code
  efficiently with the SciViews-K plugin (see
  http://www.sciviews.org/SciViews-K). Komodo can be customized by using
  projects files (files with a .kpf extension), or tools collected together in
  the toolbox and that can be saved on disk in Komodo package files (with a .kpz
  extension).
  
  Among the tools you can place in a Komodo project or package, there are macros
  (written in JavaScript or Python). Thanks to the SciViews-K plugin, you have
  access to R and R code inside these macros. This makes it a good candidate for
  writing GUI elements, including dialog boxes, on top of your favorite R code
  editor. You can also add 'snippets' in those projects/packages. Snippets are
  short pieces of code, including R code, you can save and retrieve easily. In
  the snippets, you can define replaceable parts, includings parts you replace
  after prompting the user for their values with a dialog box. SciViews uses
  these features extensively, for instance, for the 'R reference' toolbox (a
  kind of electronic reference card for R code).
  
  Unfortunately, these tools do not benefit easily from translation features.
  So, it is hard to maintain the same project/package in different languages.
  The functions provided here ease the maintenance of such projects/packages
  translated in various languages. Here is how you can use them:
  
  1) Save your Komodo project or package on disk (click on the project and use
  context menu to save it, or select all items you want to package in your
  toolbox and also use to context menu to create the package file).
  
  2) Use the \code{kpX2pot()} function to create, or update a .pot file. This
  file lists all translatable strings found in the project/package. Translatable
  strings are: (a) names of tools or folders, (b) items in snippets that are
  flagged with \%ask:R-desc:, \%ask:R-tip:, \%ask:URL-help:, \%ask:RWiki-help:,
  \%pref:URL-help:, \%pref:RWiki-help, and \%tr: (see Komodo help to learn how to
  use these tags in snippets), and (c) strings in JavaScript macros that are
  flagged with \code{_()}. For instance, creating a .pot file for
  \code{~/myproject.kpf} is as simple as calling
  \code{kpf2pot("~/myproject.kpf")}.
  
  3) Use the poEdit program (search Google to find, download and install this
  free Open Source translation utility, if you don't have it yet) to translate
  the extracted strings. The first time, you create a .po file based on the .pot
  template you just created. For subsequent versions of your project/package,
  you reuse the old .po file and select menu entry 'Catalog -> Update from POT
  file...' in poEdit to update your translation file with new strings found in
  the recent .pot file. You are better to place the .po file in the same
  directory as your project/package and to give it the same name, but replacing
  .kpX by -<lang>.po, where <lang> is the language in which you do the
  translation. You can distribute .pot files to a staff of translators that
  would send you back the created/modified .po files for compilation. See the
  poEdit documentation for further help (note that multiline strings and
  singular/plural forms are not supported yet by \code{kpXTranslate()}).
  
  4) Once you have your .po files ready, you can translate your Komodo
  project/package in these languages easily. For instance, a project file
  \code{~/myproject.kpf} can be translated in French, using the .po file
  \code{~/myproject-fr.po} and in Italian using a .po file
  \code{~/myproject-it.po}. To do so, you simply type
  \code{kpfTranslate("~/myproject.kpf")} in R. That produces a
  \code{~/myproject-fr.kpf} file that contains your Komodo project translated in
  French, and a \code{~/myproject-it.kpf} file with your Italian translation.
  Please, note that \code{kpzTranslate()} currently needs to access the external
  \code{zip} program for zipping the .kpz file. This program is usually
  accessible from within Linux or Mac OS X by default, but needs to be installed
  (and made accessible through the PATH) under Windows.
  
  5) To open your translated project/package in Komodo, just drag and drop the
  new file in the central area of the Komodo window, and the project is open in
  the projects tabs at left, or the content of the package is added in you
  toolbox at right, depending on the type of file you use.
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\keyword{ utilities }

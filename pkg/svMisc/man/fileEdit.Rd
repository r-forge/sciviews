\name{fileEdit}
\alias{fileEdit}

\title{ Invoke an external text editor for a file }
\description{
  Edit a text file using an external editor. Possibly wait for the end of the
  program and care about creating the file (from a template) if it does not
  exists yet.
}

\usage{
fileEdit(file, template = NULL, replace = FALSE, wait = FALSE,
    editor = getOption("fileEditor"))
}

\arguments{
  \item{file}{ path to the file to edit. }
  \item{template}{ a file to use as template if \code{file} must be created.
    If \code{NULL}, an empty file is created. }
  \item{replace}{ force replacement of \code{file} if \code{template} is not null. }
  \item{wait}{ wait for edition to complete. }
  \item{editor}{ editor to use. Either the name of the program, or a string
    containing the command to run, using \%s as replacement tag where to place
    the filename in the command. }
}

\value{
  The function returns \code{TRUE} if it was able to edit the file or
  \code{FALSE} otherwise, invisibly.
}

\note{
  The default editor program, or the command to run is in the \code{fileEditor}
  option (use \code{getOption("fileEditor")} to retrieve it, and
  \code{options(fileEditor = "<myowneditor>")} to change it). Default values are
  determined automatically.
  
  On Unixes, "gedit", "kate" and "vi" are looked for in that order. Note that
  there is a gedit plugin to submit code directly to R:
  \url{http://rgedit.sourceforge.net/}. Since, gedit natively supports a lot
  of different syntax highlighting, including R, and is lightweight but feature
  rich, it is recommended as default text editor for \code{fileEdit()} on Unixes.
  
  On Mac OS X, if the "edit" program exists, it is used (it is the command line
  program installed by TextWrangler or BBEdit, see
  \url{http://www.barebones.com/products/}, much more capables text editors
  than the default TextEdit program), otherwise, the default text editor used
  by OS X is choosen (default usually to TextEdit). TextWrangler can be
  installed freely. It can be configured to highlight and submit R code. see
  \url{http://macsci.jelmerborst.nl/files/textwrangler_and_r.php} for
  instructions. It features also several tools that makes it a much better
  choice than TextEdit for \code{fileEdit()} on Mac OS X.
  
  On Windows, if Notepad++ is installed in its default location, it is used,
  otherwise, the default "notepad.exe" is used. Notepad++ is a free text editor
  that is much better suited to edit code or text files that the default
  Windows' notepad application, in particular because it can handle various line
  end types (Unix, Mac or Windows) and encodings. It also supports syntax
  highlighting, code completion and much more. So, it is strongly recommended to
  install it (see \url{http://notepad-plus-plus.org/}) and use it with
  \code{fileEdit()}. There is also a plugin to submit code to R directly from
  Notepad++: \url{http://sourceforge.net/projects/npptor/}.
  
  Of course, you can use your own text editor, just indicate it in the
  \code{fileEditor} option. Note, however, that you should use only lighweight
  and fast starting programs. Also, for the \code{wait = TRUE} argument of
  \code{fileEdit()}, you must check that R waits for the editor to be closed
  before furter processing code. In some cases, a little command line program is
  used to start a larger application (like Komodo Edit/IDE), or the program
  deleguates to an existing instances and exits immediatelly, even if the file
  is still edited. These programs are not recommended at all for
  \code{fileEdit()}.
  
  If you want to use files that are compatibles between all platforms supported
  by R itself, you should think about using ASCII encoding as much as possible
  and the Windows style of line-ending. That way, you ensure that all the
  default editors will handle those files correctly, including the broken
  default editor on Windows, notepad.exe, which does not understand at all Mac
  or Unix line ends!
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{systemFile}}, \code{\link[base]{file.path}}, \code{\link[base]{file.exists}} }

\examples{
\dontrun{
## Create a template file in the tempdir...
tpl <- tempfile("template", fileext = ".txt")
cat("Example template file\nto be used with fileEdit()\n", file = tpl)

## ... and edit a new file, starting from that template:
newf <- tempfile("test", fileext = ".txt")
fileEdit(newf, template = tpl, wait = TRUE)

## Make sure the content ends with \n, and read it
cat("\n", file = newf, append = TRUE)
cat("Your file contains:\n")
readLines(newf)

## Eliminate both the file and template
unlink(newf)
unlink(tpl)
}
}

\keyword{ utilities }

\concept{ file edition }

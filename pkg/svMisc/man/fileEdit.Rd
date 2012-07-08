\name{fileEdit}
\alias{fileEdit}

\title{ Invoke an external text editor for a file }
\description{
  Edit a text file using an external editor. Possibly wait for the end of the
  program and care about creating the file (from a template) if it does not
  exists yet.
}

\usage{
fileEdit(..., title = files, editor = getOption("fileEditor"), file.encoding = "",
    template = NULL, replace = FALSE, wait = FALSE)
}

\arguments{
  \item{\dots}{ path to one or more files to edit. }
  \item{title}{ the title of the editor window (not honoured by all editors,
    most external editors only display the file name or path). }
  \item{editor}{ editor to use. Either the name of the program, or a string
    containing the command to run, using \%s as replacement tag where to place
    the filename in the command, or a function with 'file', 'title' and 'wait'
    arguments to delegate process of the files. }
  \item{file.encoding}{ encoding of the files. If \code{""} or \code{native.enc},
    the files are considered as being already in the right encoding. }
  \item{template}{ one or more files to use as template if files must be created.
    If \code{NULL}, an empty file is created. This argument is recycled for all
    files to edit. }
  \item{replace}{ force replacement of files if \code{template} is not null. }
  \item{wait}{ wait for edition to complete. If more than one file is edited,
    the program waits sequentially for each file to be edited in turn (with a
    message in the R console). }

}

\value{
  The function returns \code{TRUE} if it was able to edit the files or
  \code{FALSE} otherwise, invisibly. Encountered errors are reported as warnings.
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
  rich, it is recommended as default text editor for \code{fileEdit()} on
  Unixes. If JGR is run and the editor is "vi" or "internal", then the internal
  JGR editor is used, otherwise, the provided editor is chosen.
  
  On Mac OS X, if the "edit" program exists, it is used (it is the command line
  program installed by TextWrangler or BBEdit, see
  \url{http://www.barebones.com/products/}, much more capables text editors
  than the default TextEdit program), otherwise, the default text editor used
  by OS X is choosen (default usually to TextEdit). TextWrangler can be
  installed freely. It can be configured to highlight and submit R code. see
  \url{http://macsci.jelmerborst.nl/files/textwrangler_and_r.php} for
  instructions. It features also several tools that makes it a much better
  choice than TextEdit for \code{fileEdit()} on Mac OS X. Specify "textwrangler"
  or "bbedit" to force using these programs. The default value is "textedit",
  the Mac default text editor, but on R.app, and with \code{wait = FALSE}, the
  internal R.app editor is used instead in that case. If JGR is run, and the
  editor is "textedit", "internal" or "vi", then, the internal JGR editor is
  used instead.
  
  On Windows, if Notepad++ is installed in its default location, it is used,
  otherwise, the default "notepad" is used in Rterm and the internal editors are
  chosen for Rgui. Notepad++ is a free text editor that is much better suited to
  edit code or text files that the default Windows' notepad application, in
  particular because it can handle various line end types (Unix, Mac or Windows)
  and encodings. It also supports syntax highlighting, code completion and much
  more. So, it is strongly recommended to install it (see
  \url{http://notepad-plus-plus.org/}) and use it with \code{fileEdit()}. There
  is also a plugin to submit code to R directly from Notepad++:
  \url{http://sourceforge.net/projects/npptor/}.
  
  Of course, you can use your own text editor, just indicate it in the
  \code{fileEditor} option. Note, however, that you should use only lighweight
  and fast starting programs. Also, for the \code{wait = TRUE} argument of
  \code{fileEdit()}, you must check that R waits for the editor to be closed
  before further processing code. In some cases, a little command line program
  is used to start a larger application (like for Komodo Edit/IDE), or the
  program delegates to an existing instances and exits immediatelly, even if the
  file is still edited. Such editors are not recommended at all for
  \code{fileEdit()}.
  
  If you want to use files that are compatibles between all platforms supported
  by R itself, you should think about using ASCII encoding as much as possible
  and the Windows style of line-ending. That way, you ensure that all the
  default editors will handle those files correctly, including the broken
  default editor on Windows, notepad, which does not understand at all Mac
  or Unix line ends!
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{systemFile}}, \code{\link[base]{file.path}},
  \code{\link[base]{file.exists}}, \code{\link[utils]{file.edit}}  }

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

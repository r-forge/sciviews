\name{Img}
\alias{imgAdd}
\alias{imgDel}
\alias{imgGet}
\alias{imgNames}
\alias{imgType}
\alias{imgRead}
\alias{imgReadPackage}
\alias{print.guiImg}

\title{ Manipulate image resources for the GUIs }
\description{
  Mechanism provided here is very simple and allows for automatic loading of
  image resources from any package subdirectory. Currently, only Tk images
  loaded from GIF files are supported... but more formats could be added in the
  future.
}

\usage{
imgAdd(file, type = "gif", img.type = "tkImage", update = FALSE, \dots)
imgDel(image)
imgGet(image)
imgNames()
imgType(image, warn = TRUE)

imgRead(dir, type = "gif", img.type = "tkImage")
imgReadPackage(package, subdir = "gui", type = "gif", img.type = "tkImage")

\method{print}{guiImg}(x, \dots)
}

\arguments{
  \item{file}{ image file from where to download the resource. }
  \item{type}{ type of image. Currently, only 'gif' is supported. }
  \item{img.type}{ the type of image resource to create. Currently, only
    'tkImage' is supported and it is a Tcl/Tk resource. }
  \item{update}{ do we update an already loaded image resource, or not? }
  \item{image}{ Name of an image. }
  \item{warn}{ do we issue a warning if the type of image is not recognized? }
  \item{dir}{ the directory that contains one or more image files to read. }
  \item{package}{ name of a package from where to load image resources. }
  \item{subdir}{ subdirectory in the package where the graphical resources are
    stored. By default, it is the \"gui\" subdirectory. }
  \item{x}{ an object of class 'guiImg'. }
  \item{\dots}{ further arguments (currently not used). }
}

\details{
  These functions care about (un)loading image resources. A list of these
  resources is maintained in '.guiImgs' located in the \code{SciViews:TempEnv}
  environment.
}

\value{
  \code{imgAdd()} and \code{imgGet()} return the handle to the newly created
    image (invisibly for the \code{imgAdd()}).
  \code{imgDel()} returns invisibly \code{TRUE} if the resource is found and
    deleted, \code{FALSE} otherwise.
  \code{imgNames()} return the list of all images registered in .guiImgs in the
    \code{SciViews:TempEnv} environment.
  \code{imgRead()} and \code{imgReadPackage()} return invisibly the list of
    image files that are imported as resources.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{toolAdd}} }

\examples{
\dontrun{
## These cannot be run by examples() but should be OK when pasted
## into an interactive R session with the tcltk package loaded

imgNames()
myImg <- imgAdd(system.file("gui", "logoSciViews.gif", package = "svWidgets"))
myImg  # Note that $Tk. is prepended to the name!
imgNames()
imgType(myImg)
## Place that logo in a Tk window
timg <- winAdd("timg", title = "A Tk window with image", pos ="-40+20")
labImg <- tklabel(timg, image = imgGet(myImg), bg = "white")
tkpack(labImg)
## When the image resource is deleted, it is not displayed any more (no error)
imgDel(myImg)
imgNames()
winDel("timg")
## To read all image resources at once (place this in .Lib.first())
imgReadPackage("svWidgets")
imgNames()
rm(myImg)
}
}

\keyword{ utilities }

\concept{ GUI image resources }

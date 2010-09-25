\name{tkImg}
\alias{tkImgAdd}
\alias{tkImgDel}
\alias{tkImgRead}

\title{ Manipulate image resources for Tcl/Tk GUIs }
\description{
  These functions read image files on disk and create Tk image resources.
}

\usage{
tkImgAdd(file, type = "gif", update = FALSE)
tkImgDel(image)
tkImgRead(dir, type = "gif")
}

\arguments{
  \item{file}{ image file from where to download the resource. }
  \item{type}{ type of image. Currently, only 'gif' is supported. }
  \item{update}{ do we update an already loaded image resource, or not? }
  \item{image}{ name of an image. }
  \item{dir}{ the directory that contains one or more image files to read. }
}

\details{
  These functions should not be called directly, but by means of
  \code{ImgAdd()}, \code{ImgDel()} or \code{ImgRead()}.
}

\value{
  \code{tkImgAdd()} returns the handle to the newly created image invisibly.
  \code{tkImgDel()} returns invisibly \code{TRUE} if the resource is found and
    deleted, \code{FALSE} otherwise.
  \code{tkImgRead()} returns invisibly the list of image files that are imported
    as resources.
}

\author{ Philippe Grosjean }

\seealso{ \code{\link{ImgAdd}}, \code{\link{ImgDel}}, \code{\link{ImgRead}} }

\keyword{ utilities }

\concept{ GUI image resources in Tcl }

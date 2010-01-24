\name{makeIconGallery}
\alias{makeIconGallery}

\title{ Create galleries of icons for SciViews-K and Komodo }

\description{
  The "pick icon" dialog box of Komodo uses icon galleries. SciViews-K redefines
  such galleries for easier access to the icons, and it supplements about 1800
  additional icons. The present function builds those galleries, based on a list
  of icons manually compiled.
}

\usage{
makeIconGallery(flist)
}

\arguments{
  \item{flist}{ the path to the ASCII text file containing the URIs of the
    different icons to collect together in the gallery. It is supposed to use
	the .txt extension, which is replaced by .html in the gallery file. }
}

\value{
  \code{TRUE} (success) or \code{FALSE} (error) is returned invisibly.
}

\author{Philippe Grosjean (\email{phgrosjean@sciviews.org})}

\keyword{ utilities }
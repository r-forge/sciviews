\name{checkUsageFile}
\Rdversion{1.1}
\alias{checkUsageFile}
\title{
File based version of checkUsage
}
\description{
Simple wrapper to the checkUsage function of the codetools
package that calls checkUsage on all objects contained in a source file
}
\usage{
checkUsageFile(file, encoding = "unknown")
}
\arguments{
  \item{file}{file to check}
  \item{encoding}{encoding to assume for the file}
}
\value{
A data frame of errors/problems in the file is returned
}
\author{
Romain Francois <francoisromain@free.fr>
}
\seealso{
\code{\link[codetools]{checkUsage}}
}
\keyword{ manip }


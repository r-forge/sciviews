\name{namespaceParser}
\Rdversion{1.1}
\alias{namespaceParser}
\title{
NAMESPACE parser 
}
\description{
parses a NAMESPACE file and look for errors
}
\usage{
namespaceParser(NAMESPACE, checkPackages = TRUE)
}
\arguments{
  \item{NAMESPACE}{name of the file}
  \item{checkPackages}{logical; if TRUE, packages that 
  	are set to be imported are checked to be installed}
}
\value{
a data frame that contains errors in the NAMESPACE file
}
\author{
Romain Francois <francoisromain@free.fr>
}
\keyword{manip}


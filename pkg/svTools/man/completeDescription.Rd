\name{completeDescription}
\Rdversion{1.1}
\alias{completeDescription}
\title{
completion helper for DESCRIPTION files
}
\description{
Attemps to find completions for a DESCRIPTION file
}
\usage{
completeDescription(file, row, col, text = readLines(file), 
	author = getOption("svTools.description.author"))
}
\arguments{
  \item{file}{DESCRIPTION file to complete}
  \item{row}{line in the file where the cursor is}
  \item{col}{column in the file where the cursor is}
  \item{text}{text to complete}
  \item{author}{How to complete Author fields. The default value 
  looks for the "svTools.description.author" option }
}
\value{
	A list with the following items
	\item{ok}{logical indicating if there actually are completions}
	\item{data}{character matrix. The first column gives the completion, the second a description}
	\item{token}{token that is being completed}
	\item{type}{type of results, can be "package", "fields", "other" }
}
\references{
Writing R extensions defines what should be in a DESCRIPTION file
}
\author{
Romain Francois <francoisromain@free.fr>
}
\keyword{ manip }


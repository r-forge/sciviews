##    This file is part of sciViews.
##
##    sciViews is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    sciViews is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with sciViews.  If not, see <http://www.gnu.org/licenses/>.
##

makeTestListFromExamples <- function(packageName, manFilesDir) {
  manPageFiles <- list.files(manFilesDir, pattern="\\.Rd$")
  manPages <- sapply(manPageFiles, function(filename) {
    lines <- readLines(paste(manFilesDir, filename, sep="/"))
    lines <- lines[grep("^\\\\name[ ]*\\{(.*)\\}", lines)]
    sub("^\\\\name[ ]*\\{(.*)\\}", lines, replacement="\\1")
  })
  manPages <- manPages[manPages != paste(packageName, "package", sep="-")]

  lapply(manPages, function(x) {
    result <- svTest(function() 
                     tryCatch(withCallingHandlers({ do.call(example, list(topic=x, package=packageName)); checkTrue(TRUE); },
                                                  warning=function(w) { checkIdentical(NULL, w) }),
                              error=function(w) checkIdentical(NULL, w)))
    attr(result, 'unit') <- 'examples'
    result
  })
}

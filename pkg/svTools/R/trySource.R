
#' Try to source a script file and returns a structured error if it fails
#' @export
#' @param file A connection to source  
#' @return A structured error (see \link{parseError} ) if the file cannot be sourced
#' @author Romain Francois \email{francoisromain@@free.fr}
trySource <- function(file){
  out <- try( source(file) , silent = TRUE)
  if( out %of% "try-error") parseError( out )  
}


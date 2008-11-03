#' Reset the errors
#' 
#' Removes errors concerning a file or a set of files from the list of errors
#' @export
#' @param file file for which errors should be removed
#' @param pattern Files matching this regular expression will be removed from the error list. 
#' The macthing is performed on the \code{\link{basename}} of the file	 
#' @return Nothing, only used for its side effect
#' @author Romain Francois \email{francoisromain@@free.fr}
resetErrors <- function( file = NULL, pattern = NULL ){
	if( !is.null(file) ){
		svTools.env$.errors <- svTools.env$.errors[ ! svTools.env$.errors$file %in% sapply( file, tools:::file_path_as_absolute ) , , drop = FALSE]
	} else if( !is.null(pattern) && any( basename( svTools.env$.errors$file ) %~% pattern) ){
		svTools.env$.errors <- svTools.env$.errors[ svTools.env$.errors$file %!~% pattern , , drop = FALSE]
	} else{ 
		svTools.env$.errors <- emptyError( )
	}
	invisible( NULL )
}

#' Add an error to the list of errors
#' 
#' Adds an error to the list of errors
#' @export
#' @param file file in which the error is observed. 
#' (this argument can also be a structured error, see \code{\link{parseError}} in which case all other arguments are ignored )
#' @param line line of the file n which the error happens 
#' @param message error message
#' @param type type of error (typically error or warning)
#' @return Nothing. Only used for side effects
#' @author Romain Francois \email{francoisromain@@free.fr}
addError <- function( file, line=1, message="", type = "error" ){
  d <- if( file %of% "data.frame" && all( c("file", "line", "message", "type") %in% colnames( file) ) ){
		file
	} else{
		data.frame( file = tools:::file_path_as_absolute(file), line = line, 
			message = message, type = type, stringsAsFactors = FALSE)
  }
	svTools.env$.errors <- rbind( svTools.env$.errors, d )
}

#' retrieve errors stored in the error list
#' 
#' Facility to retrieve the errors stored in the error list
#' @export
#' @param file if specified, only errors about this file will be returned
#' @param pattern if specified, only errors of files matching the pattern will be returned
#' @return A data frame with columns file, line, message and type
#' @author Romain Francois \email{francoisromain@@free.fr}
getErrors <- function( file = NULL , pattern = NULL){
	out <- svTools.env$.errors
	if( ! is.null( pattern) && any( out$file %~% pattern) ) {
		out <- out[ basename( out$file ) %~% pattern, ]
	}
	if( ! is.null(file) ){
		out <- out[ out$file == tools:::file_path_as_absolute(file) , ]
	}
	if( nrow( out ) ) {
		out <- out[ order( out$file, out$line) , ]
		out$line <- as.integer( out$line )
	} else emptyError() 
}

#' Creates an empty structured error
#' 
#' Creates an empty structured error, a data frame with all the columns needed for the
#' structured errors, but with no lines
#' @export
#' @return A data frame with columns file, message, type and line
#' @author Romain Francois \email{francoisromain@@free.fr}	
emptyError <- function(){
	data.frame( file = character(0), line = integer(0), message = character(0), 
		type = character(0), stringsAsFactors = FALSE)
}


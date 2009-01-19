read.INDEX <- function( file ){
  
	EMPTY <- data.frame( index= character(), description=character(), stringsAsFactors=FALSE)
	if( !file.exists(file ) ){
		return( EMPTY )
	}
	rl <- readLines( file ) 
	if( !length( rl ) ){
		return( EMPTY )
	}
	lines <- rl %~% "^ "
	index <- rl[!lines] %-~% " +.*$"
  description <- rl[!lines] %-~% "^.*? +"
  data.frame( index = index, description = description, stringsAsFactors = FALSE)
}


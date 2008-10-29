
rdparse <- function( file ){
	rdfile <- readLines( file )
	index <- cumsum( rdfile %~% "^\\\\[[:alpha:]]" )
	
	chunks <- lapply( unique( index ) , function(i) rdfile[index==i] )
	names. <- sapply( chunks, function(x) x[1] %-~% "(^\\\\|{.*$)"  )
	
	cs <- cumsum( c(0, nchar( rdfile ) )  )
	offset.start <- cs[ sapply( 1:max(index), function(i) which(index==i)[1] ) ]
	offset.end   <- cs[ 1 + sapply( 1:max(index), function(i) tail( which(index==i), 1 ) ) ]
	
	list( offset.start = offset.start, 
	  offset.end = offset.end, 
		chunks = chunks, names= names. )
}



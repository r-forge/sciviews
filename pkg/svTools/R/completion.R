
CompletePlusWrap <- function( ... ){
	out <- CompletePlus( ..., minlength = 1 )
	if( is.null(out) ){
		out <- matrix( "", nc = 4, nr = 0 ) 
	}else{
		types <- rep( "function" , nrow(out ) )
		completions <- out[,1]
		types[ completions %~% "= *$" ] <- "argument"
		types[ completions %~% ":: *$" ] <- "package"
		# arguments first, then functions, then packages
		out <- cbind( out, types )	[ order(types),, drop = FALSE ]
	}
	token <- utils:::.guessTokenFromLine( )
	fun <- utils:::inFunction()
  if(length(fun) && !is.na(fun)){
    tooltip <- CallTip( fun )
  } else {
    tooltip <- NULL
    fun <- ""
  }
	
	list( data = out, token = token,  
	  fun = fun, tooltip = tooltip )
}

pchComplete <- function( line ){
	allPch <- 1:25
	if( line %~% "pch *= *[^,)]*$" ){
		start <- line %-~% "^.*= *"
		if( start %!~% "^ *[0-9]+ *$" ){ 
			completions <- allPch
		} else{
			int <- try(as.integer(start), silent = TRUE)
			if( int %of% "try-error" ) 	completions <- allPch
			out <- as.integer( grep( start, allPch, value = TRUE ) )
			completions <- if( length(out ) ) out else allPch
		}
		return( list( completions = completions, token = start ) )
	}
}

colComplete <- function( line ){
	
	token <- sub( "^.*=[[:space:]]*", "", line )
	start <- token %-~% "[[:space:]]+" 
	
	if( start %~% "['\"]" ){
		### look at named colors
		start <- start %-~% "['\"]"
		
		cols <- ( allColors <- colors() ) %~|% start
		if( !length( cols ) ) cols <- allColors
		rgb <- t( col2rgb( cols ) )
		cols <- paste( '"', cols, '"', sep = "" )
	} else {
		### look at colors in the palette
		pal <- palette()
		if( nchar(start) ) {
			cols <- 1:length(pal) %~|% start
			if( !length( cols ) ){
				cols <- 1:length(pal)
			} 
		} else cols <- 1:length(pal)
		rgb <- t( col2rgb( pal[cols] ) )
	}
	list( token = token, names = as.character(cols), rgb = rgb )
	
}

ltyComplete <- function( line ){
	
	ltys <- c("blank", "dashed", "solid", "dotted", "longdash", "twodash" )
	
	token <- line %-~% "^.*=[[:space:]]*"
	start <- token %-~% "([[:space:]]+|'|\")" 
	
	matches <- ltys %~|% start
  if( !length( matches ) ) matches <- ltys
	
	list( lty = matches , token = token )
	
}


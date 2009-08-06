
completeDescription <- function( file, row, col, text = readLines(file), 
  author = getOption( "svTools.description.author" ) ){
	
	if( missing(text) ){
	  n <- if( missing(row) ) -1 else row
	  rl <- readLines( file, n = n )
	  row <- length(rl)
	  if(missing(col)) col <- nchar(rl[row])
	} else{
		rl <- text %/~% "\\\n"
		row <- length(rl )
		col <- nchar( rl[row] )
	}
	lastLine <- rl[ row ] <- substring( rl[row], 1, col  )
	
	if( lastLine %~% "^( +|[^:]+:)" ){
		# extract the last field 
		lastField <- tail( which( rl %~% "^[^:]+:" ), 1 )
		field <- rl[ lastField ] %-~% "(:.*$|[[:space:]]+)"
		
		### complete package names 
		if( field %in% c("Depends","Suggests", "Enhances", "Imports") ){
			start <- lastLine %-~% ".*[,[:space:]]"
			packages <- installedPackages( pattern = start )[, c("Package", "Title"), drop = FALSE ]
			return( list( data = packages, token = start, ok = 1, type = "package" ) )
		} 
		
		### use the "svTools.description.author" option to complete
		if( field %in% c("Author", "Maintainer" ) ){
			if( !is.null( author) ){
				return( list( ok = 1, data = cbind( author, "" ), token = lastLine %-~% ".*: *", type = "other"  ) )
			} else return( list( ok = 0 ) )
		} 
		
		### possible licenses
		if( field == "License"){
		  possibleLicenses <- rbind(      
			  c( "GPL-2",         'The "GNU General Public License" version 2          ' ),
				c( "GPL-3",         'The "GNU General Public License" version 3          ' ),
				c( "LGPL-2",        'The "GNU Library General Public License" version 2  ' ),
				c( "LGPL-2.1",      'The "GNU Lesser General Public License" version 2.1 ' ),
		   	c( "LGPL-3",        'The "GNU Lesser General Public License" version 3   ' ),
				c( "AGPL-3",        'The "GNU Affero General Public License" version 3   ' ),
				c( "Artistic-1.0",  'The "Artistic License" version 1.0                  ' ),
				c( "Artistic-2.0",  'The "Artistic License" version 2.0                  ' ) )
			return( list( ok = TRUE, data = possibleLicenses, token = lastLine %-~% ".*: *", type = "other"  ) )
		}        
		
		### propose today's date
		if( field == "Date"){
			data <- cbind( format( Sys.time( ) , "%Y-%m-%d" ), "Today" )
			return( list( ok = TRUE, data = data, token = lastLine %-~% ".*: *" , type = "other" ) )
		}
		
		if( field %in% c("LazyLoad", "LazyData", "ZipData") ){
			data <- rbind( c("yes", ""), c("no", "" ) )
			return( list( ok = TRUE, data = data, token = lastLine %-~% ".*: *" , type = "other" ) )
		}
		
		if( field == "Encoding" ){
			data <- rbind( 
			    c("latin1" , "" ), 
					c("latin2" , "" ), 
					c("UTF-8"  , "" ) )
			return( list( ok = TRUE, data = data, token = lastLine %-~% ".*: *" , type = "other" ) )
		}
		
		if( field == "Type" ){
			data <- rbind( 
			    c("Package"     , "Usual package" ), 
					c("Translation" , "Translation package" ), 
					c("Frontend"    , "Frontend package" ) )
			return( list( ok = TRUE, data = data, token = lastLine %-~% ".*: *" , type = "other" ) )
		}
		
		### give up
		return( list( ok = FALSE ) )
		
 	} else{
		if( lastLine %~% "[^[:alpha:]]" ){
			return( list( ok = FALSE ) )
		} else{
			keep <- descriptionFields[,1] %~% lastLine | descriptionFields[,3] %~% lastLine
			data <- as.matrix( descriptionFields[ keep, c(1, 3), drop = FALSE ] )
			
			data[,1] <- paste( data[,1], ": ", sep = "")
			return( list( data = data, ok = TRUE, token = lastLine, type = "fields" ) )
		}
	}
	
	
}


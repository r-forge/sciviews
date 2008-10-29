
roxygenComplete <- function( line = "#'" ){
	
	roxygenTags <- rbind( 
	  c( "author",              "\\author"                 , "Author of the function" )                                       ,
		c( "aliases",             "\\alias, ..."             , "" )                                                             ,
		c( "concept",             "\\concept"                , "" )                                                             ,
		c( "examples",            "\\examples"               , "" )                                                               ,
		c( "keywords",            "\\keyword, ..."           , "" )                                                           ,
		c( "method",              "\\method"                 , "" )                                                                 ,
		c( "name",                "\\name"                   , "" )                                                                   ,
		c( "note",                "\\note"                   , "" )                                                                   ,
		c( "param",               "\\arguments{\\item, ...}" , "" )                                                 ,
		c( "references",          "\\references"             , "" )                                                             ,
		c( "return",              "\\value"                  , "" )                                                                  ,
		c( "seealso",             "\\seealso"                , "" )                                                                ,
		c( "title",               "\\title"                  , "" )                                                                  ,
		c( "TODO",                ""                         , "" )                                                                         ,
		c( "usage",               "\\usage"                  , "" )                                                                  ,
		c( "callGraph",           ""                         , "Create a call graph of the default depth, excluding primitive functions" )  ,
		c( "callGraphPrimitives", ""                         , "Create a call graph of the default depth, including primitive functions" )  ,
		c( "callGraphDepth",      ""                         , "Change the depth of the callgraph from the default of 2" )                  ,
		c( "include",             ""                         , "See ?make.collate.roclet" )                                                 ,
		c( "export",              "export"                   , "" )                                                                   ,
		c( "exportClass",         "exportClass"              , "" )                                                              ,
		c( "exportMethod",        "exportMethod"             , "" )                                                             ,
		c( "exportPattern",       "exportPattern"            , "" )                                                            ,
		c( "S3method",            "S3method"                 , "" )                                                                 ,
		c( "import",              "import"                   , "" )                                                                   ,
		c( "importFrom",          "importFrom"               , "" )                                                               ,
		c( "importClassesFrom",   "importClassesFrom"        , "" )                                                        ,
		c( "importMethodsFrom",   "importMethodsFrom"        , "" )                                                         ) 
	
	tag <- line %-~% "^#' *@"    
	matchingKeywords <- unique( c( 
	  grep( tag, roxygenTags[,1], ignore.case = TRUE ), 
		grep( tag, roxygenTags[,3], ignore.case = TRUE ) ) )
	completions <- if( !length(matchingKeywords) ) roxygenTags else roxygenTags[ matchingKeywords, , drop = FALSE ]
	token <- tag
	
	list( completions = sprintf( "%s ", completions[,1]), token = token, title = completions[,3] ) 

}

roxygenParamComplete <- function( file, row, line="#' @param " ){
	potential <- paste( argsfunafter( file, row, allArguments = FALSE ), " ", sep = "" )
	
	line <- line %-~% "^#' *@param"
	if( line %~% "^ +$" ){
		return( list( completions = potential, token = "" ) )
	}
	
	start <- line  %-~% "^[[:space:]]+"
	if( start %~% "[[:space:]]+" ) {
		return( list( completions = character(0), token = "" ) )
	}
	
	completions <- grep( start, potential, value = TRUE )
	if( length( completions ) ){
		return( list( completions = completions, token = start ) )
	} else{
		return( list( completions = character(0), token = "" ) )
	}
	
	
}


#' Get arguments of the function defined after a given point
#' @param file 
#' @param row 
argsfunafter <- function( file, row, allArguments = FALSE, p.out = parse(file), target = NULL ){
	positions <- sapply( attr( p.out, "srcref" ), function(x) as.numeric(x)[1] )
  target <- if( !is.null(target) ) target else which( positions >= row )[1]
	funstart <- positions[target]
	  
	### find the arguments that have already been documented
	definedPars <- try( if( !allArguments && funstart > 1){ 
	  rl <- readLines( file, n = funstart - 1)
	  test <- rl %~% "#'"
	  definedPars <- if( tail( test, 1 ) ){
			pos <- which( ! rev(test) )[1] - 1
	  	last <- if( is.na(pos) ) funstart else funstart - pos
			roxygenBlock <- rl[ last : (funstart-1) ]
	  	roxygenBlock %-~|% "^.*@param[[:space:]]+" %-~% "[[:space:]].*$" %~|% "."
	  } 
	} , silent = TRUE )
	if( definedPars %of% "try-error" ) definedPars <- NULL
	
	### find the arguments of the function
	chunk <- p.out[[target]]
	env <- new.env()
	if( length(chunk) == 3  ){
		if( chunk[[1]] == "<-" || chunk[[1]] == "=" ){    
			eval( chunk, env = env )
			contents <- ls( env )
			if( length( contents ) ){
				object <- env[[ contents ]]
				if( class( object ) == "function" ){
					allpars <- names( formals( object) )
					return( setdiff( allpars, definedPars ) )
				}
			}
		}
	}
	invisible( NULL )
}


isAfter <- function( p.out, row, col){
  rows <- sapply( attr( p.out, "srcref" ) , "[", 3 )
	cols <- sapply( attr( p.out, "srcref" ) , "[", 4 )
	row > rows | ( rows == row & col > cols )
}

isBefore <- function( p.out, row, col){
  rows <- sapply( attr( p.out, "srcref" ) , "[", 1 )
	cols <- sapply( attr( p.out, "srcref" ) , "[", 2 )
	row < rows | ( rows == row & col < cols )
}

isInside <- function( p.out, row, col){
	srcref <- attr( p.out, "srcref" )
	startRows <- sapply( srcref , "[", 1 )
	startCols <- sapply( srcref , "[", 2 )
	endRows   <- sapply( srcref , "[", 3 )
	endCols   <- sapply( srcref , "[", 4 )
	
	( ( row == startRows & col >= startCols ) | ( row >= startRows ) ) &  ( ( row == endRows   & col <= endCols   ) | ( row <= endRows   ) )
	
}

isFunction <- function( chunk ){
	env <- new.env()
	out <- try( {
		eval( chunk, env = env )
		name <- ls( env ) 
	}, silent = TRUE )
	test <- !( out %of% "try-error" ) && length(name) == 1 && env[[name]] %of% "function" 
	if( test ){
		attr( test, "fun" ) <- name
	}
	test
}



generateRoxygenTemplate <- function( file, row, col, 
  author = getOption("svTools.roxygen.author"), 
	type = c("verbatim", "supperabbrev" ) ){
	
	p.out <- parse( file )
	
	where <- if( any(inside <- isInside(p.out, row, col)) ){
		which( inside )
	} else if( any( before <- isBefore(p.out, row, col) ) ) { 
		which( before ) [1]
	} else length( p.out )
	
	if( !( isfun <- isFunction(p.out[[where]]) ) ){
		return( list( ok = 0 )  ) 
	} 
	funname <- attr( isfun, "fun" )
	
	startPos <- as.numeric( attr( p.out, "srcref" )[[where]][1:2] )
	
	arguments <- argsfunafter( file = file, allArguments =  T, 
	  p.out = p.out, row = startPos[1], target = where )
	
	
	template <- "#' ${1:Title (short) }\n#' \n#' ${2:Description (2-3 lines)}\n#' @export"
	if( length(arguments) ){
		template <- paste( template, paste( "#' @param ", arguments, " ${",2+1:length(arguments),": define `",arguments,"` }", sep = "", collapse = "\n" ), sep = "\n" ) 
	}
	index <- 2 + length( arguments ) + 1
	template <- paste( template, paste("#' @return ${",index,": What does the function return}", sep = "" ), sep = "\n" )
	index <- index + 1
	if( !is.null(author) ){
		author <- gsub( "([^@])@([^@])","\\1@@\\2", author )
		template <- paste( template, paste( "#' @author ${",index,":", author, "}", sep = "" ), sep = "\n" ) 
	}
	index <- index + 1
	template <- paste( template, paste( "#' @callGraph\n#' @examples\n#' ${",index,":# executable code for `",funname,"`}", sep = "" ), sep = "\n" ) 
	
	type <- match.arg( type )
	
	### remove the supper abbrev stuff
	if( type == "verbatim" ){
		template <- gsub( "(?s)\\$\\{[[:digit:]]+: *([^}]+)\\}","\\1", template, perl = TRUE  )
		template <- paste( template, "\n" , sep = "")
	}
	
	list( template = template, 
	      row = attr( p.out, "srcref" )[[where]][1], 
				ok = 1)
}


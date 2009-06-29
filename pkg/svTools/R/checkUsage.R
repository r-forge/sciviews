#' Wrapper for the checkUsage function in codetools
#' 
#' Wrapper for the checkUsage function in codetools. 
#' This one parses a file, calls checkUsage on every function of the 
#' file and identifies where are located each of the findings of checkUsage
#' @export
#' @param file file to analyse
#' @param encoding Character encoding to use
#' @return A data frame containing information about errors
#' @author Romain Francois \email{francoisromain@@free.fr}
checkUsageFile <- function( file, encoding = "unknown" ){
	
	if( is.character(file) && file %~% '^rwd:' ){
		file <- sub( '^rwd:', getwd(), file )
	}
	
	if( encoding != "unknown" ){
		old.op <- options( encoding = encoding )
		on.exit( options( old.op ) )
	}
	
	### first parse for errors
	p.out <- tryParse( file, action = addError, encoding = encoding )
	if( p.out %of% "data.frame" ){
		return( getErrors( file = file ) ) 
	}
	if( length( p.out ) == 0){
		return( emptyError() )
	}
	resetErrors( file = file )
	
	# silly hack to retrieve information from codetools
	report <- function( x ){
		findings <<- c( findings, x )
	}
	
	..addError <- function( line, msg ){
		addError( line = line, message = msg %-~%  "(\\\n|^: )"  , file = file, type = "warning" )
	}
	
	
	finding <- function( txt, p, i, rx, rx2 ){
			param <- sub( rx, "\\1", txt ) 
			param <- gsub( "\\.", "\\\\.", param ) 
			exprs <- p[[i]][[3]][[3]]
			srcref <- do.call( rbind, lapply( attr( exprs, "srcref" ), as.integer ) )  
			for( j in 1:length( exprs ) ){
				src <- as_character_srcref( attr( exprs, "srcref" )[[j]], useSource = TRUE, encoding = encoding )
			  matchingLines <- grep( sprintf(rx2, param), src )
				if( length( matchingLines ) ){
			  	return( matchingLines + as.integer( srcref[j,1] ) - 1 )
			  }
			}
	}
	
	find.parameter_changed_by_assignment <- function( txt, p, i ){
			finding( txt, p, i, 
			  rx = "^.*: parameter .(.*). changed by assignment\\\n", 
				rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*(=|<-|<<-)" )
	}
	
	find.local_assigned_but_not_used <- function( txt, p, i ){
			finding( txt, p, i, 
			  rx = "^.*: local variable .(.*). assigned but may not be used\\\n", 
				rx2 = "^[^.a-zA-Z0-9_(,]*%s[[:space:]]*(=|<-|<<-)" )
	}
	
	find.no_global_def <- function( txt, p, i ){
			finding( txt, p, i, 
			  rx = "^.*: no visible global function definition for .(.*).\\\n", 
				rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*\\(" )
	}
	
	find.no_local_def_as_function <- function( txt, p, i ){
			finding( txt, p, i, 
			  rx = "^.*: local variable .(.*). used as function with no apparent local function definition\\\n", 
				rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*\\(" )
	}
	 
	find.multiple_local_def <- function( txt, p, i ){
			finding( txt, p, i, 
			  rx = "^.*: multiple local function definitions for .(.*). with different formal arguments\\\n", 
				rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*(=|<-|<<-)[[:space:]]*function" )
	}

	
	searchAndReport <- function( regex, fun ){
		if( length( test.match <- grep( regex, findings ) ) ){
			for( j in test.match ){
				out <- fun( findings[j], p.out, i)
				if( length( out) ){
					..addError( out, findings[j] )
				}
			}
		}
	}
	
	
	for( i in 1:length(p.out) ){
		if( looksLikeAFunction( p.out[[i]] ) ){
			env <- new.env()
			eval( p.out[[i]], envir = env )
			fname <- ls( env ) 
			if( length(fname) == 1){
				findings <- NULL
				codetools:::checkUsage( env[[fname]], all = TRUE, report = report, name = "" )
				if( length(findings) ){
					
					searchAndReport( "changed by assignment"                , find.parameter_changed_by_assignment) 
					searchAndReport( "assigned but may not be used"         , find.local_assigned_but_not_used) 
					searchAndReport( "no visible global function definition", find.no_global_def )  
					searchAndReport( "no apparent local function definition", find.no_local_def_as_function )  
					searchAndReport( "multiple local function definitions"  , find.multiple_local_def )  
					
					# TODO :this needs to be improved to deal with nested functions
					if( length( test.assign <- grep( "’ may not be used", findings ) ) ){
						for( j in test.assign ){
							..addError( attr(p.out, "srcref")[[i]][1]  , findings[j] )
						}
					}
	
				}
			}
		}
	}
	getErrors( file = file )
}

as_character_srcref <- function (x, useSource = TRUE, encoding = "unknown"){
    srcfile <- attr(x, "srcfile")
    if (useSource)
        lines <- try(getSrcLines_(srcfile, x[1], x[3], encoding = encoding), TRUE)
    if (!useSource || inherits(lines, "try-error"))
        lines <- paste("<srcref: file \"", srcfile$filename,
            "\" chars ", x[1], ":", x[2], " to ", x[3], ":",
            x[4], ">", sep = "")
    else {
				if (length(lines) < x[3] - x[1] + 1)
            x[4] <- .Machine$integer.max
        lines[length(lines)] <- substring(lines[length(lines)], 1, x[4])
        lines[1] <- substring(lines[1], x[2])
    }
    lines
}

getSrcLines_ <- function (srcfile, first, last, encoding = "unknown" ){
    if (first > last)
        return(character(0))
    lines <- tail( readLines(srcfile, n = last, warn = FALSE, encoding = encoding), -(first-1) )
		return(lines)
}




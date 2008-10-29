#' Wrapper for the checkUsage function in codetools
#' 
#' Wrapper for the checkUsage function in codetools. 
#' This one parses a file, calls checkUsage on every function of the 
#' file and identifies where are located each of the findings of checkUsage
#' @export
#' @param file file to analyse
#' @return A data frame containing information about errors
#' @author Romain Francois \email{francoisromain@@free.fr}
checkUsageFile <- function( file ){
	
	### first parse for errors
	p.out <- tryParse( file, action = .addError )
	if( p.out %of% "data.frame" ){
		return( getErrors( file = file ) ) 
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
				src <- as.character( attr( exprs, "srcref" )[[j]] )
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
					
					searchAndReport( "changed by assignment"                , find.local_assigned_but_not_used )  
					searchAndReport( "assigned but may not be used"         , find.no_global_def )  
					searchAndReport( "no visible global function definition", find.no_local_def_as_function )  
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


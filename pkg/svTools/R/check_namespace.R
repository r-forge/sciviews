
namespaceDirectives <- c("export", 
	  "exportPattern", "exportClass", "exportClasses", 
		"exportMethods", "import", "importFrom", 
		"importClassFrom", "importClassesFrom", 
		"importMethodsFrom", "useDynLib", "S3method", "if" )

namespaceParser <- function( NAMESPACE, checkPackages = TRUE ){
	resetErrors( file = NAMESPACE )
	if( checkPackages ) allpacks <- .packages( all.available = TRUE )  
	### look for the 'object is not subsettable' error
	test <- try( tools:::.check_namespace( 
		dirname( tools:::file_path_as_absolute( NAMESPACE ) ) ), 
		silent = TRUE )
	if( test %of% "try-error" ){
		if( test %~% "object is not subsettable" ){
			lengths <- sapply( p, length )
			if( any( lengths == 1 ) ){
				line <- attr( p, "srcref" )[[ which( lengths == 1 )[1] ]] [1]
				addError(file=NAMESPACE, line=line, message = "object is not subsettable" )
			}
		} else {
			addError( parseError( test ) )
		}
	}
	
	### look for unexpected namespace directives
	p <- suppressWarnings( parse( NAMESPACE ) )
	
	directives <- sapply( p, function(x) as.character(x[[1]]) )
	if( any( test <- ! directives %in% namespaceDirectives ) ){
		problemLine <- sapply( attr( p, "srcref" )[ test ], function(x) as.integer(x[1] ) )
		addError(file=NAMESPACE, line=problemLine, 
			message = paste( "`", directives[test] , "` : Wrong NAMESPACE directive", sep = ""), 
			type = "warning" )
	}
	      
	 
	nS3 <- 0
            
	### parse the directives and look  for the unexpected
	parseDirective <- function(e, srcref, p, i) {   
        asChar <- function(cc) {
            r <- as.character(cc)
            if (any(r == "")){
							addError( file = NAMESPACE, type = "error", 
							  message = gettextf("empty name in directive '%s' in NAMESPACE file", as.character(e[[1]]) ), 
								line = srcref[1] )
						}
            r
        }                               
				switch(as.character(e[[1]]),                                                                                                       
					"if" = if (eval(e[[2]], .GlobalEnv)) parseDirective(e[[3]], srcref) else if (length(e) == 4) parseDirective(e[[4]], srcref), 
					"{" = for (ee in as.list(e[-1])) parseDirective(ee, srcref), 
          "=", "<-" = {
                parseDirective(e[[3]], srcref)
                if (as.character(e[[3]][[1]]) == "useDynLib") 
                  names(dynlibs)[length(dynlibs)] <<- asChar(e[[2]])
            }, export = {
								exp <- e[-1]
               exp <- structure(asChar(exp), names = names(exp))
               if( !length( exp ) ){
									addError( file = NAMESPACE, line = srcref[1], 
										message = "empty export", type = "warning"  ) 
							  }
								# TODO: check that the object exists
            }, exportPattern = {
							  pat <- asChar(e[-1])
								if( !length( pat ) ){
									addError( file = NAMESPACE, line = srcref[1], 
										message = "empty pattern", type = "warning"  ) 
							  }
								if( asChar( attr( p, "srcref") [[i]]) %~% "[^\\\\]\\\\[^\\\\]" ){
									addError( file= NAMESPACE, line = srcref[1], 
									  message = "wrong pattern, need to double escape", 
										type = "warning" )
								}
							  # TODO: try to match the regex against object names 
								#       and warn if there is no match
            }, exportClass = , exportClasses = {
                # TODO: check that the class is defined
            }, exportMethods = {
                # TODO: check that the methods are defined
            }, import = {
							packages <- asChar(e[-1])
							if( !length( packages) ){
								addError( file = NAMESPACE, line = srcref[1], 
										message = "empty import directive", type = "warning"  ) 
							}
							test <- packages %in% allpacks
							if( any(!test) ){
								addError( line = srcref[1], file = NAMESPACE, type = "error", 
								  message = sprintf( "package `%s` is set to be imported but is not available", packages[!test] ) )
							}
						}, 
            importFrom = {     
               imp <- asChar( e[-1] )
							  if( length( imp) < 2 ){
									addError( file = NAMESPACE, line = srcref[1], 
									  message = "Not enough information in importFrom directive", 
										type = "error" ) 
							  } else{
									if( ! require( imp[1], character.only = TRUE ) ){
										addError( line = srcref[1], file = NAMESPACE, type = "error", 
												message = sprintf( "package `%s` is set to be imported but is not available", imp[1] ) )
									} else if( any( test <- !imp[-1] %in% ls( sprintf("package:%s", imp[1])  )  ) ){ 
										addError( line = srcref[1], file = NAMESPACE, type = "error", 
											message = sprintf("object `%s` not exported from %s", imp[-1][test], imp[1]) )
									}
									# TODO: check if the variables are exported from the package
								}
								
            }, importClassFrom = , importClassesFrom = {
               imp <- asChar( e[-1] )
							  if( length( imp) < 2 ){
									addError( file = NAMESPACE, line = srcref[1], 
									  message = "Not enough information in importFrom directive", 
										type = "error" ) 
							  } else{
									if( ! require( imp[1], character.only = TRUE  ) ){
										addError( line = srcref[1], file = NAMESPACE, type = "error", 
												message = sprintf( "package `%s` is set to be imported but is not available", imp[1] ) )
							
									}
									# TODO: check if the classes are exported from the package
								}
            }, importMethodsFrom = {
               imp <- asChar( e[-1] )
							  if( length( imp) < 2 ){
									addError( file = NAMESPACE, line = srcref[1], 
									  message = "Not enough information in importFrom directive", 
										type = "error" ) 
							  } else{
									if( ! require( imp[1], character.only = TRUE  ) ){
										addError( line = srcref[1], file = NAMESPACE, type = "error", 
												message = sprintf( "package `%s` is set to be imported but is not available", imp[1] ) )
							
									}
									# TODO: check if the methods are exported from the package
								}
            }, useDynLib = {
                # TODO: do something about it
            }, S3method = {
                spec <- e[-1]
								 if (length(spec) != 2 && length(spec) != 3) 
                  addError( message = gettextf("bad 'S3method' directive: %s", deparse(e)), 
									   file = NAMESPACE, line = srcref[1], type = "error" )
                nS3 <<- nS3 + 1
                if (nS3 > 500) 
                  addError( message= "too many 'S3method' directives", 
									  file = NAMESPACE, line = srcref[1], type = "error" )
            } )
    }
		for (i in 1:length(p) ) {
			srcref <- attr( p, "srcref" )
			parseDirective( p[[i]], as.integer( srcref[[i]] ), p, i )
    }
	invisible( getErrors( file = NAMESPACE ) ) 
	
}


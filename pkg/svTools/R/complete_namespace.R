
namespaceComplete <- function( line ){
	
	### export
	if( line %~% "^[[:space:]]*export[[:space:]]*\\(" ){
		ex <- line %-~% ".*[(,][[:space:]]*"
		# TODO: parse the source files for functions
	}
	
	### import
	if( line %~% "^[[:space:]]*import[[:space:]]*\\(" ){
		im <- line %-~% ".*[(,][[:space:]]*"
		allpacks <- installedPackages( pattern = im )[,c("Package","Title")] 
		return( list( data = allpacks, type = "package" ) )
	}
	
	### importFrom
	if( line %~% "^[[:space:]]*importFrom[[:space:]]*\\([^,]*$" ){
		im <- line %-~% ".*[(][[:space:]]*"
		allpacks <- installedPackages( pattern = im )[,c("Package","Title")] 
		return( list( data = allpacks, type = "package" ) )
	}
	
}



check_description <- function( descfile, txt = readLines( descfile ) ){
  
	txt <- txt %/~% "\\\n"
	resetErrors( file = descfile )   
	..addError <- function( file = descfile, line, message, type = "error" ) {
		addError(file=file,line=line, message = message, type = type )
  }
  
  ### check mandatory fields
  for( mandatory in c("Package", "Version", "License", "Description", "Title", "Author", "Maintainer" )){ 
    if( !any( txt %~% sprintf("^%s", mandatory) ) ){
      ..addError( line = 1, message = sprintf("field `%s` is mandatory", mandatory ) )
    }
  }
	
	### check the fields
	fields <- txt %~|% "^[^:]+:" %-~% "[[:space:]]*:.*$"
	if( ! all( test <- fields %in% descriptionFields[,1] ) ){
		wrongFields <- fields[!test]
		lapply( wrongFields, function(x){
			rx.out <- regexpr( sprintf("^%s *:", x), txt )
			line <- which( rx.out != -1 )
			..addError( line = line, message = sprintf("Wrong field : `%s`", x ) )
		})
	}
	
  ### check the package name
  package <- grep("^Package[[:space:]]*:", txt )
  if( length(package )) {
    packageName <- txt[package] %-~% "(^[^:]*:| )"
    if( packageName %!~% "^[a-zA-Z][\\.0-9a-zA-Z]*$" ){
      ..addError( line = package, message = "wrong package name")
    }
  }
  
  ### check the version
  version <- grep("^Version:", txt )
  if( length(version) ){
    versionNumber <- txt[version] %-~% "(^[^:]*:| )"
    # TODO: handle translation packages
    if( versionNumber %~% "[^0-9\\.-]" ){
      ..addError( line = version, message = "Wrong format for the version number", type = "warning" )  
    }
    nfields <- length(versionNumber %/~% "[-\\.]" ) 
    if( nfields  < 2){
      ..addError( line = version, message = "Wrong version number, need at least two fields" , type = "warning")
    }
    if( nfields > 3 ){
       ..addError( line = version, message = "Wrong version number, too many fields", type = "warning" )
    }
  }
  
  ### check maintainer
  maintainer <- grep( "^Maintainer:", txt )
  if(length(maintainer)){
    maintainerLine <- txt[ maintainer ] %-~% "^[^:]: *"
    if( maintainerLine %~% "[\\.,]$" ){
      ..addError( line = maintainer, message = "the maintainer field should not end with a period or commas" )
    }
    if( length(maintainerLine %/~% "@") != 2 ){
      ..addError( line = maintainer, 
        message = "only one email adress in Maintainer field" )
    }
    email <- maintainerLine %-~% "(^[^<]*<|>[^>]*$)"
    if( email %!~% "[^@]+@[^@]+" | email %~% "[[:space:]]" ){
      ..addError( line = maintainer, 
        message = paste("wrong email adress: '", email, "'", sep = "" ) )
    }
  }
  
  ### check date                              
  date <- grep("^Date", txt )
  if(length(date)){
    dateLine <- txt[date] %-~% "(^[^:]*:| )"
    if( dateLine %!~% "^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$" ){
      ..addError( line = date, message = "the date should be in format yyyy-mm-dd" )
    }
  }
  
  ### check the dependencies
	# FIXME : all the stuff below comes from tools, I need to figure out what to do with it
  db <- tools:::.read_description(descfile)
  depends  <- tools:::.get_requires_from_package_db(db, "Depends")
  imports  <- tools:::.get_requires_from_package_db(db, "Imports")
  suggests <- tools:::.get_requires_from_package_db(db, "Suggests")
  standard_package_names <- tools:::.get_standard_package_names()
  bad_depends <- list()
  reqs <- unique(c(depends, imports, if (!identical(as.logical(Sys.getenv("_R_CHECK_FORCE_SUGGESTS_")), 
      FALSE)) suggests))
  installed <- character(0)
  for (lib in .libPaths()) {
      pkgs <- list.files(lib)
      pkgs <- pkgs[file.access(file.path(lib, pkgs, "DESCRIPTION"), 
          4) == 0]
      installed <- c(pkgs, installed)
  }
  installed <- sub("_.*", "", installed)
  reqs <- reqs %without% installed
  m <- reqs %in% standard_package_names$stubs
  if (length(reqs[!m])) 
      bad_depends$required_but_not_installed <- reqs[!m]
  if (length(reqs[m])) 
      bad_depends$required_but_stub <- reqs[m]
  
	if( length(bad <- bad_depends$required_but_not_installed) ) {
		..addError( line = grep("^(Depends|Suggests|Enhances)", txt), 
		  message = paste("package `",bad,"` required but not installed", sep = "") ) 
	}
	
	if( length(bad <- bad_depends$required_but_stub) ) {
		..addError( line = grep("^(Depends|Suggests|Enhances)", txt), 
		  message = paste("package `",bad,"` required but stub", sep = "") ) 
	}
	
	invisible( getErrors( file = descfile ) ) 
	
}





loadedPackages <- function(){
  s <- grep( "^package:", search(), value = TRUE )
  sub("^package:", "", s )
}

installedPackages <- function( pattern = NULL){
 ip <- installed.packages( fields = "Title" )
 if( !is.null(pattern) ){
	 keep <- suppressWarnings( union( 
	 	grep( pattern , ip [,"Package"], ignore.case = TRUE ), 
		grep( pattern , ip [,"Title"], ignore.case = TRUE ) ) )
	 ip <- ip[ keep, , drop = FALSE]
 }
 lp <- loadedPackages() 
 def <- c( getOption("defaultPackages"), "base")
 ip <- cbind( ip, 
   "Loaded"  = ifelse( ip[,'Package'] %in% lp , 1, 0 ), 
   "Default" = ifelse( ip[,'Package'] %in% def, 1, 0 )
 )
 ip 
}


packdesc  <- function (pkg, lib.loc = NULL, fields = NULL, drop = TRUE, encoding = "") {
    retval <- list()
    if (!is.null(fields)) {
        fields <- as.character(fields)
        retval[fields] <- NA
    }
    pkgpath <- ""
    if (is.null(lib.loc)) {
        if (pkg == "base") 
            pkgpath <- file.path(.Library, "base")
        else if ((envname <- paste("package:", pkg, sep = "")) %in% 
            search()) {
            pkgpath <- attr(as.environment(envname), "path")
            if (is.null(pkgpath)) 
                pkgpath <- ""
        }
    }
    if (pkgpath == "") {
        libs <- if (is.null(lib.loc)) 
            .libPaths()
        else lib.loc
        for (lib in libs) if (file.access(file.path(lib, pkg), 
            5) == 0) {
            pkgpath <- file.path(lib, pkg)
            break
        }
    }
    if (pkgpath == "") {
        pkgpath <- system.file(package = pkg, lib.loc = lib.loc)
        if (pkgpath == "") {
            warning(gettextf("no package '%s' was found", pkg), 
                domain = NA)
            return(NA)
        }
    }
    file <- file.path(pkgpath, "DESCRIPTION") 
    readLines(file)
}

packwebdesc <- function(pack, repos, width = 60){
  temp <- tempfile(); on.exit(unlink(temp))
  txt <- suppressWarnings( try({
    download.file( sprintf("%s/Descriptions/%s.DESCRIPTION",repos,pack), destfile=temp, quiet = TRUE)
    readLines(temp)
  }, silent = TRUE) )
  if( inherits(txt, "try-error") ) txt <- ""
  txt
}


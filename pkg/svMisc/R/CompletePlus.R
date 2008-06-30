CompletePlus <- function (linebuffer, cursorPosition = nchar(linebuffer), minlength = 2 ) {
    utils:::.assignLinebuffer(linebuffer)
    utils:::.assignEnd(cursorPosition)
    utils:::.guessTokenFromLine()
    token <- utils:::.CompletionEnv[["token"]]
    if (nchar(token, type = "chars") < minlength) return(invisible(NULL))
    utils:::.completeToken()
    comps <- utils:::.retrieveCompletions()
    out <- matrix( "", nrow = length(comps), ncol = 2 )
    out[,1] <- comps
    
    ### deal with packages (completions ending with ::)
    if(length(test.pack <- grep("::", comps) )){
      out[ test.pack,2] <- sapply( sub("::", "", comps[test.pack]), packageDescription, fields = "Description"  ) 
    }
    
    ### deal with argument completions (ending with =)
    if(length(test.arg <- grep("=", comps) )){
      arg <- sub("=$", "", comps[test.arg] )
      fguess <- utils:::.CompletionEnv[["fguess"]]
      pack <- sub( "^package:", "", find( fguess )[1] )
      if(pack == ".GlobalEnv" ) {
        out[ test.arg,2] <- ""
      } else{
        out[ test.arg,2] <- paste( "[", fguess, "] ", .extract_argument_description( pack, fguess, arg), sep = "" )
      }
    }
    
    ### TODO: do not know what to do with these
    test.others <- grep(" ", comps)
    # TODO: are there other kind of completions I miss here
    
    ### deal with function completions
    test.fun <- setdiff( 1:length(comps), c(test.arg, test.pack, test.others) )
    if( length(test.fun) ){
      funs     <- comps[test.fun]
      packs    <- sub( "^package:", "", sapply( funs , find ) )
      desc.fun <- rep( "", length(packs) )
      for( pack in unique(packs) ){
        if( pack != ".GlobalEnv" ){
          dir <- .find.package(pack)
          rds <- file.path(dir, "Meta", "Rd.rds")
          rd.data <- .readRDS(rds)
          funInThisPack <- funs[ packs == pack ]
          desc.fun[ packs == pack ] <- sapply( funInThisPack, function(x){
            index <- which( sapply( rd.data$Aliases, function(y) any(x %in% y) ) )
            rd.data$Title[ index ]
          })
        }
      }
      out[ test.fun, 2 ] <- desc.fun
    }
    
    out
    
}

.extract_argument_description <- function( package, fun, arg, lib.loc = NULL){
  
  dir <- .find.package(package, lib.loc)
  rds <- file.path(dir, "Meta", "Rd.rds")
  if (file_test("-f", rds)) {
    rd.data <- .readRDS(rds)
    index <- which( sapply( rd.data$Aliases, function(x) any(fun %in% x) ) )
    if( length(index) == 1){
      rdfile <- rd.data$File[index]
      rddb <- tools:::Rd_db( package = package)
      rdcontent <- paste( rddb[ basename(names(rddb)) == rdfile ][[1]], collapse = "\n" )
      arguments <- .get_Rd_arguments_table( rdcontent )
      arguments[ sapply( arg, function(x) which(arguments[,1] == x  )), 2 ]
      # TODO: do some error handling
    } else {
      rep( "", length(arg) )
    }
  } else {
    rep( "", length(arg))
  }
  
}

.get_Rd_arguments_table <-  function (txt) {
    txt <- tools:::get_Rd_section(txt, "arguments")
    tab <- get_Rd_items_table(txt)
    txt <- tab[,1]
    if (!length(txt)) 
        return(character())
    txt <- gsub("\\\\l?dots", "...", txt)
    txt <- sub("^[[:space:]]+", "", txt)
    txt <- sub("[[:space:]]+$", "", txt)
    txt <- gsub("\\\\_", "_", txt)
    tab[,1] <- txt
    tab
}

get_Rd_items_table <- function (txt) {
    out <- character() # item names
    desc <- character() # item descriptions
    
    if (length(txt) != 1L) 
        stop("argument 'txt' must be a character string")
    pattern <- "(^|\n)[[:space:]]*\\\\item\\{"
    while ((pos <- regexpr(pattern, txt)) != -1L) {
        txt <- substring(txt, pos + attr(pos, "match.length") - 1L)
        if ((pos <- tools:::delimMatch(txt)) == -1L) 
            stop(gettextf("unmatched \\item name in '\\item{%s'", 
                sub("\n.*$", "", txt)), domain = NA, call. = FALSE)
        newout <- strsplit( substring(txt, pos + 1L, pos + attr(pos, "match.length") - 2L), " *, *" )[[1]]
        out <- c(out, newout)
        txt <- substring(txt, pos + attr(pos, "match.length"))
        if ((pos <- regexpr("^[[:space:]]*\\{", txt)) == -1L) 
            stop(gettextf("no \\item description for item '%s'", 
                out[length(out)]), domain = NA, call. = FALSE)
        txt <- substring(txt, pos + attr(pos, "match.length") - 1L)
        if ((pos <- tools:::delimMatch(txt)) == -1L) 
            stop(gettextf("unmatched \\item description for item '%s'", 
                out[length(out)]), domain = NA, call. = FALSE)
        desc <- c( desc, rep( substring(txt, 2L, pos + attr(pos, "match.length") - 2L), length(newout) ) )
        txt <- substring(txt, pos + attr(pos, "match.length"))
    }
    cbind( out, desc )
}



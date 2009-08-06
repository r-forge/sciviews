rsitesearch <- function( query ){
      
  ### build the string to submit to the website
  if(missing(query)) return(NULL)
  paste0 <- function(...) paste(..., sep = "")
  string <- paste0("http://search.r-project.org/cgi-bin/namazu.cgi?query=", gsub(" ", "+", query))
  mpp <- "max=100"
  restr <- "idxname=functions"
  lang <- "lang=firefox"
  qstring <- paste(string, mpp, lang, restr, sep = "&")
  
  ### download the result of the query and read it into R
  temp <- tempfile()
  download.file( qstring, temp, quiet = TRUE )
  result <- readLines( temp )
  if( result %~+% "No document matching your query" ) return(NULL)
  
  ### process the webpage to extract relevant information
  result <- grep( "^http", result, value = TRUE )
  result <- gsub( ".*/R/library/", "", result )
  result <- strsplit( result, "(/html/| )")
  result <- as.data.frame( do.call( rbind, result ) )
  colnames( result ) <- c("package", "page", "score") 
  result$score <- as.numeric( result$score ) 
  result$page  <- gsub( "\\.html$", "", result$page )
  
  ### structure the result by package
  out <- by( result[,2:3], list( package = result$package), function(x){
    list( data = x[ order(x$score, decreasing = TRUE) ,  ,drop = FALSE], 
          score = sum( x$score ) )
  })
  out <- out[ order( sapply(out, "[[", "score"), decreasing = TRUE ) ]
  
  structure( out, class = "rsitesearch", call = NULL, query = query, link = qstring )
}                      

print.rsitesearch <- function( x, only.summary = FALSE, ...){
  ### print header
  cat( "r site search query for '", attr( x, "query" ), "'\n", sep = "", ... )
  cat( attr(x, "link"), "\n\n", ... )
  packages <- names(x) 
  scores   <- sapply( x, "[[", "score")
  for( i in seq(along = x)){
    cat( sprintf("%s (%d)\n", packages[i], scores[i]) )
    if(!only.summary) {
      cat( paste( "  |-- ", 
        sprintf( "%-30s %5d", x[[i]]$data$page, x[[i]]$data$score ) , 
        sep = " ", collapse = "\n" ), ... )
      cat("\n\n", ...)
    }
  }
}

head.rsitesearch <- function( x, n = 2, ...){
  h <- head( unclass(x), n = n, ... )
  structure( h, class = "rsitesearch", query = attr(x, "query"), 
    link = attr(x, "link" ) ) 
}

tail.rsitesearch <- function( x, n = 2, ...){
  h <- tail( unclass(x), n = n, ... )
  structure( h, class = "rsitesearch", query = attr(x, "query"), 
    link = attr(x, "link" ) ) 
}

`[.rsitesearch` <- function(x, i, ...){  
  structure( NextMethod("["), class = "rsitesearch", 
    query = attr(x, "query"), link = attr(x, "link") )
}

summary.rsitesearch <- function( object, ... ){
  print( object, only.summary = TRUE, ...  )
} 

### search the gmane mailing list
gmane <- function( query, groups = "*", prefix = "gmane.comp.lang.r" ) {
  
  ### building the search url
  url <- sprintf( "http://search.gmane.org/?query=%s&group=%s.%s&sort=relevance", 
    gsub(" +", "+", query), prefix, groups )  
  
  ### make the search
  tmp <- tempfile()
  on.exit( unlink(tmp) )
  download.file( url,  destfile=tmp) 
  
  ### read the html file, and deduce things
  rl <- readLines( tmp )
  firstLines <- rl %~|%  "^<A HREF"
  links <- gsub('^<A HREF="([^"]+)".*','\\1', firstLines )
  # links <- gsub("//article\\.","//thread\\.",links)
  links <- links %-~% "/match=.*$"
  group <- gsub( 
    sprintf("http://article.gmane.org/%s.([^/]+)/.*", prefix ), 
    "\\1", links )
  titles <- gsub( '.*>([^<]+)<.*', '\\1', firstLines )  
  relevance <- gsub( '.*\\((.*)%\\)$', '\\1', firstLines )
  
  by( data.frame( links = links, titles = titles, relevance = relevance, stringsAsFactors=FALSE), 
    group, function(x) x )
}

### convert r news bib database into a data.frame
.rnews <- function( query, file = "Rnews.bib" ){

  biblines <- readLines( file )
    
  ### read the pdf urls
  strings <- biblines %~|% "@String\\{"
  strings <- strings %-~% '(@String\\{|\\}|")'  
  x    <- strings %/~% "[[:space:]]*=[[:space:]]*"  
  refs <- sapply( x, "[", 1 )
  urls <- sapply( x, "[", 2 )
  names(urls) <- refs
    
  begin    <- grep("^@Article", biblines )
  end      <- grep("^\\}", biblines )
  articles <- mapply( function(x, y) {
      lines   <- biblines[x:y]
      eqLines <- c( grep("=", lines ), length(lines)+1)
      txt <- mapply( function(x1,x2){  
        paste( lines[x1:x2], collapse = " ")    
      }  , head( eqLines,-1), tail( eqLines - 1,-1) )
      txt <- txt %/~% "[[:space:]]*=[[:space:]]*"   
      fields <- sapply( txt, "[", 1) %-~% "[[:space:]]+"
      content <- sapply( txt, "[", 2) %-~% "(^\\{|\\}?,$)"
      content <- gsub(" +", " ",content)
      names( content ) <- fields
      content["url"] <- urls[ "http" ]
      if( any( fields == "pdf") && content["pdf"] %in% refs ){
        content["pdf"] <- urls[ content["pdf"] ]
      }
      content
    } , begin+1, end-1 )
  uNames <- unique( unlist( sapply( articles, names )) )
  articles <- sapply( articles, function(x){
    x[ uNames %without% names(x) ] <- NA
    x[ uNames ]
  })
  
  out <- as.data.frame( t(articles), stringsAsFactors=FALSE ) 
  out$year <- as.numeric( out$year )
  out$volume <- as.numeric( out$volume )
  out$number <- as.numeric( out$number )
  colnames( out ) <- uNames 
  out$issue  <- paste( "Volume ", out$volume, "/", out$number, " (", out$month, " ",out$year,")", sep="" )
  out
}

# rnewssearch <- function( query, ... ){
#   matches <- agrep( query, rnews$title, ignore.case = TRUE,...)
#   subs <- rnews[ matches, ]
#   by( subs, subs$issue, function(x){
#     x$title
#   })
# }

rwiki <- function( query ){
  tmp <- tempfile() 
  on.exit( unlink(tmp) )
  
  url <- sprintf( "http://wiki.r-project.org/rwiki/doku.php?do=search&id=%s", 
    gsub( " +", "+", query ) )
  download.file( url, tmp ) 

  results <- readLines( tmp ) %~|% "search_result"
  results <- tail( results %/~% "search_result", -1 )
  
  ids <- results %-~% '&amp.*'
  ids <- ids %-~% '^.*id='
    
  hits <- as.numeric( gsub('^.*class=\\"search_cnt\\">(.*) Hits</span>.*', '\\1', results ) )
  
  snippets <- results %-~% '.*\\"search_snippet\\">'
  snippets <- snippets %-~% '</?[^>]*>'
  snippets <- snippets %-~% '\\[[^\\]*]\\]'
  snippets <- snippets %-~% '<div.*'
  snippets <- snippets %-~% 'hideLoadBar\\([^\\)]*\\)'
  
  structure( list( id =ids, snippet = snippets, hit = hits, n = length(results) ), 
    class = "wikisearch")
}

print.wikisearch <- function(x, ...){
  for( i in 1:x$n){ 
    cat( x$id[i], " (", x$hit[i], " Hits)\n", sep = "", ... )
    cat( strwrap(x$snippet[i], prefix = "     ", width = 60 ), sep = "\n", ... )
    cat( "\n", ... )
  }
}

rgraphicalmanuals <- function(query){
  url <- sprintf("http://cged.genes.nig.ac.jp/RGM2/index.php?query=%s&scope=all", 
    gsub(" +", "+", query) )
  
  # TODO: follow   
  tmp <- tempfile() 
  on.exit( unlink(tmp) )
  download.file( url, tmp ) 

  results <- readLines( tmp  )  
  results <- results %~|% '^<td><a href=".*/library/'
  results <- results %-~% "^.*/library/"
  results <- results %-~% '\\.html".*'
  
  packages <- results %-~% "/.*"
  pages    <- results %-~% ".*/"
  out <- by( pages, packages, function(x) as.character(unique(x)) )
  
  structure( out, class = "graphicalmanuals" )
}

rgraphgallery <- function(query){
  url <- sprintf("http://addictedtor.free.fr/graphiques/simplesearch.php?q=%s", 
    gsub(" +", "+", query ) )
  tmp <- tempfile() 
  on.exit( unlink(tmp) )
  download.file( url, tmp ) 

  results <- readLines(tmp)
  ids <- results %-~% ',.*'
  titles <- results %-~% '^[0-9]*,'
  structure( list(id = ids, title = titles, n = length(titles)), 
    class="graphgallery" )
}


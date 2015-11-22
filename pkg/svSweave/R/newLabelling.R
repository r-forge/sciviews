## These functions are there to enumerate labels for figures, tables, equations,
## listings, ...
newLabelling <- function (type = c("arabic", "roman"), prefix = "",
    string = "_**Figure ####:** @@@@_")
{
    type <- match.arg(type)
    conv <- switch(type,
        arabic = function (x) x,
        roman = function (x) as.roman(x))
    prefix <- as.character(prefix)[1]
    string <- as.character(string)[1]
    labels <- list()
    
    ## Return a function that creates the enumeration of the items
    function (label, text, reset = FALSE) {
        ## Do we reset figs?
        if (isTRUE(reset)) labels <<- list()
            
        ## Do we have a label? If not, return an empty string.
        if (missing(label)) return(invisible(""))
        
        value <- labels[[label]]
        ## Does it exists?
        if (is.null(value)) {
            value <- paste0(prefix, conv(length(labels) + 1))
            ## Record this item in labels
            labels[[label]] <- value
            labels <<- labels
        }
        
        ## If we have a text, format a complete legend string
        ## This should be a markdown-compatible label!
        mdlabel <- gsub("\\.", "-", make.names(label))
        if (missing(text)) {
            ## Special case: if numbered example list of markdown...
            if (grepl("%%%%", string)) {
                paste0("@", mdlabel)
            } else value
        } else {
            sub("%%%%", mdlabel, sub("@@@@", text, sub("####", value, string)))
        }
    }
}

## Default items
fig <- newLabelling()
tab <- newLabelling(string = "_**Table ####:** @@@@_")
## This is the best I can do, using the numbered example list of markdown (but
## it is not available for something else)!
eq <- newLabelling(string = "(@%%%%) $$ @@@@ $$")

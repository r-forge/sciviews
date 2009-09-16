.active.data.frame <- list(object = "",
    fun = function () {
        if (exists(.active.data.frame$object, envir = .GlobalEnv)) {
            obj <- get(.active.data.frame$object, envir = .GlobalEnv)
            res <- paste(names(obj), "\t", sapply(obj, class), "\n", sep = "")
            return(.active.data.frame$cache <<- res)
        } else return(.active.data.frame$cache <<- NULL)       
    }, cache = "")


guiRefresh <- function (force = FALSE) {    
    # Refresh active items and the R Objects explorer
    # If force == TRUE, do not compare with the cache
    # Active items are represented by .active.xxx objects in .GlobalEnv
    aObjs <- ls(pattern = "^\\.active\\.", envir = .GlobalEnv, all.names = TRUE)
    for (item in aObjs) {
        obj <- get(item, envir = .GlobalEnv, inherits = FALSE)
        if (mode(obj) == "list") {
            objclass <- sub("^\\.active\\.", "", item)
            # JavaScript does not accept dots in function names. So, we have
            # to remove them from class name (eg., data.frame => dataframe)
            objclass <- gsub("\\.", "", objclass)
            cache <- obj$cache
            res <- obj$fun()
            if (is.null(res)) # Active object not found, remove obj
                rm(list = item, envir = .GlobalEnv)
            if (isTRUE(force) || !identical(res, cache)) # Refresh in Komodo
                koCmd(paste('sv.r.obj_refresh_', objclass, '("<<<data>>>");',
                    sep = ""), data = res)
        }
    }
    # Refresh object browser (only data from .GlobalEnv)
    lst <- objList(envir = .GlobalEnv, all.info = FALSE, compare = TRUE)
    if (length(lst$Name) > 0)
        koCmd('sv.r.objects.refreshGlobalEnv("<<<data>>>");',
              data = print(lst, sep = ";;", raw.output = TRUE, header = TRUE))
        
    return(TRUE)
}

guiAutoRefresh <- function (...) {
    guiRefresh(force = FALSE)
    return(TRUE)
}
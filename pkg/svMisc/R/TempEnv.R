"TempEnv" <-
function() {
    pos <-  match("TempEnv", search())
    if (is.na(pos)) { # Must create it
        TempEnv <- list()
        attach(TempEnv, pos = length(search()) - 1)
        rm(TempEnv)
        pos <- match("TempEnv", search())
    }
    return(pos.to.env(pos))
}

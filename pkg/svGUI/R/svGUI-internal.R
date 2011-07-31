.onLoad <- function (lib, pkg)
{
	## Create .GUI that contains information about the default GUI
	guiAdd(".GUI")
}

#.onUnload <- function (libpath)
#{
#	## We do nothing, because other packages may also use .GUI
#}

.packageName <- "svGUI"

## A copy of TempEnv() from svMisc to avoid a useless dependency (only
## internally used)
.TempEnv <- function ()
{
    pos <-  match("TempEnv", search())
    if (is.na(pos)) { # Must create it
        TempEnv <- list()
        attach(TempEnv, pos = length(search()) - 1)
        rm(TempEnv)
        pos <- match("TempEnv", search())
    }
    return(pos.to.env(pos))
}

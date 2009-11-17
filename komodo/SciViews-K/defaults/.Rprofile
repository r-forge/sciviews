# Avoid running this function recursively (R restarts sometimes in Linux)
if (!exists("svStart", envir = .GlobalEnv, mode = "function")) {
	source("svStart.R")
	svStart()
	rm(svStart)
}
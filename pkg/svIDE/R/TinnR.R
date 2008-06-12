# Specific functions for Tinn-R (adapted by J.-C. Faria from functions in svGUI
# made by Ph. Grosjean)
# Note: to avoid duplication in code, core process is now moved into objSearch()
# and objList() in the svMisc package

"trObjSearch" <-
function(path = NULL) {
	res <- objSearch(sep = "\n", compare = FALSE)
	if (is.null(path)) {
		return(data.frame(search.. = strsplit(res, "\n")[[1]]))
	} else {
		cat("search..\n", res, "\n", sep = "", file = path)
	}
}

"trObjList" <-
function(id = "default", envir = ".GlobalEnv", all.names = TRUE,
pattern = "", group = "", path = NULL) {
	# Get data
	res <- objList(id = id, envir = envir, all.names = all.names,
		pattern = pattern, compare = FALSE)

	if (length(res) == 1 && res == "") {
		res <- data.frame("", "", "", "", stringsAsFactors = FALSE)
	} else {
		res <- data.frame(t(data.frame(strsplit(res, "\t"))),
			stringsAsFactors = FALSE)[ , -5]
	}
	colnames(res) <- c("Name", "Dims", "Group", "Class")
	rownames(res) <- NULL

	# Group conversion
	GrpTable <- c(
		"vector",      "vector",    "vector",     "vector",
		"vector",      "vector",    "vector",     "table",
		"list",        "function",  "other",      "other",
		"other",       "other")
	names(GrpTable) <- c(
		"numeric",     "complex",   "character",  "logical",
		"factor",      "DateTime",  "raw",        "data.frame",
		"list",        "function",  "NULL",       "language",
		"S3",          "S4")
	NewGroup <- GrpTable[res$Group]
	NewGroup[NewGroup == "vector" & (regexpr("x", res$Dims) > -1)] <- "array"
	NewGroup[NewGroup == "array" &
		(regexpr("^[0-9]+x[0-9]+$", res$Dims) > -1)] <- "matrix"
	res$Group <- NewGroup

	# Filter according to group
    if (group != "") {
		if (group == "data") {
			res <- res[NewGroup != "function", ]
		} else {
			res <- res[NewGroup == group, ]
		}
	}

	# Final result
	if (is.null(path)) {
		return(res)
	} else {
		write.table(res, file = path, row.names = FALSE, quote = FALSE,
			sep = "\t")
	}
}

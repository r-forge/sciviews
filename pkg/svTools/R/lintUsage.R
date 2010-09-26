### Wrapper for the checkUsage function in codetools. 
### Romain Francois <francoisromain@free.fr>
lintUsage <- function (file, encoding = getOption("encoding"))
{	
	if (is.character(file) && regexpr('^rwd:', file) > 0)
		file <- sub('^rwd:', getwd(), file)
	
	old.op <- options(encoding = encoding)
	on.exit(options(old.op))
	
	## First parse for errors
	p.out <- tryParse(file, action = addError, encoding = encoding)
	if (inherits(p.out, "data.frame")) return(getErrors(file = file))
	if (length(p.out) == 0) return(emptyError())
	resetErrors(file = file)
	
	## Silly hack to retrieve information from codetools
	findings <- NULL
	report <- function (x)
		assign("findings", c(findings, x), envir = environment())
	
	addErrorFile <- function (line, msg)
		addError(line = line, message = gsub("(\\\n|^: )", "", msg),
			file = file, type = "warning")
	
	finding <- function (txt, p, i, rx, rx2) {
		param <- sub(rx, "\\1", txt) 
		param <- gsub("\\.", "\\\\.", param) 
		exprs <- p[[i]][[3]][[3]]
		srcref <- do.call(rbind, lapply(attr(exprs, "srcref"), as.integer))  
		for (j in 1:length(exprs)) {
			src <- .as.characterSrcRef(attr(exprs, "srcref")[[j]],
				useSource = TRUE, encoding = encoding)
			matchingLines <- grep(sprintf(rx2, param), src)
			if (length(matchingLines))
			  	return(matchingLines + as.integer(srcref[j, 1]) - 1)
		}
	}
	
	findParamChangedByAssign <- function (txt, p, i)
		return(finding(txt, p, i, 
			rx = "^.*: parameter .(.*). changed by assignment\\\n", 
			rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*(=|<-|<<-)"))
	
	findUnusedLocalAssign <- function (txt, p, i)
		return(finding(txt, p, i, 
			rx = "^.*: local variable .(.*). assigned but may not be used\\\n", 
			rx2 = "^[^.a-zA-Z0-9_(,]*%s[[:space:]]*(=|<-|<<-)"))
	
	findNoGlobalDef <- function (txt, p, i)
		return(finding(txt, p, i, 
			rx = "^.*: no visible global function definition for .(.*).\\\n", 
			rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*\\("))
	
	findNoLocalDefAsFun <- function (txt, p, i)
		return(finding(txt, p, i, 
			rx = "^.*: local variable .(.*). used as function with no apparent local function definition\\\n", 
			rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*\\("))
	 
	findMultipleLocalDef <- function (txt, p, i)
		return(finding(txt, p, i, 
			rx = "^.*: multiple local function definitions for .(.*). with different formal arguments\\\n", 
			rx2 = "[^.a-zA-Z0-9_]*%s[[:space:]]*(=|<-|<<-)[[:space:]]*function"))
	
	searchAndReport <- function (regex, fun) {
		if (length(test.match <- grep(regex, findings)))
			for (j in test.match) {
				out <- fun(findings[j], p.out, i)
				if (length(out)) addErrorFile(out, findings[j])
			}
	}
	
	for (i in 1:length(p.out)) {
		if (.looksLikeAFunction(p.out[[i]])) {
			env <- new.env()
			eval(p.out[[i]], envir = env)
			fname <- ls(env) 
			if (length(fname) == 1) {
				findings <- NULL
				checkUsage(env[[fname]], all = TRUE, report = report, name = "")
				if (length(findings)) {
					searchAndReport("changed by assignment", findParamChangedByAssign) 
					searchAndReport("assigned but may not be used", findUnusedLocalAssign) 
					searchAndReport("no visible global function definition", findNoGlobalDef)  
					searchAndReport("no apparent local function definition", findNoLocalDefAsFun)  
					searchAndReport("multiple local function definitions", findMultipleLocalDef)  					
### TODO: this needs to be improved to deal with nested functions
					if (length(test.assign <- grep(" may not be used", findings)))
						for (j in test.assign)
							addErrorFile(attr(p.out, "srcref")[[i]][1], findings[j])
				}
			}
		}
	}
	return(getErrors(file = file))
}

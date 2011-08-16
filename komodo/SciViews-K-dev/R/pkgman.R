# 'imports'
compareVersion <- utils::compareVersion
available.packages <- utils::available.packages
installed.packages <- utils::installed.packages
install.packages <- utils::install.packages
remove.packages <- utils::remove.packages
packageDescription <- utils::packageDescription
getCRANmirrors <- utils::getCRANmirrors
write.table <- utils::write.table

pkgManGetDescription <- function(pkg, print=TRUE) {
	if (pkg %in% rownames(installed.packages())) {
		desc <- packageDescription(pkg)
	} else {
		con <- url(file.path(getOption("repos")['CRAN'], "web", "packages", pkg,
							 'DESCRIPTION', fsep = '/'))
        m <- try(open(con, "r"), silent = TRUE)
        if (!inherits(m, "try-error")) {
			dcf <- try(read.dcf(con))
			close(con)
			desc <- as.list(dcf[1, ])
			class(desc) <- "packageDescription"
		} else {
			return(invisible(NULL))
		}
	}
	if (print) {
		write.dcf(as.data.frame.list(desc[!sapply(desc, is.na)],
			optional = TRUE), width = Inf)
		invisible(desc)
	} else {
		desc
	}
}

pkgManGetMirrors <- function() {
	tmpVar <- "pkgMan.CRANmirrors"
	if(existsTemp(tmpVar)) {
		mirrors <- getTemp(tmpVar)
	} else {
		mirrors <- getCRANmirrors()
		assignTemp(tmpVar, mirrors)
	}
	write.table(mirrors[, c(1,4)], row.names = FALSE, col.names = F, sep=';', quote = F, na="")
}

pkgManGetAvailable <- function(page = "next", pattern = "", ilen=50,
	col=c("Package", "Version", "InstalledVersion", "Status"),
	reload=FALSE, sep=';', eol="\t\n") {
	if (!existsTemp('avpkg.list') || reload) {
		avpkg.list <- availablePkgs(utils::available.packages(filters=c("R_version",
			"OS_type", "duplicates")), installed = FALSE)
		assignTemp('avpkg.list', avpkg.list)
	} else {
		avpkg.list <- getTemp('avpkg.list')
	}
	if (page == "first") {
		newSearch <- TRUE
		i0 <- 1
	} else {
		newSearch <- getTemp('avpkg.pattern', "") != pattern
		i0 <- getTemp('avpkg.idx', default = 1)
	}

	if(is.character(pattern) && pattern != "") {
		if(newSearch) {
			page <- "current"
			i0 <- 1
			idx <- grep(pattern, avpkg.list[,'Package'], ignore.case = TRUE)
			assignTemp('avpkg.pattern.idx', idx)
		} else {
			idx <- getTemp('avpkg.pattern.idx')
		}
		imax <- length(idx)
	} else {
		imax <- nrow(avpkg.list)
		idx <- seq(imax)
	}
	#browser()
	assignTemp('avpkg.pattern', pattern)

	if (page == "next") i0 <- i0 + ilen else
		if (page == "prev") i0 <- i0 - ilen
	outside <- i0 > imax || i0 < 1
	if (outside) return(NULL)
	assignTemp('avpkg.idx', i0)
	i1 <- min(i0 + ilen - 1, imax)
	i <- seq(i0, i1)
	cat(i0, i1, imax, "\t\n")
	write.table(availablePkgs(avpkg.list[idx[i], , drop = FALSE])[, col, drop = FALSE],
		row.names = FALSE, col.names = F, sep=sep, quote = FALSE, eol=eol, na='')
}

availablePkgs <- function(avpkg=available.packages(), installed=TRUE) {
	#browser()
	avpkg <- avpkg[order(toupper(avpkg[, "Package"])), , drop = FALSE]
	if(installed) {
		inspkg <- installed.packages()
		ipkgnames <- unique(inspkg[, 'Package'])

		ipkgnames <- ipkgnames[ipkgnames %in% avpkg[, 'Package']]
		avpkg <- cbind(avpkg, 'InstalledVersion'=NA, 'Status'=NA)
		if(length(ipkgnames)) {
			pkgstatus <- sapply(ipkgnames, function(pkg) {
				compareVersion(avpkg[pkg, 'Version'], inspkg[pkg, 'Version'])
			})
			avpkg[ipkgnames, 'Status'] <- pkgstatus
			avpkg[ipkgnames, 'InstalledVersion'] <- inspkg[ipkgnames, 'Version']
		}
	}
	avpkg
}

pkgManGetInstalled <- function(sep=';', eol="\t\n") {
	inspkg <- installed.packages(fields="Description")
	inspkg <- inspkg[order(toupper(inspkg[, "Package"])),
		c("Package","Version","Description")]

	inspkg[,3] <- gsub("\n", " ", inspkg[,3])
	inspkg <- cbind(inspkg, Installed=inspkg[, 'Package'] %in% .packages())
	write.table(inspkg, row.names = FALSE, col.names = F, sep=sep, quote = F, eol=eol, na='')
}

pkgManSetCRANMirror <- function(url) {
	repos <- getOption("repos")
	repos['CRAN'] <- url
	options(repos = repos)
}


pkgManInstallPackages <- function(upkgs, installDeps=FALSE, ask=TRUE) {
	dep <- suppressMessages(utils:::getDependencies(upkgs, available = getTemp('avpkg.list')))
	msg <- status <- ""
	if (!ask && (installDeps || all(dep %in% upkgs))) {
		msg <- captureAll(install.packages(dep))
		status <- "done"
	} else {
		l <- length(dep)
		msg <- sprintf(ngettext(l,
			"This will install package %2$s.",
			"This will install packages: %s and %s.",
		), paste(sQuote(dep[-l]), collapse = ", "), sQuote(dep[l]))
		status <- "question"

	}
	list(packages=dep, message=msg, status=status)
	#invisible(dep)
}

pkgManRemovePackage <- function(pkgName) {
	sapply(pkgName, function(pkgName) {
		if(pkgName %in% loadedNamespaces()) unloadNamespace(pkgName)
		pack <- paste("package", pkgName, sep=":")
		if(pack %in% search()) detach(pack, character.only = TRUE)

		dlli <- getLoadedDLLs()[[pkgName]]
		if(!is.null(dlli)) dyn.unload(dlli[['path']])

		pkgpath <- find.package(pkgName, quiet = TRUE)
		if(length(pkgpath) == 0L) return(FALSE)

		pkglib <- normalizePath(file.path(pkgpath, ".."))
		if(file.access(pkglib, 2) == 0) {
			remove.packages(pkgName, lib=pkglib)
			return(TRUE)
		} else {
			#warning("No sufficient access rights to library", sQuote(pkglib))
			return(FALSE)
		}
	}, simplify=FALSE)
}

pkgManLoadPackage  <- function(pkgName) {
	sapply(pkgName, library, character.only = TRUE, logical.return = TRUE, simplify = FALSE)
}

pkgManDetachPackage <- function(pkgName) {
	sapply(pkgName, function(pkgName) {
		tryCatch({
			if(pkgName %in% loadedNamespaces()) unloadNamespace(pkgName)
			pack <- paste("package", pkgName, sep=":")
			if(pack %in% search()) detach(pack, character.only = TRUE)
			TRUE
		}, error = function(e) {
			conditionMessage(e)
		})
	}, simplify = FALSE)
}


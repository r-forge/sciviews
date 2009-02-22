"print.guiImg" <-
function (x, ...)
{
	cat("A SciViews GUI image object:", "\n")
	print(unclass(x))
	return(invisible(x))
}

"ImgAdd" <-
function (file, type = "gif", imgtype = "tkImage", update = FALSE, ...)
{
	res <- switch(imgtype,
		tkImage = tkImgAdd(file = file, type = type, update = update),
		stop("Unrecognized image type '", imgtype, "'"))
	return(invisible(res))
}

"ImgDel" <-
function (image)
{
    res <- switch(ImgType(image),
		tkImage = tkImgDel(image))
	return(invisible(res))
}

"ImgGet" <-
function (image)
{
	# Get the image
    return(getTemp(".guiImgs")[[image]])
}

"ImgType" <-
function (image, warn = TRUE)
{
	# Get the type of image
	if (regexpr("^[$]Tk[.]", image) > 0) return("tkImage") else {
        if (warn) warning("Unrecognized image type for ", image)
		return(NA)
	}
}

"ImgNames" <-
function ()
{
	# List all available images
    res <- names(getTemp(".guiImgs"))
	if (is.null(res)) res <- character(0)
	return(res)
}

"ImgRead" <-
function (dir, type = "gif", imgtype = "tkImage")
{
	# Depending on 'imgtype', we call a different function
	res <- switch(imgtype,
		tkImage = tkImgRead(dir = dir, type = type),
		stop("Unrecognized image type '", imgtype, "'"))
	return(invisible(res))
}

"ImgReadPackage" <-
function (package, subdir = "gui", type = "gif", imgtype = "tkImage")
{
	# Create image resources by reading a series of image files from the 'gui'
	# subdirectory of a package
	dir <- system.file(subdir, package = package)
	res <- ImgRead(dir= dir, type = type, imgtype = imgtype)
	return(invisible(res))
}

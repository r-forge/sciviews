"Args" <-
function (name, only.args = FALSE
{
	#### TODO: handle primitives and S3/S4 methods for generic functions
	ret <- try(res <- eval(parse(text = paste("argsAnywhere(", name, ")",
		sep = ""))), silent = TRUE)
	if (inherits(ret, "try-error") || is.null(res))
		return("")	# Function 'name' not found
	res <- deparse(res)
	res <- paste(res[-length(res)], collapse = "\n")
	if (only.args) {
		res <- sub("^function *[(]", "", res)
		res <- sub(" *[)] *$", "", res)
	} else {
		res <- sub("^function", name, res)
		res <- sub(" *$", "", res)
	}
	return(res)
}

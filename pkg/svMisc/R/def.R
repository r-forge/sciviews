"def" <-
function (value, default = "", mode = "character", length = NULL)
{
	# Ensure we got a value of a given mode, and if not, use default
	# If length is provided, make sure that the returned vector has that length
	# (if needed, cut or recycle 'value')

	# If either NULL or NA, or something of length == 0 is in 'value', then,
	# return default
	if (is.null(value) || is.na(value) || length(value) < 1) value <- default

	# Coerce to mode... special treatment for logical!
	res <- switch(mode[1],
		logical = (value == TRUE),
		character = as.character(value),
		numeric = as.numeric(value),
		factor = as.factor(value),
		complex = as.complex(value),
		value)	# This is for unrecognized modes!

	# If length is provided, make sure the vector has this length
	if (!is.null(length)) {
		if (!is.numeric(length) || length[1] < 1) length <- 1 else
			length <- round(length[1])	# Make sure 'length' argument is correct
		res <- rep(res, length.out = length)
	}
	return(res)
}

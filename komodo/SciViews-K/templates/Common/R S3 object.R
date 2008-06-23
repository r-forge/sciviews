# S3 object: [[%ask1:Class]]
# Author:    [[%ask:Author]]

# Creator or the S3 object (usually, a function with the same name)
"[[%ask1]]"
<- function() {
	# Code to create the object here...
	obj <- "[[%ask1]] object"
	class(obj) <- [[%ask1]]
	return(obj)

}

# Print method
"print.[[%ask1]]"
<- function(x, ...) {
	# Code to print the object here...
	cat ("[[%ask1]] object printed\n")
	return(invisible(x))
}

# Summary method
"summary.[[%ask1]]" <-
function(object, ...)
	structure(object, class = c("summary.[[%ask1]]", class(object)))

"print.summary.[[%ask1]]" <-
function(x, ...) {
	# Code to print the summary of the object here...
	cat ("[[%ask1]] object summarized\n")
	return(invisible(x))
}

# Plot method
"plot.[[%ask1]]"
<- function(x, ...) {
	# Code to plot the object here...
	cat ("[[%ask1]] object plotted\n")
	invisible()
}
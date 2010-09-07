\name{toRjson}
\alias{toRjson}
\alias{evalRjson}

\title{ Convert R object to and from RJSON specification }
\description{
  RJSON is an object specification that is not unlike JSON, but better adapted
  to represent R objects (i.e., richer than JSON). It is also easier to parse
  and evaluate in both R and JavaScript to render the objects in both languages.
  RJSON objects are used by SciViews to exchange data between R and SciViews
  GUIs like Komodo/SciViews-K.
}

\usage{
toRjson(x, attributes = FALSE)
evalRjson(rjson)
}

\arguments{
  \item{x}{ any R object to be converted into RJSON (do not work with objects
    containing C pointers, environments, promises or expressions, but should
    work with almost all other R objects). }
  \item{attributes}{ if \code{FALSE} (by default), a simple object is created
    by ignoring all attributes. This is usally the suitable option to transfer
    data to another language, like JavaScript that do not understand R attributes
    anyway. With \code{attributes = TRUE}, the complete information about the
    object is written, so that the object could be recreated (almost) identical
    when evaluated in R (but prefer \code{save} and \code{load} to tranfer
    objects between R sessions!). }
  \item{rjson}{ a string containing an object specified in RJSON notation. The
    specification is evaluated in R... and it can contain also R code. There
    is no protection provided against execution of bad code. So, you must trust
    the source! }
}

\details{
  JSON (JavaScript Object Notation) allows to specify fairly complex objects
  that can be rather easily exchanged between languages. The notation is also
  human-readable and not too difficult to edit manually (although not advised,
  of course). However, JSON has too many limitations to represent R objects (no
  NA versus NaN, no infinite numbers, no distinction between lists and objects
  with attributes, or S4 objects, etc.). Moreover, JSON is not very easy to
  interpret in R and the existing implementations can convert only specified
  objects (simple objects, lists, data frames, ...).
  
  RJSON slighly modifies and enhances JSON to make it: (1) more complete to
  represent almost any R object (except objects with pointers, environments,
  ..., of course), and (2) to make it very easy to parse and evaluate in both
  R and JavaScript (and probably many other) languages.
  
  With \code{attributes = FALSE}, factors and Dates are converted to their
  usual character representation before encoding the RJSON object. If
  \code{attributes = TRUE}, they are left as numbers and their attributes
  (class, -and levels for factor-) completely characterize them (i.e., using
  \code{evalRjson()} and such objects recreate factors or Dates, respectively).
  However, they are probably less easy to handle in JavaScript of other language
  where you import the RJSON representation.
  
  Note also that a series of objects are not yet handled correctly. These
  include: complex numbers, the different date flavors other that Date,
  functions, expressions, environments, pointers. Do not use such items in
  objects that you want to convert to RJSON notation.
  
  A last restriction for the moment: you cannot have any special characters
  like \\n, \\t, \\f, \\r, \\b, \\\", or \" in names. If you want to make your
  names most compatible with JavaScript, note that the dot is not allowed in
  syntactically valid names, but the dollar sign is allowed.
  
  TODO: a complete specification of RJSON (somewhere... a wiki page?)
}

\value{
  For \code{toRjson()}, a character string vector with the RJSON specification
  of the argument.
  
  For \code{evalRjson()}, the corresponding R object in case of a pure RJSON
  object specification, or the result of evaluating the code, if it contains R
  commands (for instance, a RJSONp -RJSON with padding- item where a RJSON
  object is an argument of an R function that is evaluated. In this case, the
  result of the evaluation is returned).
}

\author{ Philippe Grosjean <phgrosjean@sciviews.org> }

\seealso{ \code{\link{Parse}} }

\examples{
## A complex R object
Robj <- structure(list(
	a = as.double(c(1:5, 6)),
	LETTERS,
	c = c(c1 = 4.5, c2 = 7.8, c3 = Inf, c4 = -Inf, NA, c6 = NaN),
	c(TRUE, FALSE, NA),
	e = factor(c("a", "b", "a")),
	f = "this is a \"string\"\nwith\tspecial chars",
	g = matrix(rnorm(4), ncol = 2),
	`h&'$@` = data.frame(x = 1:3, y = rnorm(3),
		fact = factor(c("b", "a", "b"))),
	i = Sys.Date(),
    j = list(1:5, y = "another item")),
    comment = "My comment\n\"",
    anAttrib = 1:10,
    anotherAttrib = list(TRUE, y = 1:4))

## Convert to simplest RJSON, without attributes
Rjson1 <- toRjson(Robj)
Rjson1
evalRjson(Rjson1)

## More complex RJSON, with attributes
Rjson2 <- toRjson(Robj, TRUE)
Rjson2
Robj2 <- evalRjson(Rjson2)
Robj2
## Numbers near equivalence comparison (note: identical(Robj, Robj2) is FALSE)
all.equal(Robj, Robj2)

rm(Robj, Robj2, Rjson1, Rjson2)
}

\keyword{ utilities }

\concept{ Object serialization, JavaScript Object Notation }
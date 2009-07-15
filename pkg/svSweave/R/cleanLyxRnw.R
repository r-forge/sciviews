"cleanLyxRnw" <- function (RnwCon, RnwCon2 = RnwCon)
{
	# Read the data in the Rnw file
	Rnw <- readLines(RnwCon)

	# If the Rnw file is produced with LyX and SciViews Sweave module, chunks are
	# separated by \rchunk{<<[pars]>>= ... @}

	# Beginning of R-Chunks (rewrite into <<[pars]>>=)
	starts <- grepl("^\\\\rchunk\\{<<.*>>=$", Rnw)
	Rnw[starts] <- sub("^\\\\rchunk\\{", "", Rnw[starts])

	# End of R-Chunks (rewrite as @)
	ends <- grepl("^@[ \t]*\\}$", Rnw)
	Rnw[ends] <- "@"

	parts <- cumsum(starts | ends)
	chunk <- parts %% 2 > 0 	# R chunks are odd parts

	# Do we need to change something?
	if (!any(chunk))
		return(writeLines(Rnw, RnwCon2))

	# Eliminate empty strings not followed by empty strings inside chunks
	Rnw[chunk & Rnw == "" & Rnw != c(Rnw[-1], " ")] <- NA
	isna <- is.na(Rnw)
	Rnw <- Rnw[!isna]
	chunk <- chunk[!isna]

	# Eliminate successive empty strings (keep only one)
	Rnw[chunk & Rnw == "" & Rnw == c(Rnw[-1], " ")] <- NA
	Rnw <- Rnw[!is.na(Rnw)]

	# Convert tabulations into four spaces inside chunks (8 spaces by default)
	Rnw[chunk] <- gsub("\t", "    ", Rnw[chunk])

	# Write the result to the new .Rnw file
	return(writeLines(Rnw, RnwCon2))
}

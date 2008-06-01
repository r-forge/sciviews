"compareRVersion" <-
function(version) {
    # This is similar to compareVersion, but works for R version comparison
    compareVersion(paste(R.Version()$major, R.Version()$minor, sep = "."),
		version)
}

// SciViews-K functions
// Define default preferences values for SciViews-K
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

// Define default socket ports for the client and server, and other parameters
sv.prefs.setString("sciviews.server.socket", "7052", false);
sv.prefs.setString("sciviews.client.socket", "8888", false);
sv.prefs.setString("sciviews.client.id", "SciViewsK", false);

// Default working directory for R
sv.prefs.setString("sciviews.session.dir", "~", false);

// Where do we want to display R help? In internal browser or not?
sv.prefs.setString("sciviews.r.help", "internal", false);

// This is the base path for the R Wiki context help feature of sv.helpContext()
sv.prefs.setString("sciviews.rwiki.help.base",
	"http:/wiki.r-project.org/rwiki/doku.php?id=", false);

// Record default field and decimal separators for CSV files
sv.prefs.setString("r.csv.sep", '\t', false);
var sep = sv.prefs.getString("r.csv.sep", '\t');
if (sep == '\t') {
	sv.prefs.setString("r.csv.sep.arg", '"\\t"', true);
} else {
	sv.prefs.setString("r.csv.sep.arg", '"' + sep + '"', true);
}
sv.prefs.setString("r.csv.dec", '.', false);
sv.prefs.setString("r.csv.dec.arg", '"' + sv.prefs.getString("r.csv.dec", '.') +
	'"', true);

// Set default dataset to 'df'
// Should be reset to a more useful value during first use of R
sv.prefs.setString("R.active.data.frame", "df", false);

// (re)initialize a series of MRU for snippets' %ask constructs
//// TODO: ts, data, table

//// dec argument, like in read.table()
sv.prefs.mru("dec", reset = true, '"."|","', sep = "|");

//// sep argument, like in read.table()
sv.prefs.mru("sep", reset = true, '" "|";"|","|"\\t"', sep = "|");

//// header argument, like in read.table()
sv.prefs.mru("header", reset = true, 'TRUE|FALSE', sep = "|");

//// Various examples of pkgdata (indeed, data frames in datatasets 2.9.1)
sv.prefs.mru("pkgdata", reset = false, 
	'airquality|anscombe|attenu|attitude|beaver1|beaver2|BOD|cars|' +
	'ChickWeight|chickwts|CO2|DNase|esoph|faithful|Formaldehyde|freeny|' +
	'Indometh|infert|InsectSprays|iris|LifeCycleSavings|Loblolly|longley|' +
	'morley|mtcars|Orange|OrchardSprays|PlantGrowth|pressure|Puromycin|' +
	'quakes|randu|rock|sleep|stackloss|swiss|Theoph|ToothGrowth|trees|' +
	'USArrests|USJudgeRatings|warpbreaks|women', sep = "|");

// TODO... Various examples of itemIndex, subset and expression
// TODO... List of function, descfun and transfun

//// Various examples of formulas
sv.prefs.mru("formula", reset = false,
	'y ~ x,y ~ x + x2,y ~ x + I(x^2),y ~ x - 1,' +
	'y ~ factor,y ~ x | factor,y ~ factor + factor2,y ~ factor * factor2',
	sep = ",");

//// Various examples of quantiles and probs
sv.prefs.mru("quantiles", reset = false, '1|c(1, 3)', sep = "|");
sv.prefs.mru("probs", reset = false, '0.5|c(0.01, 0.25, 0.5, 0.75, 0.99)', sep = "|");
sv.prefs.mru("lower.tail", reset = true, 'TRUE|FALSE', sep = "|");
sv.prefs.mru("na.rm", reset = true, 'TRUE|FALSE', sep = "|");
sv.prefs.mru("var.equal", reset = true, 'TRUE|FALSE', sep = "|");
sv.prefs.mru("conf.level", reset = true, '0.90|0.95|0.99|0.999', sep = "|");
sv.prefs.mru("alternative", reset = true, '"two.sided"|"less"|"greater"', sep = "|");
sv.prefs.mru("breaks", reset = true, '"Sturges"|"Scott"|"Freedman-Diaconis"|10', sep = "|");
sv.prefs.mru("corMethod", reset = true, '"pearson"|"kendall"|"spearman"', sep = "|");

//// Various graph parameters
// Colors
sv.prefs.mru("col", reset = true,
    '"black"|"red"|"blue"|"green"|"gray"|"darkred"|"darkblue"|"darkgreen"|' +
	'"darkgray"|"lightblue"|"lightgreen"|"lightgray"|"gray10"|"gray20"|' +
    '"gray30"|"gray40"|"gray50"|"gray60"|"gray70"|"gray80"|"gray90"|"white|"' +
    '"transparent"|"wheat"|"cornsilk"|"yellow"|"orange"|"tan"|"tomato"|' +
    '"firebrick"|"magenta"|"pink"|"salmon"|"violet"|"purple"|"plum"|"cyan"|' +
    '"lavender"|"navy"|"azure"|"aquamarine"|"turquoise"|"khaki"|"gold"|' +
    '"bisque"|"beige"|"brown"|"chocolate"', sep = "|");

// Type
sv.prefs.mru("type", reset = true, '"p"|"l"|"b"|"c"|"o"|"h"|"s"|"S"|"n"', sep = "|");
ko.mru.reset("dialog-interpolationquery-typeMru");
ko.mru.add("dialog-interpolationquery-typeMru", '"n"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"S"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"s"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"h"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"o"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"c"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"b"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"l"', true);
ko.mru.add("dialog-interpolationquery-typeMru", '"p"', true);

// Pch
sv.prefs.mru("type", reset = true,
    '0|1|2|3|3|4|5|6|7|8|9|10|11|12|13|14|15|15|17|18|19|20|21|22|23|24|25|' +
    '"."|"+"|"-"|"*"', sep = "|");

// Lty
sv.prefs.mru("lty", reset = true,
    '"solid"|"dashed"|"dotted"|"dotdash"|"longdash"|"twodash"|"blank"', sep = "|");

// Lwd
sv.prefs.mru("lwd", reset = true, '1|2|3', sep = "|");


//// various mrus for 'car' graphs
sv.prefs.mru("reg.line", reset = true, 'FALSE|lm', sep = "|");
sv.prefs.mru("smooth", reset = true, 'TRUE|FALSE', sep = "|");
sv.prefs.mru("diagonal", reset = true,
    '"density"|"histogram"|"boxplot"|"qqplot"|"none"', sep = "|");
sv.prefs.mru("envelope", reset = true, '0.90|0.95|0.99|0.999', sep = "|");

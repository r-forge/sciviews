// SciViews-K preference code
// SciViews-K preferences management ('sv.prefs' namespace)
// Define default preferences values for SciViews-K and MRU lists
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.prefs.getString(pref, def); // Get a preference, use 'def' is not found
// sv.prefs.setString(pref, value, overwrite); // Set a preference string
// sv.prefs.askString(pref, defvalue); // Ask for the value of a preference
// sv.prefs.mru(mru, reset, items, sep); //Simplify update of MRU lists
//
////////////////////////////////////////////////////////////////////////////////

if (typeof(sv.prefs) == 'undefined') sv.prefs = new Object();

// Get a string preference, or default value
sv.prefs.getString = function (pref, def) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (prefs.hasStringPref(pref)) {
		return(prefs.getStringPref(pref));
	} else return(def);
}

// Set a string preference
sv.prefs.setString = function (pref, value, overwrite) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (overwrite == false & prefs.hasStringPref(pref)) return;
	prefs.setStringPref(pref, value);
}

// Display a dialog box to change a preference string
sv.prefs.askString = function (pref, defvalue) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	// If defvalue is defined, use it, otherwise, use current pref value
	if (defvalue == null & prefs.hasStringPref(pref))
		defvalue = prefs.getStringPref(pref);
	if (defvalue == null) defvalue == "";
	// Display a dialog box to change the preference value
	newvalue = ko.dialogs.prompt("Change preference value for:", pref,
		defvalue, "SciViews-K preference", "svPref" + pref)
	if (newvalue != null) prefs.setStringPref(pref, newvalue);
}

// Simplify update of MRU lists
sv.prefs.mru = function (mru, reset, items, sep) {
	var mruList = "dialog-interpolationquery-" + mru + "Mru";
	// Do we reset the MRU list?
	if (typeof(reset) == "undefined") reset = false;
	if (reset == true) ko.mru.reset(mruList);

	// Do we need to split items (when sep is defined)?
	if (typeof(sep) != "undefined") items = items.split(sep);

	// Add each item in items in inverse order
	for (var i = items.length - 1; i >= 0; i--) {
		if (items[i] != "")
			ko.mru.add(mruList, items[i], true);
	}
}

//// Preferences (default values, or values reset on each start) ///////////////
// Define default socket ports for the client and server, and other parameters
sv.prefs.setString("sciviews.server.socket", "7052", false);
sv.prefs.setString("sciviews.client.socket", "8888", false);
sv.prefs.setString("sciviews.client.id", "SciViewsK", false);
sv.prefs.setString("sciviews.server.host", "127.0.0.1", false);

// R interpreter
sv.prefs.setString("svRDefaultInterpreter", "", false);
sv.prefs.setString("svRApplication", "", false);
sv.prefs.setString("svRApplicationId", "", false);
sv.prefs.setString("CRANMirror", "http://cran.r-project.org/", false);



// This is required by sv.helpContext() for attaching help to snippets (hack!)
// Create empty preference sets to be used with snippet help system hack
// [[%pref:R-help:value]] which displays nothing when the snippet is used
// but can be used to retrieve value to display a particular help page
// for this snippet
// Help page triggered by a given URL
sv.prefs.setString("URL-help", "", true);
// R HTML help pages triggered with '?topic'
sv.prefs.setString("R-help", "", true);
// Help page on the R Wiki
sv.prefs.setString("RWiki-help", "", true);

// Default working directory for R and default subdirs the first time SciViews-K
// is used... the rest of session dirs is set in r.js with sv.r.setSession()
sv.prefs.setString("sciviews.session.dir", "~", false);

// Where do we want to display R help? In internal browser or not?
sv.prefs.setString("sciviews.r.help", "internal", false);

// This is the base path for the R Wiki context help feature sv.helpContext()
sv.prefs.setString("sciviews.rwiki.help.base",
	"http:/wiki.r-project.org/rwiki/doku.php?id=", false);

// Record default field and decimal separators for CSV files
sv.prefs.setString("r.csv.sep", ',', false);
var sep = sv.prefs.getString("r.csv.sep", ',');
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
sv.prefs.setString("r.active.data.frame", "<df>", true);
sv.prefs.setString("r.active.lm", "<lm>", true);
sv.prefs.setString("r.active.princomp", "<princomp>", true);
sv.prefs.setString("r.active.prcomp", "<prcomp>", true);
sv.prefs.setString("r.active.PCA", "<PCA>", true);
sv.prefs.mru("var", true, "");
sv.prefs.mru("var2", true, "");
sv.prefs.mru("x", true, "");
sv.prefs.mru("x2", true, "");
sv.prefs.mru("y", true, "");
sv.prefs.mru("factor", true, "");
sv.prefs.mru("factor2", true, "");
sv.prefs.mru("blockFactor", true, "");


//// (re)initialize a series of MRU for snippets' %ask constructs //////////////
// TODO: defaultMRU for ts, data, table, ...

// dec argument, like in read.table()
sv.prefs.mru("dec", true, '"."|","', "|");

// sep argument, like in read.table()
sv.prefs.mru("sep", true, '" "|";"|","|"\\t"', "|");

// header argument, like in read.table()
sv.prefs.mru("header", true, 'TRUE|FALSE', "|");

// Various examples of pkgdata (indeed, data frames in datatasets 2.9.1) /////
sv.prefs.mru("pkgdata", false,
	'airquality|anscombe|attenu|attitude|beaver1|beaver2|BOD|cars|' +
	'ChickWeight|chickwts|CO2|DNase|esoph|faithful|Formaldehyde|freeny|' +
	'Indometh|infert|InsectSprays|iris|LifeCycleSavings|Loblolly|longley|' +
	'morley|mtcars|Orange|OrchardSprays|PlantGrowth|pressure|Puromycin|' +
	'quakes|randu|rock|sleep|stackloss|swiss|Theoph|ToothGrowth|trees|' +
	'USArrests|USJudgeRatings|warpbreaks|women', "|");

// TODO... Various examples of itemIndex, subset and expression
// TODO... List of function, descfun and transfun

//// Various examples of formulas //////////////////////////////////////////////
sv.prefs.mru("formula", false,
	'y ~ x,y ~ x + x2,y ~ x + I(x^2),y ~ x - 1,' +
	'y ~ factor,y ~ x | factor,y ~ factor + factor2,y ~ factor * factor2', ",");

//// Various examples of quantiles and probs ///////////////////////////////////
sv.prefs.mru("quantiles", false, '1|c(1, 3)', "|");
sv.prefs.mru("probs", false, '0.5|c(0.01, 0.25, 0.5, 0.75, 0.99)', "|");
sv.prefs.mru("lower.tail", true, 'TRUE|FALSE', "|");
sv.prefs.mru("na.rm", true, 'TRUE|FALSE', "|");
sv.prefs.mru("var.equal", true, 'TRUE|FALSE', "|");
sv.prefs.mru("conf.level", true, '0.90|0.95|0.99|0.999', "|");
sv.prefs.mru("alternative", true, '"two.sided"|"less"|"greater"', "|");
sv.prefs.mru("breaks", true, '"Sturges"|"Scott"|"Freedman-Diaconis"|10', "|");
sv.prefs.mru("corMethod", true, '"pearson"|"kendall"|"spearman"', "|");

// Var.equal (for t-test)
sv.prefs.mru("var.equal", true, 'TRUE|FALSE', "|");

// For multivariate stats
sv.prefs.mru("cor", true, 'TRUE|FALSE', "|"); // princomp()
sv.prefs.mru("loadings", true, 'TRUE|FALSE', "|");
sv.prefs.mru("sort.loadings", true, 'TRUE|FALSE', "|");
sv.prefs.mru("screetype", true, '"barplot"|"lines"', "|");
sv.prefs.mru("pc.biplot", true, 'TRUE|FALSE', "|");
sv.prefs.mru("choices", true, '1:2|2:3|c(1, 3)|c(1, 4)|c(2, 4)|c(3, 4)', "|");

//// Various graph parameters //////////////////////////////////////////////////
// Colors
sv.prefs.mru("col", true,
    '1|2|3|4|5|6|7|8|"#838383"|' +
    '"black"|"red"|"blue"|"green"|"gray"|"darkred"|"darkblue"|"darkgreen"|' +
	'"darkgray"|"mistyrose"|"lightblue"|"lightgreen"|"lightgray"|"gray10"|' +
    '"gray20"|"gray30"|"gray40"|"gray50"|"gray60"|"gray70"|"gray80"|"gray90"|' +
    '"white"|"transparent"|"wheat"|"cornsilk"|"yellow"|"orange"|"tan"|' +
    '"tomato"|"firebrick"|"magenta"|"pink"|"salmon"|"violet"|"purple"|' +
    '"plum"|"cyan"|"lightcyan"|"lavender"|"navy"|"azure"|"aquamarine"|' +
    '"turquoise"|"khaki"|"gold"|"bisque"|"beige"|"brown"|"chocolate"', "|");

// Type
sv.prefs.mru("type", true, '"p"|"l"|"b"|"c"|"o"|"h"|"s"|"S"|"n"', "|");

// Log
sv.prefs.mru("log", true, '""|"x"|"y"|"xy"', "|");

// Add
sv.prefs.mru("add", true, 'TRUE|FALSE', "|");

// Pch
sv.prefs.mru("pch", true,
    '0|1|2|3|3|4|5|6|7|8|9|10|11|12|13|14|15|15|17|18|19|20|21|22|23|24|25|' +
    '"."|"+"|"-"|"*"', "|");

// Lty
sv.prefs.mru("lty", true,
    '"solid"|"dashed"|"dotted"|"dotdash"|"longdash"|"twodash"|"blank"', "|");

// Lwd
sv.prefs.mru("lwd", true, '1|2|3', "|");

// Notch (for boxplot)
sv.prefs.mru("notch", true, 'TRUE|FALSE', "|");


//// various mrus for 'car' graphs /////////////////////////////////////////////
sv.prefs.mru("reg.line", true, 'FALSE|lm', "|");
sv.prefs.mru("smooth", true, 'TRUE|FALSE', "|");
sv.prefs.mru("diagonal", true,
    '"density"|"histogram"|"boxplot"|"qqplot"|"none"', "|");
sv.prefs.mru("envelope", true, '0.90|0.95|0.99|0.999', "|");

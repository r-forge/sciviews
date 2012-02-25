// SciViews-K preference code
// SciViews-K preferences management ('sv.prefs' namespace)
// Define default preferences values for SciViews-K and MRU lists
// Copyright (c) 2008-2012, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.prefs.defaults;             // Default preference values
// sv.prefs.checkAll();           // Check all preferences
// sv.prefs.getString(pref, def); // Get a preference, use 'def' is not found
// sv.prefs.setString(pref, value, overwrite); // Set a preference string
// sv.prefs.askString(pref, defvalue); // Ask for the value of a preference
// sv.prefs.mru(mru, reset, items, sep); //Simplify update of MRU lists
//                                         history a text entries in dialog box
// sv.prefs.tip(arg, tip);        // Default tooltips for interpolation queries
//
// Definition of various preferences for SciViews-K
////////////////////////////////////////////////////////////////////////////////

if (typeof(sv.prefs) == "undefined") sv.prefs = {};

// sv.prefs.defaults[preferenceName] = preferenceValue
sv.prefs.defaults = {
	"sciviews.server.socket": "7052",
	"sciviews.server.type": "socket",
	"sciviews.client.type": "http",
	"sciviews.client.socket": "8888",
	"sciviews.client.id": "SciViewsK",
	"sciviews.server.host": "127.0.0.1",
	"svRDefaultInterpreter": "",
	"svRApplication": "",
    "r.csv.dec": ".",
	"r.csv.sep": ",",
	"r.application": "",
	"r.cran.mirror": "http://cran.r-project.org/"
	//*Future preferences:*
	//"svRArgs": "--quiet",
	//"RHelpCommand": "javascript:sv.r.help(\"%w\")",
	//"sciviews.rhelp.open_in": [tab, window]
	//"sciviews.r.auto-start": false
}

// Get a string preference, or default value
sv.prefs.getString = function (pref, def) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"]
		.getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (prefs.hasStringPref(pref)) {
		return(prefs.getStringPref(pref));
	} else return(def);
}

// Set a string preference
sv.prefs.setString = function (pref, value, overwrite) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"]
		.getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (overwrite == false & prefs.hasStringPref(pref)) return;
	prefs.setStringPref(pref, value);
}

// Display a dialog box to change a preference string
sv.prefs.askString = function (pref, defvalue) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"]
		.getService(Components.interfaces.koIPrefService);
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

// Set default preferences
sv.prefs.checkAll = function (revert) {
	var prefset = Components.classes['@activestate.com/koPrefService;1']
		.getService(Components.interfaces.koIPrefService).prefs;
	for (var i in sv.prefs.defaults) {
		var el;
		var p = sv.prefs.defaults[i];
		switch(typeof(p)) {
		 case "number":
			el = (parseInt(p) == p)? "Long" : "Double";
			break;
		 case "boolean":
			el = "Boolean";
			break;
		 case "string":
		 default:
			el = "String";
			p = p.toString();
		}
		if (revert // take all
			|| !prefset.hasPref(i) // if missing at all
			|| (prefset["has" + el + "Pref"](i) // has right type, but empty
			&& !prefset["get" + el + "Pref"](i))) {
			prefset.deletePref(i); // To avoid _checkPrefType error
			prefset["set" + el + "Pref"](i, p);
		};
	}
}
// Preferences (default values, or values reset on each start)
sv.prefs.checkAll(false);
// Try getting a reasonable default R interpreter, if none is defined
var svRDefaultInterpreter = sv.prefs.getString("svRDefaultInterpreter", "");
// Is this R interpreter still there?
if (svRDefaultInterpreter != "" &&
	sv.tools.file.exists(svRDefaultInterpreter) == sv.tools.file.TYPE_NONE) {
	// We don't warn the user that current R is not found here because Komodo
	// is still loading. Will be rechecked on time in sv.command.startR()
	sv.prefs.setString("svRDefaultInterpreter", "", true);
	svRDefaultInterpreter = "";
}
// If no default R interpreter defined, try to get reasonable default one
if (svRDefaultInterpreter == "") {
	// This is platform-dependent...
	if (navigator.platform.indexOf("Win") === 0) {
		svRDefaultInterpreter = sv.tools.file.whereIs("Rgui");
		if (svRDefaultInterpreter) {
			sv.prefs.setString("svRDefaultInterpreter", svRDefaultInterpreter,
				true);
			sv.prefs.setString("svRApplication", "r-gui", true);		
		}
	} else { // Linux or Mac OS X
		svRDefaultInterpreter = sv.tools.file.whereIs("R");
		if (svRDefaultInterpreter) {
			// Check if GnomeTerm Konsole or xfce4term are there, use them
			if (sv.tools.file.exists("gnome-terminal") !=
				sv.tools.file.TYPE_NONE) {
				sv.prefs.setString("svRApplication", "r-gnome-term", true);
			} else if (sv.tools.file.exists("konsole") !=
				sv.tools.file.TYPE_NONE) {
				sv.prefs.setString("svRApplication", "r-kde-term", true);
			} else if (sv.tools.file.exists("xfce4-terminal") !=
				sv.tools.file.TYPE_NONE) {
				sv.prefs.setString("svRApplication", "r-xfce4-term", true);
			} else { // Use default terminal
				sv.prefs.setString("svRApplication", "r-terminal", true);
			}
			sv.prefs.setString("svRDefaultInterpreter", svRDefaultInterpreter,
				true);
		}
	}
}

// Simplify update of MRU lists
sv.prefs.mru = function (mru, reset, items, sep) {
	var mruList = "dialog-interpolationquery-" + mru + "Mru";
	// Do we reset the MRU list?
	if (reset === undefined) reset = false;
	if (reset == true) ko.mru.reset(mruList);

	// Do we need to split items (when sep is defined)?
	if (sep !== undefined) items = items.split(sep);

	// Add each item in items in inverse order
	for (var i = items.length - 1; i >= 0; i--) {
		if (items[i] != "")
			ko.mru.add(mruList, items[i], true);
	}
}

// Simplify storage of default tooltips for arguments in interpolation queries
sv.prefs.tip = function (arg, tip) {
	sv.prefs.setString("dialog-tip-" + arg, tip, true);
}

// This is required by sv.helpContext() for attaching help to snippets
// Create empty preference sets to be used with snippet help system hack
// [[%pref:R-help:value]] which displays nothing when the snippet is used
// but can be used to retrieve value to display a particular snippet help page
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

// Set default dataset to 'df'
// Should be reset to a more useful value during first use of R
sv.prefs.setString("r.active.data.frame", "<df>", true);
sv.prefs.setString("r.active.data.frame.d", "<df>$", true);
sv.prefs.setString("r.active.lm", "<lm>", true);
sv.prefs.setString("r.active.pcomp", "<pcomp>", true);
sv.prefs.mru("var", true, "");
sv.prefs.mru("var2", true, "");
sv.prefs.mru("x", true, "");
sv.prefs.mru("x2", true, "");
sv.prefs.mru("y", true, "");
sv.prefs.mru("factor", true, "");
sv.prefs.mru("factor2", true, "");
sv.prefs.mru("blockFactor", true, "");

//// (re)initialize a series of MRU for snippets' %ask constructs //////////////
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

// For multivariate stats with 'pcomp' object in the SciViews package
sv.prefs.mru("scale", true, 'TRUE|FALSE', "|");
sv.prefs.mru("loadings", true, 'TRUE|FALSE', "|");
sv.prefs.mru("sort.loadings", true, 'TRUE|FALSE', "|");
sv.prefs.mru("screetype", true, '"barplot"|"lines"', "|");
sv.prefs.mru("pc.biplot", true, 'TRUE|FALSE', "|");
sv.prefs.mru("choices", true, '1:2|2:3|c(1, 3)|c(1, 4)|c(2, 4)|3:4', "|");
sv.prefs.mru("text.pos", true, '1|2|3|4|NULL', "|");
sv.prefs.mru("labels", false, 'NULL|FALSE|<factor>|list(group = <factor>)', "|");

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

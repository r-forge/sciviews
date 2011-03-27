// SciViews-K preference code
// SciViews-K preferences management ('sv.prefs' namespace)
// Define default preferences values for SciViews-K and MRU lists
// Copyright (c) 2008-2010, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.pref.getPref(pref, def); // Get a preference, use 'def' is not found
// sv.pref.setPref(pref, value, overwrite); // Set a preference string
// sv.prefs.askString(pref, defvalue); // Ask for the value of a preference
// sv.prefs.mru(mru, reset, items, sep); //Simplify update of MRU lists
//
////////////////////////////////////////////////////////////////////////////////

if (sv.pref == undefined) sv.pref = {};

//This can be used in the Preferences page to set/restore missing values:
//sv.prefs.checkAll()

// sv.prefs.defaults[preferenceName] = preferenceValue
sv.defaultPrefs = {
	'sciviews.ko.port': 7052,
	'sciviews.r.port': 8888,
	'sciviews.r.host': '127.0.0.1',
	'sciviews.client.id': 'SciViewsK',
	'sciviews.client.type': 'socket',
	'sciviews.conn.type': 'socket',
	svRDefaultInterpreter: '',
	svRApplication: '',
	svRArgs: '--quiet',
    'r.csv.dec': '.',
	'r.csv.sep': ',',
	'r.application': '', // XXX this one is of questionable usefulness
	CRANMirror: 'http://cran.r-project.org/',
	RHelpCommand: 'javascript:sv.r.help(\"%w\")',
    'sciviews.pkgs.sciviews' : 'false'
	//*Future preferences:*
	//sciviews.rhelp.open_in = [tab, window]
	//sciviews.r.auto-start
};

//// Set default preferences
sv.checkAllPref = function sv_checkAllPref(revert) {
	var val, rev;
	for (var i in sv.defaultPrefs) {
		val = sv.pref.getPref(i);
		rev = revert || (typeof(val) == "number" && isNaN(val)) || val == "None"
			|| (sv.defaultPrefs[i] != '' && val == '');
		sv.pref.setPref(i, sv.defaultPrefs[i], rev);
	}
};


(function() {

/* Preferences */
var prefset = Components.classes["@activestate.com/koPrefService;1"]
	.getService(Components.interfaces.koIPrefService).prefs;

this.prefset = prefset;

this.getPref = function(prefName, defaultValue) {
	var ret, typeName, type;
	if (prefset.hasPref(prefName)) {
		type = ['long', 'double', 'boolean', 'string'].indexOf(prefset.getPrefType(prefName));
		if (type == -1) return undefined;
		typeName = ['Long', 'Double', 'Boolean', 'String'][type];
		ret = prefset['get' + typeName + 'Pref'](prefName);
	} else ret = defaultValue;
	return ret;
}

this.setPref = function(prefName, value, overwrite, asInt) {
	var typeName, type;
	if (prefset.hasPref(prefName)) {
		if (overwrite === false) return '';
		type = prefset.getPrefType(prefName);
	} else {
		type = typeof value;
		if (type == 'number') type =  asInt? "long" : "double";
	}
	type = ['double', 'long', 'boolean', 'string'].indexOf(type);
	if (type == -1 || type == null) return undefined;
	typeName = ['Double', 'Long', 'Boolean', 'String'][type];
	prefset['set' + typeName + 'Pref'](prefName, value);
	return typeName;
}

this.deletePref = function(prefName) {
	prefset.deletePref(prefName);
	return prefset.hasPref(prefName);
}


// Display a dialog box to change a preference string
this.ask = function (pref, defvalue) {
	// If defvalue is defined, use it, otherwise, use current pref value
	var prefExists = prefset.hasPref(pref);
	if (defvalue == null) {
		defvalue =  prefExists ? this.getPref(pref) : "";
	}
	var prefType = prefExists ? prefset.getPrefType(pref) : 'undefined';
	var validator = {
		'double': function(win, x) (/^[+-]?\d+\.\d*([eE][+-]?\d+)?$/).test(x),
		'long': function(win,x) x == parseInt(x),
		'boolean': function(win, x) ["true", "false", "0", "1"].indexOf(x.toLowerCase()) != -1,
		'string': function(win,x) true,
		'undefined': function(win,x) true
	}
	// Display a dialog box to change the preference value
	var newVal = ko.dialogs.prompt("Change preference value" +
		(prefType == 'undefined' ? "" : " (" + prefType + ")") +
		" for:", pref, 	defvalue, "SciViews-K preference", "svPref" + pref,
		validator[prefType]);

	if (prefType == 'undefined') {
		for (prefType in validator) if (validator[prefType](null, newVal)) break;
	}
	switch(prefType) {
		case 'boolean': newVal = !!eval(newVal.toLowerCase()); break;
		case 'long': newVal = parseInt(newVal); break;
		case 'double': newVal = parseFloat(newVal); break;
	}
	if (newVal != null) this.setPref(pref, newVal);
}


}).apply(sv.pref);


sv.checkAllPref(false);

// XXX: Temporarily removed all sv.prefs.mru* entries

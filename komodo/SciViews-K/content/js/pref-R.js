// SciViews-K R preferences panel functions
// Copyright (c) 2009, Ph. Grosjean (phgrosjean@sciviews.org) & Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// svPrefR_OnPreferencePageOK(prefset);         // User click OK
// PrefR_OnLoad();                            // R preference widow loaded
// svPrefR_loadRExecutable();                   // Select R executable
// svPrefR_finishSpecifyingExecutable(path);    // Set R executable
////////////////////////////////////////////////////////////////////////////////
//
// TODO: use 'R' simply as default R (terminal on Win/Mac, or on Linux)

/* TODO: prefs to include:
* address for remote R (sv.socket.host)? (if not localhost - disable source* commands)
* R help: show in tab (sidebar - another TODO) or in separate window
* R Site search url (%S replaced by topic)
*/

// TODO: rework R applications list, include "Find in path" item, similar to other
// languages' interpeters in Komodo. Add new function to find installed R's and
// populate the interpreter list (depending on the platform).

var sv;

// for editable menulists: append new element if necessary
function editMenulist(el) {
	var curValue = sv.tools.strings.trim(el.value);
	if (!curValue) return;
	var values = [], val;
	for (var j = 0; j < el.itemCount; j++) {
		val = el.getItemAtIndex(j).value;
		if (val == curValue) {
			el.selectedIndex = j;
			return;
		}
		values.push(val);
	}
	el.appendItem(curValue, curValue, null);
}

// Used at startup:
function menuListSetValues(attribute) {
	if (!attribute) attribute = 'values';
	var ml = document.getElementsByTagName('menulist');
	var el, values;
	for (var i = 0; i < ml.length; i++) {
		el = ml[i];
		if (el.hasAttribute(attribute)) {
			values = el.getAttribute(attribute).split(/\s+/);
			for (var k in values) {
                el.appendItem(values[k], values[k], null);
			}
		}
	}
}

// Used on closing. Store menulist items in an attribute "value"
function menuListGetValues(attribute) {
	if (!attribute) attribute = 'values';
	var ml = document.getElementsByTagName('menulist');
	var el, values;
	for (var i = 0; i < ml.length; i++) {
		el = ml[i];
		if (el.hasAttribute(attribute)) {
			values = [];
			for (var k = 0; k < el.itemCount; k++) {
				values.push(el.getItemAtIndex(k).value);
			}
			el.setAttribute(attribute, values.join(" "));
		}
	}
}

function PrefR_menulistSetValue(menuList, value, attr, vdefault) {
	var n = menuList.itemCount;
	var item;
	for (var i = 0; i <= n; i++) {
		item = menuList.getItemAtIndex(i);
		if (item) {
			var attr1 = item.hasAttribute(attr)? item.getAttribute(attr) : vdefault;
			if (attr1 == value) {
				menuList.selectedIndex = i;
				break;
			}
		}
	}
}

function PrefR_OnLoad() {
	// Get the sv object:
	var p = parent;
	while (p.opener && (p = p.opener) && !sv) if (p.sv) sv = p.sv;

	var os = Components.classes['@activestate.com/koOs;1']
        .getService(Components.interfaces.koIOs);

	var prefExecutable;
	var prefset = parent.hPrefWindow.prefset;
	var prefName = 'svRDefaultInterpreter';
	document.getElementById("svRQuiet")
        .setAttribute("checked", sv.prefs.getString("svRQuiet"));
	if (!prefset.hasStringPref(prefName) || !prefset.getStringPref(prefName)) {
		prefExecutable = sv.tools.file.whereIs("R");
		prefset.setStringPref(prefName, prefExecutable);
	}
	prefExecutable = sv.prefs.getString("svRDefaultInterpreter")
	PrefR_setRAppMenu(document.getElementById("svRApplication"));
	PrefR_menulistSetValue(document.getElementById("svRApplication"),
        os.path.basename(prefExecutable), "app",  "R");
	document.getElementById("svRDefaultInterpreter").value = prefExecutable;

	if (!PrefR_UpdateCranMirrors(true))
        PrefR_UpdateCranMirrors(false);

	menuListSetValues();
	sv.prefs.checkAll();
	PrefR_svRApplicationUpdate(null);
	parent.hPrefWindow.onpageload();
}

function OnPreferencePageLoading(prefset) {
	//PrefR_svRApplicationOnSelect(null);
}

function OnPreferencePageOK(prefset) {
	prefset = parent.hPrefWindow.prefset;
        prefset.setStringPref("svRDefaultInterpreter",
        document.getElementById("svRDefaultInterpreter").value);
        prefset.setStringPref("svRApplication",
        document.getElementById('svRApplication')
        .selectedItem.getAttribute("value"));
	prefset.setStringPref("svRApplicationId",
        document.getElementById('svRApplication').selectedItem.id);
	prefset.setStringPref("svRQuiet",
        document.getElementById('svRQuiet')
        .getAttribute("checked") == "true");

	var outDec = document.getElementById('r.csv.dec').value;
	var outSep = document.getElementById('r.csv.sep').value;

    // "Preference widget" does not save newly added values for some reason:
	prefset.setStringPref("r.csv.sep", outSep);

    if (outDec == outSep) {
        parent.switchToPanel("svPrefRItem");
        ko.dialogs.alert(
            "Decimal separator cannot be the same as field separator.", null,
            "SciViews-K preferences");
        return false;
    }

	//The 'r.csv.*.arg' prefs are replaced by simply 'r.csv.dec'/'r.csv.sep'
	//as they escaped strings anyway (e.g. string "\\t" not tab character)

	if (sv.r.running) {
		sv.r.eval('options(OutDec = "' + outDec + '", ' +
                'OutSep = "' + outSep + '")', true);
	}

	menuListGetValues();
	return true;
}

function PrefR_svRApplicationOnSelect(event) {
	var el = document.getElementById("svRApplication");
	var sel = el.selectedItem;
	var app = sel.hasAttribute("app")? sel.getAttribute("app") : "R";
	// PhG: always get a good starting value - DO NOT ELIMINATE THIS!
	var svRDefaultInterpreter = PrefR_locateApp(app);
	document.getElementById("svRDefaultInterpreter").value
		= svRDefaultInterpreter;
	
	// Delegate to PrefR_svRApplicationUpdate()
 	return PrefR_svRApplicationUpdate(event);
}

function PrefR_svRApplicationUpdate(event) {
	var el = document.getElementById("svRApplication");
	var prefattribute = el.getAttribute("prefattribute");
	var sel = el.selectedItem;
	var data = sel.getAttribute(prefattribute);
	var cmdfield = document.getElementById('R_command');

	var svRDefaultInterpreter = document
        .getElementById("svRDefaultInterpreter").value;

	// Check if svRDefaultInterpreter exists on disk
	if (!sv.tools.file.exists(svRDefaultInterpreter)) {
		// Indicate the problem in the command...
		cmdfield.value = "??? R interpreter '" + svRDefaultInterpreter +
                "' not found!";
		return false;
	}

	var Quiet = " ";
	if (document.getElementById("svRQuiet")
        .getAttribute("checked") == "true") Quiet = "--quiet ";

	var cwd = sv.tools.file.path("ProfD", "extensions",
        "sciviewsk@sciviews.org", "defaults");

	// PhG: note that the path here is now the full path, application included!
	data = data.replace("%Path%", svRDefaultInterpreter)
        .replace("%title%", "SciViews-R").replace("%cwd%", cwd)
        .replace("%quiet%", Quiet);

	cmdfield.value = data;
	return true;
}

function PrefR_setExecutable(path) {
	if (!path || !sv.tools.file.exists(path)) {
		var os = Components.classes['@activestate.com/koOs;1']
                .getService(Components.interfaces.koIOs);

		path = document.getElementById("svRDefaultInterpreter").value;
		// Special treatment for the .app items: open the parent directory!
		var defpath = path;
		if (path.match(/\.app$/) == ".app") defpath = os.path.dirname(path);
		path = ko.filepicker.openExeFile(defpath);
	}

	PrefR_menulistSetValue(document.getElementById("svRApplication"),
        os.path.basename(path), "app",  "R");
	document.getElementById("svRDefaultInterpreter").value = os.path.abspath(path);
	PrefR_svRApplicationUpdate(null);
}

// PhG: I use this to get a first guess of the application location
function PrefR_locateApp(appName) {
	// 1) Look if app is an existing file
	if (sv.tools.file.exists(appName)) {
		return(appName);
	}
	// 2) Try to locate the application
	//TODO: use basename here?
	var appPath = sv.tools.file.whereIs(appName);
	if (appPath != null) {
		return(appPath);
	}
	// 3) For R.app and the like on the Macintosh, I should really look at the
	// /Applications directory
	appName = "/Applications/" + appName;
	if (sv.tools.file.exists(appName)) {
		return(appName);
	} else {
		// Not found? What else can I do?
		return(null);
	}
}

function PrefR_setRAppMenu(menuList) {
	var isLinux = navigator.platform.toLowerCase().indexOf("linux") > -1;
	var isMac = navigator.platform.toLowerCase().indexOf("mac") > -1;
	var isWin = navigator.platform.toLowerCase().indexOf("win") == 0;

	var validPlatforms, showItem;
	var platform = navigator.platform;
	var anyItem = false;

	for (var i = menuList.itemCount; i >= 0; i--) {
		var item = menuList.getItemAtIndex(i);
		try {
			validPlatforms = item.getAttribute("platform").split(/[,\s]+/);
			showItem = false;
			for (var j in validPlatforms) {
				if (platform.indexOf(validPlatforms[j]) > -1) {
					var appName = item.getAttribute("which");
					if (isLinux || isWin) {
						appName = appName.split(/[, ]+/);
						var res = true;
						for (var k in appName)
                                                res = res && !!sv.tools.file.whereIs(appName[k]);

						if (res) {
							showItem = true;
							break;
						}
					} else if (isMac) {
						// Check that we find the application
						if (appName == "R" || sv.tools.file.exists(appName)) {
							showItem = true;
							break;
						}
					}
				}
			}
			if (!showItem) {
				menuList.removeItemAt(i);
			} else {
				anyItem = true;
			}
		} catch(e) { }
	}
	// If there is at least one item available, hide the message to install R
	if (anyItem) {
		document.getElementById("svRinstallMessage").setAttribute("hidden", "true");
	}
}

// Get CRAN mirrors list - independently of R
function PrefR_UpdateCranMirrors(localOnly) {
	var sv_file = sv.tools.file;

	// Get data in as CSV:
	var csvName = "CRAN_mirrors.csv";
	var localDir = sv_file.path("PrefD", "extensions", "sciviewsk@sciviews.org");
	var path, csvContent;
	var arrData;
	if (!localOnly) {
		try {
			csvContent = sv_file.readURI("http://cran.r-project.org/" + csvName);
			//sv_file.write(localCopy, csvContent, 'utf-8');
		} catch(e) {}
	}

	var nativeJSON = Components.classes["@mozilla.org/dom/json;1"]
        .createInstance(Components.interfaces.nsIJSON);

	var jsonFile = sv_file.path(localDir, "CRAN_mirrors.json");
	var alreadyCached = false;
	if (!csvContent) {
		// First, check if there is serialized version:
		alreadyCached = sv_file.exists(jsonFile);
		if (alreadyCached) {
			arrData = nativeJSON.decode(sv_file.read(jsonFile));
			//sv.cmdout.append("Read from: JSON");
		} else {
			var localPaths = [ ];

			var platform = navigator.platform.toLowerCase().substr(0,3);
			if (platform == "win") // TODO: what is the pref is not set??
                        localPaths.push(sv_file.path(sv.prefs.getString("svRDefaultInterpreter"),
                        "../../doc"));
			else { // if (platform == "lin")
				localPaths.push('/usr/share/R/doc'); 	// try other paths: // mac: ????
				localPaths.push('/usr/local/share/R/doc');
			}
			var file;
			for (i in localPaths) {
				file = sv_file.getfile(localPaths[i], csvName);
				if (file.exists()) {
					csvContent = sv_file.read(file.path);
					//sv.cmdout.append("Read from: " + localPaths[i]);
					break;
				}
			}
		}
	}
	if (!csvContent && !arrData)	return false;
	// TODO: Add error message when mirrors list cannot be obtained.

	if (!arrData) {
		// Convert CSV string to Array:
		arrData = CSVToArray(csvContent);
		var colNames = arrData.shift(1);
		var colName = colNames.indexOf("Name");
		var colURL = colNames.indexOf("URL");
		var colOK = colNames.indexOf("OK");
		var name, url, item;
		for (i in arrData) {
			item = arrData[i];
			if (item[colOK] == "1"
                        // fix for broken entries:
                        && (item[colURL].search(/^(f|ht)tp:\/\//) === 0)
                        ) {
				arrData[i] = [item[colName], item[colURL]];
			}
		}
		// Add main server at the beginning:
		arrData.unshift(["Main CRAN server", "http://cran.r-project.org/"]);
	}
	if (!arrData)	return false;

	if (!localOnly || !alreadyCached) {
		// If updated from web, or not cached yet,
		// serialize and save to file for faster later use:
		sv_file.write(jsonFile, nativeJSON.encode(arrData), 'utf-8');
	}

	// Put arrData into MenuList:
	var menuList = document.getElementById("CRANMirror");
	var value = menuList.value? menuList.value : sv.prefs.getString("CRANMirror");
	menuList.removeAllItems();
	for (i in arrData) {
		if (arrData[i][0])
                menuList.appendItem(arrData[i][0], arrData[i][1], arrData[i][1]);
	}
	menuList.value = value;
	return true;
}

// From: http://www.bennadel.com/index.cfm?dax=blog:1504.view
function CSVToArray(strData, strDelimiter){
	strDelimiter = (strDelimiter || ",");
	var objPattern = new RegExp((
        // Delimiters.
        "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
        // Quoted fields.
        "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
        // Standard fields.
        "([^\"\\" + strDelimiter + "\\r\\n]*))"
        ), "gi");
	var arrData = [[]];
	var arrMatches = objPattern.exec(strData);
	while (arrMatches) {
		var strMatchedDelimiter = arrMatches[1];
		if (strMatchedDelimiter.length &&
			(strMatchedDelimiter != strDelimiter)) {
			arrData.push([]);
                        }
		if (arrMatches[2]) {
			var strMatchedValue = arrMatches[2]
                        .replace(new RegExp( "\"\"", "g" ),	"\"");
		} else {
			var strMatchedValue = arrMatches[3];
		}
		arrData[arrData.length - 1].push(strMatchedValue);
		arrMatches = objPattern.exec(strData);
	}
	return(arrData);
}

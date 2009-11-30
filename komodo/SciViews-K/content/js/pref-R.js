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
// TODO: use 'R' simply as default R (terminal on Win/Mac, or ? on Linux)

/* TODO: prefs to include:
 * session directory ??? (dir, datadir, scriptdir, reportdir)
 * address for remote R (sv.socket.host)? (if not localhost - disable source* commands)
 * default CRAN mirror updated also by sv.r.pkg.chooseCRANMirror
 * R help: show in tab (sidebar - another TODO) or in separate window
 * R Site search url (%S replaced by topic)
 */

// TODO: rework R applications list, include "Find in path" item, similar to other
// languages' interpeters in Komodo. Add new function to find installed R's and
// populate the interpreter list (depending on the platform).

var sv;

function PrefR_menulistSetValue(menuList, value, attr, vdefault) {
	var n = menuList.itemCount;
	var item;
	for (var i = 0; i <= n; i++) {
		item = menuList.getItemAtIndex(i);
		if (item) {
			var attr1 =  item.hasAttribute(attr)? item.getAttribute(attr) : vdefault;
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
	while (p.opener && (p = p.opener) && !sv) if (p.sv) 	sv = p.sv;

	var prefExecutable;
	var prefset = parent.hPrefWindow.prefset;
	var prefName = 'svRDefaultInterpreter';
	if (!prefset.hasStringPref(prefName) || !prefset.getStringPref(prefName)) {
		prefExecutable = sv.tools.file.whereIs("R");
		prefset.setStringPref(prefName, prefExecutable);
	}
	PrefR_setRAppMenu(document.getElementById("svRApplication"));

	//PrefR_InterfaceUpdate();
	if (!PrefR_UpdateCranMirrors(true))
		PrefR_UpdateCranMirrors(false);

	parent.hPrefWindow.onpageload();
}

function OnPreferencePageLoading(prefset) {
	PrefR_svRApplicationOnSelect(null);
}

function OnPreferencePageOK(prefset) {
	prefset = parent.hPrefWindow.prefset;
    //prefset.setStringPref("svRDefaultInterpreter",
     //                     document.getElementById("svRDefaultInterpreter")
	//					  .value);
    //prefset.setStringPref("svRApplication",
	//					  document.getElementById('svRApplication')
	//					  .selectedItem.getAttribute("data"));
	prefset.setStringPref("svRApplicationId",
					  document.getElementById('svRApplication')
					  .selectedItem.id);
	return true;
}

function PrefR_svRApplicationOnSelect(event) {
	var el = document.getElementById("svRApplication");
	var prefattribute = el.getAttribute("prefattribute");
	var sel = el.selectedItem;
	var data = sel.getAttribute(prefattribute);
	var app = sel.hasAttribute("app")? sel.getAttribute("app") : "R";

	var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);

	var path = os.path.normpath(os.path.dirname(
			document.getElementById("svRDefaultInterpreter").value));
	if (path) path +=  os.sep;

	var svRDefaultInterpreter = path + app;

	document.getElementById("svRDefaultInterpreter").value
		= svRDefaultInterpreter;

	data = data.replace("%Path%", path).replace("%title%", "SciViews-K")
		.replace("%cwd%", os.getcwd());

	document.getElementById('R_command').value = data;
	return true;
}

function PrefR_setExecutable(path) {
	if (!path || !sv.tools.file.exists(path)) {
		var os = Components.classes['@activestate.com/koOs;1']
			.getService(Components.interfaces.koIOs);

		path = document.getElementById("svRDefaultInterpreter").value;
		path = ko.filepicker.openExeFile(path);
	}

	PrefR_menulistSetValue(document.getElementById("svRApplication"),
					 os.path.basename(path), "app",  "R");
	document.getElementById("svRDefaultInterpreter").value = os.path.abspath(path);
	PrefR_svRApplicationOnSelect(null);
}

function PrefR_setRAppMenu(menuList) {
	var isLinux = navigator.platform.toLowerCase().indexOf("linux") > -1;
	var isMac = navigator.platform.toLowerCase().indexOf("mac") > -1;
	var isWin = navigator.platform.toLowerCase().indexOf("win") == 0;

	var validPlatforms, showItem;
	var platform = navigator.platform;

	for (var i = menuList.itemCount; i >= 0; i--) {
		var item = menuList.getItemAtIndex(i);
		try {
			validPlatforms = item.getAttribute("platform").
				split(/[,\s]+/);
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
			if (!showItem)
				menuList.removeItemAt(i);
		} catch(e) {	}
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
		if (alreadyCached = sv_file.exists(jsonFile)) {
			arrData = nativeJSON.decode(sv_file.read(jsonFile));
			//sv.cmdout.append("Read from: JSON");
		} else {
			var localPaths = [ ];

			var platform = navigator.platform.toLowerCase().substr(0,3);
			if (platform == "win") // TODO: what is the pref is not set??
				localPaths.push(sv_file.path(sv.prefs.getString("svRDefaultInterpreter"),
									   "../../doc", csvName));
			else { // if (platform == "lin")
				localPaths.push('/usr/share/R/doc'); 	// try other paths: // mac: ????
				localPaths.push('/usr/local/share/R/doc');
			}
			for (i in localPaths) {
				if (sv_file.exists(localPaths[i])) {
					csvContent = sv_file.read(localPaths[i]);
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
			if (item[colOK] == "1") {
				arrData[i] = [item[colName], item[colURL]];
			}
		}
		//sv.cmdout.append("New arrData");
	}
	if (!arrData)	return false;

	if (!localOnly || !alreadyCached) {
		// If updated from web, or not cached yet,
		// serialize and save to file for faster later use:
		sv_file.write(jsonFile, nativeJSON.encode(arrData), 'utf-8');
		//sv.cmdout.append("Cached now.");
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
function CSVToArray( strData, strDelimiter ){
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
	var arrMatches = null;
	while (arrMatches = objPattern.exec( strData )) {
		var strMatchedDelimiter = arrMatches[ 1 ];
		if (strMatchedDelimiter.length &&
			(strMatchedDelimiter != strDelimiter)) {
			arrData.push( [] );
		}
		if (arrMatches[ 2 ]){
			var strMatchedValue = arrMatches[ 2 ].replace(
				new RegExp( "\"\"", "g" ),	"\"");
		} else {
			var strMatchedValue = arrMatches[ 3 ];
		}
		arrData[ arrData.length - 1 ].push( strMatchedValue );
	}
	return( arrData );
}

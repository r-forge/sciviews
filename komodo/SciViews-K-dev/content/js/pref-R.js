// SciViews-K R preferences panel functions
// Copyright (c) 2009-2010 Ph. Grosjean (phgrosjean@sciviews.org) & Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// svPrefR_OnPreferencePageOK(prefset);         // User click OK
// PrefR_OnLoad();                            	// R preference widow loaded
// TODO: update this list...
//////////////////////////////////////////////////////////////////////////////


/* TODO: prefs to include:
* address for remote R (sv.socket.host)? (if not localhost - disable source* commands)
* R help: show in tab (sidebar - another TODO) or in separate window
* R Site search url (%S replaced by topic)
*/


var sv;

// For menulists, take the value argument/(or text in the textbox), and append
// it as new element to the list if it is new, otherwise set as selected
function editMenulist(el, value) {
	var curValue = (!value)?  sv.tools.string.trim(el.value) : value;
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

// Used at startup
function menuListSetValues(attribute) {
	if (!attribute) attribute = 'values';
	var ml = document.getElementsByTagName('menulist');
	var el, values, v;
	for (var i = 0; i < ml.length; i++) {
		el = ml[i];
		if (el.hasAttribute(attribute)) {
			values = el.getAttribute(attribute).split(/\s+/);
			el.removeAllItems(); /// XXX
			for (var k in values) {
                v = unescape(values[k]);
                el.appendItem(v, v, null);
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
		if (el.editable && el.hasAttribute(attribute)) {
			values = [];
			for (var k = 0; k < el.itemCount; k++) {
				values.push(escape(el.getItemAtIndex(k).value));
			}
			el.setAttribute(attribute, values.join(" "));
		}
	}
}

function PrefR_menulistSetValue(menuList, value, attrName, vdefault) {
	var n = menuList.itemCount;
	var item;
	for (var i = 0; i <= n; i++) {
		item = menuList.getItemAtIndex(i);
		if (item) {
			var attr1 = item.hasAttribute(attrName)? item.getAttribute(attrName)
            	: vdefault;
			if (attr1 == value) {
				menuList.selectedIndex = i;
				break;
			}
		}
	}
}

// List of R applications
// Constructor
function _App(id, name, path, app, required, platform) {
	this.id = id;
	this.name = name;
	this.path = path;
	this.app = app;
	this.required = required? required.split(/\s*,\s*/) : [];
	this.platform = platform? platform.split(/\s*,\s*/): [];
}

var apps = [
new _App("", "Choose...", "", "", "", "Lin,Mac,Win"),
new _App("r-terminal", "in default terminal", "\"%Path%\" %args%", "R", "R", "Lin,Mac"),
new _App("r-terminal", "in console window", "\"%Path%\" %args%", "R.exe", "R", "Win"),
new _App("r-gnome-term", "in Gnome terminal", "gnome-terminal --hide-menubar --working-directory='%cwd%' -t '%title%' -x '%Path%' %args%", "R", "gnome-terminal,R", "Lin"),
new _App("r-kde-term", "in Konsole", "konsole --workdir '%cwd%' --title %title% -e \"%Path%\" %args%", "R", "konsole,R", "Lin"),
new _App("r-xfce4-term", "in XFCE terminal", "xfce4-terminal --title \"%title%\" -x \"%Path%\" %args%", "R",  "xfce4-terminal,R", "Lin"),
new _App("r-app", "R app", "open -a \"%Path%\" \"%cwd%\"", "R.app", "/Applications/R.app", "Mac"),
new _App("r64-app", "R64 app", "open -a \"%Path%\" \"%cwd%\"", "R64.app", "/Applications/R64.app", "Mac"),
new _App("svr-app", "SciViews R app", "open -a \"%Path%\" \"%cwd%\"", "SciViews R.app", "/Applications/SciViews R.app", "Mac"),
new _App("svr64-app", "SciViews R64 app", "open -a \"%Path%\" \"%cwd%\"", "SciViews R64.app", "/Applications/SciViews R64.app", "Mac"),
new _App("r-gui", "R GUI", "Rgui.exe", "\"%Path%\" --sdi %args%", "Rgui", "Win"),
new _App("r-tk", "R Tk GUI", "\"%Path%\" --interactive --gui:Tk %args%", "R", "R", "Lin,Mac")
];


function PrefR_OnLoad() {
	// Get the sv object:
	var p = parent;
	while (p.opener && (p = p.opener) && !sv) if (p.sv) sv = p.sv;
    //p = parent;
	//while (p.opener && (p = p.opener) && !ko) if (p.ko) ko = p.ko;

	var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);

    var platform = navigator.platform.substr(0,3);
	apps = apps.filter(function(x) (x.platform.indexOf(platform) != -1)
					   && (!x.required.length
						   || x.required.every(
								function(y) sv.tools.file.whereIs(y).length != 0)
						   )
					   );

    var menu = document.getElementById("svRApplication");
    menu.removeAllItems();
    for (var i in apps) menu.appendItem(apps[i].label, i, null);

    // update cran mirror list (first local, then tries remote at CRAN)
	if (!PrefR_UpdateCranMirrors(true)) PrefR_UpdateCranMirrors(false);

	menuListSetValues(); // Restores saved menu values
	sv.checkAllPref(); // Check if all preference values are ok, if not, restore defaults
    PrefR_PopulateRInterps();
	// TODO: this raises an exception if pref('svRDefaultInterpreter')
	// 		 is not among the options, do some checking here
	parent.hPrefWindow.onpageload();
    PrefR_updateCommandLine(true);
}


//TODO: check if there is new R version installed and ask whether to switch to it.
function PrefR_PopulateRInterps() {
	var prefset = parent.hPrefWindow.prefset;

    var prefExecutable = prefset.getStringPref('svRDefaultInterpreter');

    var rs = new Array();
    var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);
    var menu = document.getElementById("svRDefaultInterpreter");

    ////////////////////////////////////
    switch (os.name) { //'posix', 'nt', 'mac', 'os2', 'ce', 'java', 'riscos'.
        case "nt":
        rs = rs.concat(sv.tools.file.whereIs("Rgui"));
        rs = rs.concat(sv.tools.file.whereIs("R"));
		rs.sort(); rs.reverse();
        break;
        case "mac":
        //FIXME: as I understand there are only 2 options on Mac, is it right?:
        rs = ["/Applications/R.app", "/Applications/R64.app"];
        // What about "SciViews R*.app" ???
        break;
        case "posix":
        default:
        rs = rs.concat(sv.tools.file.whereIs("R"));
    }
    rs.unshift(prefExecutable);

    for (var i in rs) {
        rs[i] = os.path.normpath(rs[i]);
        if (sv.tools.file.exists(rs[i]) == sv.tools.file.TYPE_NONE) {
            rs.splice(i, 1);
        }
    }
    rs = sv.tools.array.unique(rs); // Get rid of duplicates

	if(rs.indexOf(prefExecutable) == -1) {
		prefset.setStringPref('svRDefaultInterpreter', '');
		rs.unshift('');
	}

    menu.removeAllItems();
    for (var i in rs) {
        menu.appendItem(rs[i], rs[i], null);
    }

    if (rs.length > 0) {
        document.getElementById("no-avail-interps-message").hidden = true;
    }
}

function OnPreferencePageLoading(prefset) {
}

function OnPreferencePageOK(prefset) {

	var outDec = document.getElementById('r.csv.dec').value;
	var outSep = document.getElementById('r.csv.sep').value;

    // "Preference widget" does not save newly added values for some reason:
	prefset.setStringPref("r.csv.sep", outSep);

    if (outDec == outSep) {
        parent.switchToPanel("svPrefRItem");
        ko.dialogs.alert(
        "Decimal separator cannot be the same as field separator.", null,
        "SciViews-K preferences");
        return(false);
    }
	prefset.setStringPref("svRCommand", PrefR_updateCommandLine(false));

	if (outDec != prefset.getStringPref('r.csv.dec')
		|| outSep != prefset.getStringPref('r.csv.sep')) {
		sv.r.eval('options(OutDec="' + outDec + '", ' +
		'OutSep="' + outSep + '")', true);
	}

	// Set the client type
	//var clientType = document.getElementById('sciviews.client.type').value;
	//prefset.setStringPref("sciviews.client.type", clientType);
	// Check if selected item is different from current sv.clientType
	//if (clientType != sv.clientType)
	//	sv.alert("R server type changed", "The server type you selected will be" +
	//		" used after restarting of both R and Komodo!");

	//sv.socket.setSocketType(clientType);

	menuListGetValues();

	// Restart socket server if running and port changed
	//;var serverPort = document.getElementById('sciviews.ko.port').value;
	//XXX: Manual port setting is deprecated - it hardly ever works

	//if(sv.rconn.serverIsUp &&
		//serverPort != prefset.getLongPref("sciviews.ko.port")){ XXX
		//serverPort != sv.pref.getPref("sciviews.ko.port")) {
		//prefset.setStringPref("sciviews.ko.port", serverPort);
		//sv.socket.serverStart();
		//sv.socket.serverStart();
		//sv.rconn.restartSocketServer();
	//}
	return(true);
}

function svRDefaultInterpreterOnSelect(event) {
	var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);

	var menuApplication = document.getElementById("svRApplication");
    var menuInterpreters = document.getElementById("svRDefaultInterpreter");

	// Just in case
	if(sv.tools.file.exists(menuInterpreters.value) == sv.tools.file.TYPE_NONE) {
		ko.dialogs.alert("Cannot find file: " + menuInterpreters.value, null, "SciViews-K preferences");
	}

    var app = os.path.basename(menuInterpreters.value);

    if (!(menuApplication.value in apps) || apps[menuApplication.value].app != app) {
        var i;
        for (i in apps)
			if (apps[i].app == app) break;
        menuApplication.value = i;
    }

    PrefR_updateCommandLine(true);
}

//TODO: rename to PrefR_svRApplicationUpdate
function PrefR_svRApplicationOnSelect(event) {
	var menuApplication = document.getElementById("svRApplication");
    var menuInterpreters = document.getElementById("svRDefaultInterpreter");
	if (!(menuApplication.value in apps)) return;

    var app = apps[menuApplication.value].app;
	var sel = menuApplication.selectedItem;

	var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);

    if (os.path.basename(menuInterpreters.value) != app) {
        //TODO: modify to use with:
        //PrefR_menulistSetValue(menuInterpreters, value, "value", null);
        var item;
        for (var i = 0; i <= menuInterpreters.itemCount; i++) {
            item = menuInterpreters.getItemAtIndex(i);
            if (item) {
                if (os.path.basename(item.getAttribute("value")) == app) {
                    menuInterpreters.selectedIndex = i;
                    break;
                }
            }
        }
    }
    PrefR_updateCommandLine(true);
}

function PrefR_updateCommandLine(update) {
    var appId = document.getElementById("svRApplication").value;
	var appPath = document.getElementById("svRDefaultInterpreter").value;

     if(!appId || !appPath) return '';

    var cmdArgs = document.getElementById("svRArgs").value;
	var args1 = "";

	if(document.getElementById("sciviews.pkgs.sciviews").checked)
		args1 += " --svStartPkgs=SciViews,MASS,ellipse";

   	var cwd = sv.tools.file.path("ProfD", "extensions",
    "sciviewsk@sciviews.org", "defaults");

	cmdArgs = cmdArgs.replace(/\s*--[sm]di\b/, "");

	var argsPos = cmdArgs.indexOf("--args");
	if (argsPos != -1) {
		args1 += " " + sv.tools.string.trim(cmdArgs.substring(argsPos + 6));
		cmdArgs = cmdArgs.substring(0, argsPos);
	}

	args1 = sv.tools.string.trim(args1);
	if (args1)
		args1 = " --args " + args1;

    var cmd = apps[appId].path;
	cmd = cmd.replace("%Path%", appPath)
		.replace("%title%", "SciViews-R").replace("%cwd%", cwd)
		.replace("%args%", cmdArgs) + args1;

    if (update) {
        var cmdLabel = document.getElementById('R_command');
        cmdLabel.value = cmd;
    }

    return cmd;
}

function PrefR_setExecutable(path) {
    var menu = document.getElementById("svRDefaultInterpreter");

    if (!path || !sv.tools.file.exists(path)) {
		var os = Components.classes['@activestate.com/koOs;1']
        .getService(Components.interfaces.koIOs);

		path = menu.value;

        //Error: ko.uriparse is undefined
        path = ko.filepicker.openExeFile(os.path.dirname(path),
        os.path.basename(path));
	}
    if (!path) return;
    path = os.path.normpath(path);

    editMenulist(menu, path);
    menu.value = path;


}

// Get CRAN mirrors list - independently of R
function PrefR_UpdateCranMirrors(localOnly) {
	var svFile = sv.tools.file;

	// Get data in as CSV:
	var csvName = "CRAN_mirrors.csv";
	var localDir = svFile.path("PrefD", "extensions", "sciviewsk@sciviews.org");
	var path, csvContent;
	var arrData;
	if (!localOnly) {
		try {
			csvContent = svFile.readURI("http://cran.r-project.org/" + csvName);
			//svFile.write(localCopy, csvContent, 'utf-8');
		} catch(e) {}
	}

	var nativeJSON = Components.classes["@mozilla.org/dom/json;1"]
    .createInstance(Components.interfaces.nsIJSON);

	var jsonFile = svFile.path(localDir, "CRAN_mirrors.json");
	var alreadyCached = false;
	if (!csvContent) {
		// First, check if there is serialized version:
		alreadyCached = svFile.exists(jsonFile);
		if (alreadyCached) {
			arrData = nativeJSON.decode(svFile.read(jsonFile));
			//sv.cmdout.append("Read from: JSON");
		} else {
			var localPaths = [ ];

			var platform = navigator.platform.toLowerCase().substr(0,3);
			if (platform == "win") // TODO: what if the pref is not set??
				localPaths.push(svFile.path(sv.pref.getPref("svRDefaultInterpreter"),
					"../../doc"));
			else { // if (platform == "lin")
				localPaths.push('/usr/share/R/doc'); 	// try other paths: // mac: ????
				localPaths.push('/usr/local/share/R/doc');
			}
			var file;
			for (i in localPaths) {
				file = svFile.getfile(localPaths[i], csvName);
				if (file.exists()) {
					csvContent = svFile.read(file.path);
					//sv.cmdout.append("Read from: " + localPaths[i]);
					break;
				}
			}
		}
	}
	if (!csvContent && !arrData)	return(false);
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
            && (item[colURL].search(/^(f|ht)tp:\/\//) === 0)) {
				arrData[i] = [item[colName], item[colURL]];
			}
		}
		// Add main server at the beginning:
		arrData.unshift(["Main CRAN server", "http://cran.r-project.org/"]);
	}
	if (!arrData) return(false);

	if (!localOnly || !alreadyCached) {
		// If updated from web, or not cached yet,
		// serialize and save to file for faster later use:
		svFile.write(jsonFile, nativeJSON.encode(arrData), 'utf-8');
	}

	// Put arrData into MenuList
	var menuList = document.getElementById("CRANMirror");
	var value = menuList.value? menuList.value : sv.pref.getPref("CRANMirror");
	menuList.removeAllItems();
	for (i in arrData) {
		if (arrData[i][0])
        menuList.appendItem(arrData[i][0], arrData[i][1], arrData[i][1]);
	}
	menuList.value = value;
	return(true);
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

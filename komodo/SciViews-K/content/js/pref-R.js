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
	var curValue = (!value)?  sv.tools.strings.trim(el.value) : value;
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
		if (el.hasAttribute(attribute)) {
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
var apps = [
{ id:"r-terminal", label:"in default terminal", path:"\"%Path%\" %args%",
        app:"R", required:"R", platform:"Lin,Mac"},
{id:"r-terminal", label:"in console window", path:"\"%Path%\" %args%",
        app:"R.exe", required:"R", platform:"Win"},
{id:"r-gnome-term", label:"in Gnome terminal",
        path:"gnome-terminal --hide-menubar --working-directory='%cwd%' -t '%title%' -x '%Path%' %args%",
        app:"R", required:"gnome-terminal,R", platform:"Lin"},
{id:"r-kde-term", label:"in Konsole", app:"R",
        path:"konsole --workdir '%cwd%' --title %title% -e \"%Path%\" %args%",
        required:"konsole,R", platform:"Lin"},
{id:"r-xfce4-term", label:"in XFCE terminal", app:"R",
        path:"xfce4-terminal --title \"%title%\" -x \"%Path%\" %args%",
        required:"xfce4-terminal,R", platform:"Lin"},
{id:"r-app", label:"R app", path:"open -a \"%Path%\" \"%cwd%\"",
        app:"R.app",
        required:"/Applications/R.app", platform:"Mac"},
{id:"r64-app", label:"R64 app", path:"open -a \"%Path%\" \"%cwd%\"",
        app:"R64.app",
        required:"/Applications/R64.app", platform:"Mac"},
{id:"svr-app", label:"SciViews R app", path:"open -a \"%Path%\" \"%cwd%\"",
        app:"SciViews R.app",
        required:"/Applications/SciViews R.app", platform: "Mac"},
{id:"svr64-app", label:"SciViews R64 app", path:"open -a \"%Path%\" \"%cwd%\"",
        app:"SciViews R64.app",
        required:"/Applications/SciViews R64.app", platform:"Mac"},
{id:"r-gui", label:"R GUI", app:"Rgui.exe", path:"\"%Path%\" --sdi %args%",
        required:"Rgui",
        platform:"Win"},
{id:"r-tk", label:"R Tk GUI", path:"\"%Path%\" --interactive --gui:Tk %args%",
        app:"R", required:"R", platform:"Lin,Mac"}
];


function PrefR_OnLoad() {
	// Get the sv object:
	var p = parent;
	while (p.opener && (p = p.opener) && !sv) if (p.sv) sv = p.sv;

	var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);

	var prefExecutable;
	var prefset = parent.hPrefWindow.prefset;
	var prefName = 'svRDefaultInterpreter';
    var menu = document.getElementById("svRApplication");
    menu.removeAllItems();

    var platform = navigator.platform.substr(0,3);

    var tmp = {}, required, res;
    for (var i in apps) {
		if (apps[i].platform.split(',').indexOf(platform) != -1) {
			required = apps[i].required.split(',');
			res = true;
			for (var k in required) {
				//res = res && !!sv.tools.file.whereIs(required[k]);
				// Once again, the xxx.app on the Mac are DIRECTORIES.
				// They cannot be found by the previous instruction
				if (!sv.tools.file.whereIs(required[k]) &&
					(sv.tools.file.exists(required[k]) ==
					sv.tools.file.TYPE_NONE)) res = false;
			}			
			if (res)
				tmp[apps[i].id] = apps[i];
		}
	}
    apps = tmp;

    for (var i in apps)
		menu.appendItem(apps[i].label, i, null);

    // Update cran mirror list (first local, then tries remote at CRAN)
	if (!PrefR_UpdateCranMirrors(true))
    PrefR_UpdateCranMirrors(false);

	menuListSetValues(); // Restores saved menu values
	sv.prefs.checkAll(); // Check if all preference values are ok, if not, restore defaults
    PrefR_PopulateRInterps();
	parent.hPrefWindow.onpageload();
    PrefR_updateCommandLine(true);
}


//TODO: check if there is new R version installed and ask whether to switch to it.
function PrefR_PopulateRInterps() {

    var prefExecutable = sv.prefs.getString('svRDefaultInterpreter');
    var rs = new Array();
    var os = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs);
    var menu = document.getElementById("svRDefaultInterpreter");

    // windows:
    ////////////////////////////////////
    switch (os.name) { //'posix', 'nt', 'mac', 'os2', 'ce', 'java', 'riscos'.
        case "nt":
        rs = rs.concat(sv.tools.file.whereIs("Rgui"));
        rs = rs.concat(sv.tools.file.whereIs("R"));
        break;
        case "mac":
		case "posix": // On Mac OS X, os.name is posix!!!
        rs = ["/Applications/R.app", "/Applications/R64.app",
			  "/Applications/SciViews R.app", "/Applications/SciViews R64.app",
			  sv.tools.file.whereIs("R")];
        break;
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
	prefset = parent.hPrefWindow.prefset;

	// PhG: why was this commented out? Causes problems on the Mac!!!
	prefset.setStringPref("svRDefaultInterpreter",
	document.getElementById("svRDefaultInterpreter").value);
	prefset.setStringPref("svRApplication",
		document.getElementById('svRApplication')
		.selectedItem.getAttribute("value"));

	prefset.setStringPref("svRApplicationId",
		document.getElementById('svRApplication').selectedItem.id);
	// PhG: was commented out until here...


	var outDec = document.getElementById('r.csv.dec').value;
	var outSep = document.getElementById('r.csv.sep').value;

    // "Preference widget" does not save newly added values for some reason:
	prefset.setStringPref("r.csv.sep", outSep);
	prefset.setStringPref("r.csv.dec", outDec);

    if (outDec == outSep) {
        parent.switchToPanel("svPrefRItem");
        ko.dialogs.alert(
        "Decimal separator cannot be the same as field separator.", null,
        "SciViews-K preferences");
        return(false);
    }
	prefset.setStringPref("svRCommand", PrefR_updateCommandLine(false));

	if (sv.r.running) {
		sv.r.evalHidden('options(OutDec="' + outDec + '", ' +
		'OutSep="' + outSep + '")', true);
	}

	// Set the client type
	var clientType = document.getElementById('sciviews.client.type').value;
	prefset.setStringPref("sciviews.client.type", clientType);
	// Check if selected item is different from current sv.clientType
	// and if R is running
	if (clientType != sv.clientType && sv.r.test()) {
		// R is running, do not change right now
		sv.alert("R server type changed",
			"The R server type you selected will be" +
			" used after restarting R!");
	} else {
		// Change current server type too
		sv.socket.setSocketType(clientType);
	}

	menuListGetValues();

	// Restart socket server if running and port or channel changed
	var serverType = document.getElementById('sciviews.server.type').value;
	var serverPort = document.getElementById('sciviews.server.socket').value;
	if (sv.socket.serverIsStarted &&
		(serverPort != prefset.getStringPref("sciviews.server.socket") ||
		serverType != sv.serverType)) {
		prefset.setStringPref("sciviews.server.socket", serverPort);
		prefset.setStringPref("sciviews.server.type", serverType);
		sv.serverType = serverType;
		sv.socket.serverStart();
		// TODO: change config in R (better), or warn that R must be restarted!
	} else {
		// Just change config
		prefset.setStringPref("sciviews.server.socket", serverPort);
		prefset.setStringPref("sciviews.server.type", serverType);
	}
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

    if (apps[menuApplication.value].app != app) {
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
    var cmdArgs = document.getElementById("svRArgs").value;
	var args1 = "";

	if (document.getElementById("sciviews.pkgs.sciviews").checked)
			args1 += " --svStartPkgs=SciViews";

   	var cwd = sv.tools.file.path("ProfD", "extensions",
    "sciviewsk@sciviews.org", "defaults");

	cmdArgs = cmdArgs.replace(/\s*--mdi/, "");

	var argsPos = cmdArgs.indexOf("--args");
	if (argsPos != -1) {
		args1 += " " + sv.tools.strings.trim(cmdArgs.substring(argsPos + 6));
		cmdArgs = cmdArgs.substring(0, argsPos);
	}

	args1 = sv.tools.strings.trim(args1);
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

    return(cmd);
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
				localPaths.push(svFile.path(sv.prefs.getString("svRDefaultInterpreter"),
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
	var value = menuList.value? menuList.value : sv.prefs.getString("CRANMirror");
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

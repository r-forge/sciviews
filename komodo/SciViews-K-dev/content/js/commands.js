// SciViews-K command functions
// Define the 'sv.command' namespace
// Copyright (c) 2009-2010, K. Barton & Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.command.startR();			// Start the preferred R app and connect to it
// TODO: sv.command.quitR(saveWorkspace)
// sv.command.openPkgManager(); // Open the package manager window
// sv.command.openHelp(webpage);// Open the R Help window at this web page
// sv.command.setControllers(); // Set controllers for R related commands
// sv.command.setKeybindings(clearOnly); // Set SciViews-K default keybindings
///////////////////////////////////////////////////////////////////////////////

if (typeof(sv) == 'undefined') sv = {};
if (typeof(sv.command) == 'undefined') sv.command = {};


// sv.command object constructor
(function () {
	this.RHelpWin = null;  // A reference to the R Help Window
	var _this = this;
	this.RProcess = null;

	function _getWindowByURI(uri) {
		var wm = Components.classes['@mozilla.org/appshell/window-mediator;1']
		.getService(Components.interfaces.nsIWindowMediator);
		var en = wm.getEnumerator("");

		if (uri) {
			var win;
			while (en.hasMoreElements()) {
				win = en.getNext();
				if (win.location.href == uri) return(win);
			}
		}
		return(null);
	}

	//Get reference to a window, opening it if is closed
	function _getWindowRef(uri, name, features, focus) {//, ...
		var win = _getWindowByURI(uri);
		if (!win || win.closed) {
			try {
				var args = Array.apply(null, arguments);
				args = args.slice(0,3).concat(args.slice(4));
				if (!features) args[2] = "chrome,modal,titlebar";
				win = window.openDialog.apply(null, args);
			} catch (e) {
				sv.log.exception(e, "Error opening window: " + uri);
			}
		}
		if (focus) win.focus();
	}

	// Private methods
	function _isRRunning () sv.r.running;

	function _RControl_supported () {
		var currentView = ko.views.manager.currentView;
		if (!currentView || !currentView.koDoc) return(false);
		//return(_isRRunning() && currentView.koDoc.language == "R");
		return(currentView.koDoc.language == "R");
	}

	function _RControlSelection_supported () {
		var currentView = ko.views.manager.currentView;
		if (!currentView || !currentView.scimoz) return(false);
		return (_RControl_supported() &&
			((currentView.scimoz.selectionEnd -
		currentView.scimoz.selectionStart) != 0));
	}


	var _observerSvc = Components.classes['@mozilla.org/observer-service;1']
		.getService(Components.interfaces.nsIObserverService);

	function _ProcessObserver(command, process, callback) {
		this._command = command;
		this._process = process;
		this._callback = (callback || function() {});

		_observerSvc.addObserver(this, 'run_terminated', false);
		try {
			this._process.wait(0);
			this.cleanUp();
		} catch (e) {};
	};
	_ProcessObserver.prototype = {
		observe: function(child, topic, command) {
			if ('run_terminated' === topic && this._command === command) {
				this.cleanUp();
				this._process = null;
			}
			//else if (topic === 'status_message' && (subject.category == "run_command")
			//	&& ((matches = subject.msg.match(/^(['`"])(.+)\1 returned ([0-9]+).$/)) != null
			//		&& matches[2] == this.command)) {
			//	/*...
			//	TODO: cleanUp - observer status_message
			//	....*/
			//}

		},
		cleanUp: function() {
			if (this._command) {
				_observerSvc.removeObserver(this, 'run_terminated');
				this._command = null;
			}
			if (this._process) {
				var processExitCode = this._process.wait(-1),
				processOutput = (this._process.getStdout() || this._process.getStderr());
				this._callback(processExitCode, processOutput, this._process);
				this._process = null;
			}
		},
		kill: function() {
			if (this._command) {
				_observerSvc.removeObserver(this, 'run_terminated');
				this._command = null;
			}
			if (this._process) {
				this._process.kill(-1);
				this._process = null;
			}
		}
	}

	_RterminationCallback = function(exitCode) {
		// do something here...
		sv.addNotification("SciViews-R is closed with code " + exitCode, 2000, true);
		_this.updateRStatus(false);
	}

	this.startR = function () {
		var svfile = sv.file;
		var svstr = sv.string;


		if (!sv.pref.getPref("svRCommand")) {
		    if(ko.dialogs.okCancel(
				sv.translate("R interpreter is not set in " +
						"Preferences. Would you like to do it now?"),
				   "OK", null, "SciViews-K") == "OK") {
				prefs_doGlobalPrefs("svPrefRItem", true);
		    }
		    return;
		}

		var rDir = svfile.path("ProfD", "extensions", "sciviewsk@sciviews.org", "R");

		svfile.write(svfile.path(rDir, "_init.R"),
			"setwd('"+ svstr.addslashes(sv.pref.getPref("sciviews.session.dir"))
				+ "')\n" + "options(ko.port=" +
				sv.pref.getPref("sciviews.ko.port", 7052) +
			", ko.host=\"localhost\")\n"
			);

		var cmd = sv.pref.getPref("svRCommand");
		var isWin = navigator.platform.indexOf("Win") === 0;
		var id = sv.pref.getPref("svRApplication",
			isWin? "r-gui" : "r-terminal");
		var env = [];
		switch (id) {
			case "r-tk":
				env.push("Rid=R-tk");
				// Set DISPLAY only when not set:
				var XEnv = Components.classes["@activestate.com/koEnviron;1"]
					.createInstance(Components.interfaces.koIEnviron);
				if (!XEnv.has("DISPLAY"))	env.push("DISPLAY=:0");
				XEnv = null;
			break;
			default:
		}

		var runSvc = Components.classes['@activestate.com/koRunService;1']
			.getService(Components.interfaces.koIRunService);

		var process = runSvc.RunAndNotify(cmd, rDir, env.join("\n"), null);
			// Observe = 'run_terminated'
			// subject = child
			// data = command
		RProcessObserver = new _ProcessObserver(cmd, process, _RterminationCallback);
		this.RProcess = process;
		_this.updateRStatus(true);
	}

	this.updateRStatus = function (running) {
        // Toggle status if no argument
		if (running === undefined) {
            running = !sv.r.running; // toggle
		} else {
			//running =  new Boolean(running); // does not work. why??
			running =  !!running; // convert to boolean
		}
		if (running != sv.r.running) {
			sv.r.running = running;
			xtk.domutils.fireEvent(window, 'r_app_started_closed');
			window.updateCommands('r_app_started_closed');
			sv.addNotification("R is " + (running? "" : "not ") + "running", 0, 2000);
		}
	}


this.openPkgManager = function () {
	var win = _getWindowRef("chrome://sciviewsk/content/pkgman/pkgman.xul",
		"RPkgMgr", "chrome=yes,dependent" +
		"scrollbars=yes,status=no,close,dialog=no,resizable", true, sv);
	return(win);
}

this.openSessionMgr = function() {
	var win = _getWindowRef("chrome://sciviewsk/content/sessions.xul",
		"RSessionMgr", "chrome,modal,titlebar,close,centerscreen", true);
	return(win);
}

// sv.command.openHelp - returns reference to the RHelpWindow
//FIXME: help in tab still buggy
this.openHelp = function (uri) {
	var RHelpWin = _this.RHelpWin;

	// We will need special treatment in windows
	var isWin = navigator.platform.search(/Win\d+$/) === 0;

	if (uri) {
		// This should hopefully work on all platforms (it does on Win and Linux)
		// First, check if "uri" is an URI already:
		var isUri = uri.search(/^((f|ht)tps?|chrome|about|file):\/{0,3}/) === 0;
		try {
			if (!isUri) {
				if (isWin) uri = uri.replace(/\//g, "\\");
				uri = sv.file.getURI(uri);
			}
		} catch (e) {
			// fallback
			if (!isUri) uri = "file://" + uri;
		}
	} else {
		uri = ""; // home page will be shown
	}

	var rhelpTabbed = sv.pref.getPref("rhelp.tabbed", false) == "true";
	var rHelpXulUri = "chrome://sciviewsk/content/RHelpWindow.xul";

	// Open R-help in a right tab
	if (rhelpTabbed) {
		// Make sure tab is visible and select it
		var tabPanel = document.getElementById("rhelpviewbox");
		var tab = document.getElementById("rhelp_tab");
		var tabBox = tabPanel.parentNode.parentNode;
		tabPanel.hidden = false;
		tab.hidden = false;
		tabBox.selectedIndex = tabBox.tabs.getIndexOfItem(tab);

		var RHelpFrame = document.getElementById("rhelpview-frame");

		RHelpFrame.webNavigation.loadURI(rHelpXulUri, null, null, null, null);

		//RHelpFrame.setAttribute("src", rHelpXulUri);
		RHelpWin = RHelpFrame.contentWindow;
		RHelpWin.go(uri);

	} else {
		_this.RHelpWin = _getWindowByURI(rHelpXulUri);
		if (!RHelpWin || RHelpWin.closed) {
			sv.log.debug("Starting R help with page " + uri);

			// try/catch here somehow prevented from storing window
			// reference in RHelpWin. No idea why...
			RHelpWin = window.openDialog(rHelpXulUri, "RHelp",
				"chrome=yes,dependent,resizable=yes," +
				"scrollbars=yes,status=no,close,dialog=no", sv, uri);
		} else {
			RHelpWin.go(uri);
		}
	}

	RHelpWin.focus();
	RHelpWin.close = _this.closeHelp;

	_this.RHelpWin = RHelpWin;
	return(RHelpWin);
}

// Close r-help tab
this.closeHelp = function() {
	var tabPanel = document.getElementById("rhelpviewbox");
	var tab = document.getElementById("rhelp_tab");
	var tabBox = tabPanel.parentNode.parentNode;

	tabPanel.hidden = true;
	tab.hidden = true;
	tabBox.selectedIndex = ((tabBox.tabs.getIndexOfItem(tab) + 2) %
	tabBox.tabs.itemCount) - 1;
	document.getElementById("rhelpview-frame")
	.setAttribute("src", "about:blank");
	//_this.RHelpWin.closed = true;
}

function _setControllers () {
	//Based on: chrome://komodo/content/library/controller.js
	// backwards compatibility APIs
	if (typeof(Controller) != "function") {
		xtk.include("controller");
		var Controller = xtk.Controller;
	}

	const XRRunning = 1, XRStopped = 2, XisRDoc = 4, XHasSelection = 8;
	var handlers = {
		'cmd_svOpenPkgManager': [ "sv.command.openPkgManager();", XRRunning ],
		'cmd_svBrowseWD': [ 'sv.r.setwd(\'current\', true);', XRRunning ],
		'cmd_svQuitR': [ 'sv.r.quit();', XRRunning ],
		'cmd_svOpenHelp': [ "sv.command.openHelp();", XRRunning ],
		'cmd_svSessionMgr': [ "sv.command.openSessionMgr();", 0 ],
		'cmd_svStartR': ['sv.command.startR();', XRStopped],
		'cmd_svREscape': [ 'sv.r.escape();', XRRunning ],
		'cmd_svRRunAll': [ 'sv.r.send("all");',XisRDoc | XRRunning ],
		'cmd_svRSourceAll': [ 'sv.r.source("all");',XisRDoc | XRRunning ],
		'cmd_svRRunBlock': [ 'sv.r.send("block");',XisRDoc | XRRunning ],
		'cmd_svRRunFunction': [ 'sv.r.send("function");',XisRDoc | XRRunning ],
		'cmd_svRRunLine': [ 'sv.r.send("line");',XisRDoc | XRRunning ],
		'cmd_svRRunPara': [ 'sv.r.send("para");',XisRDoc | XRRunning ],
		'cmd_svRSourceBlock': [ 'sv.r.source("block");',XisRDoc | XRRunning ],
		'cmd_svRSourceFunction': [ 'sv.r.source("function");',XisRDoc | XRRunning ],
		'cmd_svRSourcePara': [ 'sv.r.source("para");',XisRDoc | XRRunning ],
		'cmd_svRRunLineOrSelection': [ 'sv.r.run();', XisRDoc | XRRunning ],
		'cmd_svRSourceLineOrSelection': [ 'sv.r.source("line/sel");', XisRDoc | XRRunning ],
		'cmd_svRRunSelection': [ 'sv.r.send("sel");',XisRDoc | XRRunning | XHasSelection ],
		'cmd_svRSourceSelection': [ 'sv.r.source("sel");', XisRDoc | XRRunning | XHasSelection ],
		'cmd_viewrtoolbar': [ 'ko.uilayout.toggleToolbarVisibility(\'RToolbar\')', 0 ]
	}

	// Temporary
	//function _isRRunning () true;
	function _isRRunning () sv.r.running;

	function _isRCurLanguage () {
		var view = ko.views.manager.currentView;
		if (!view || !view.document) return(false);
		return(view.document.language == "R");
	}

	function _hasSelection () {
		var view = ko.views.manager.currentView;
		if (!view || !view.scimoz) return(false);
		return ((view.scimoz.selectionEnd - view.scimoz.selectionStart) != 0);
	}

	function svController() {}
	svController.prototype = new Controller();
	svController.prototype.constructor = svController;
	svController.prototype.destructor = function () { }
	svController.prototype.isCommandEnabled = function(command) {
		if(!(command in handlers)) return(false);
		var test = handlers[command][1];
		return (
				(((test & XRRunning) != XRRunning) || _isRRunning())
				&& (((test & XRStopped) != XRStopped) || !_isRRunning())
				);

		//return(true);
	}
	//var test = handlers[command][1];
	//return (((test & XRRunning) != XRRunning) || _isRRunning())
	//&& (((test & XRStopped) != XRStopped) || !_isRRunning())
	//&& (((test & XisRDoc) != XisRDoc) || true) //_isRCurLanguage())
	//&& (((test & XHasSelection) != XHasSelection) || _hasSelection()));
	//}

	svController.prototype.supportsCommand = svController.prototype
		.isCommandEnabled;

	svController.prototype.doCommand = function(command) {
		if (command in handlers) return(eval(handlers[command][0]));
		return (false);
	}

window.controllers.appendController(new svController());
//sv.log.debug("Controllers has been set.");
}

// Set default keybindings from file
// chrome://sciviewsk/content/default-keybindings.kkf
// preserving user modified ones and avoiding key conflicts
// sfx is for platform specific keybindings
function _setKeybindings (clearOnly, sfx) {
	if (!sfx) sfx = "";
	var kbMgr = ko.keybindings.manager;
	try {
		var svSchemeDefault = sv.file
			.readURI("chrome://sciviewsk/content/keybindings" + sfx + ".kkf");
	} catch(e) {
		return false;
	}
	if (!svSchemeDefault) return false;

	var currentConfiguration = kbMgr.currentConfiguration;
	if (!kbMgr.configurationWriteable(currentConfiguration)) {
		currentConfiguration =
			kbMgr.makeNewConfiguration(currentConfiguration + " (R)");
	}

	//from: gKeybindingMgr.parseConfiguration
	var bindingRx = /[\r\n]+(# *SciViews|binding cmd_sv.*)/g;
	function _getSvKeys (data, pattern) {
		if (!pattern) pattern = "";
		var keys = data.match(new RegExp("^binding " + pattern +
			".*$", "gm"));
		var res = {};
		for (var j in keys) {
			try {
				keys[j].search(/^binding\s+(\S+)\s+(\S+)$/);
				res[RegExp.$1] = RegExp.$2;
			} catch(e) { }
		}
		return(res);
	}

	var svKeysDefault = _getSvKeys (svSchemeDefault, "cmd_sv");

	if(clearOnly) {
		for(var i in svKeysDefault) kbMgr.clearBinding(i, "", false);
	} else {
		var keysequence;
		for(var i in svKeysDefault) {
			keysequence = svKeysDefault[i].split(/, /);
			if (!kbMgr.usedBy(keysequence).length) {
				kbMgr.assignKey(i, keysequence, '');
				kbMgr.makeKeyActive(i, keysequence);
			}
		}
	}
	//kbMgr.saveAndApply(ko.prefs);
	kbMgr.saveCurrentConfiguration();
	kbMgr.loadConfiguration(kbMgr.currentConfiguration, true);
	return true;
}


function _str(sString) sString.QueryInterface(Components.interfaces
	.nsISupportsString).data;

this.getRProc = function(property) {
	if (!property) property = "CommandLine";

	var svUtils = Components.classes["@sciviews.org/svUtils;1"]
		.createInstance(Components.interfaces.svIUtils);
	var procList = svUtils.getproc(property);

	proc = [];
	while(procList.hasMoreElements()) proc.push(_str(procList.getNext()));
	return proc;
}

this.places = {
	sourceSelection: function sv_sourcePlacesSelection() {
		if(!sv.r.running) return;
		var files = ko.places.manager.getSelectedItems()
			.filter(function(x) (x.file.isLocal && x.file.ext.toLowerCase() == ".r"))
			.map(function(x) x.file.path);
		if (!files.length) return;
		var cmd = files.map(function(x) "source('" +
			sv.string.addslashes(x) +"')" ).join("\n");
		sv.rconn.eval(cmd, function(z) {
			sv.rbrowser.smartRefresh(true);
			}, false);
	},

	get anyRFilesSelected()
		sv.r.running &&
		ko.places.manager.getSelectedItems().some(function(x)
			x.file.isLocal &&
			x.file.ext.toLowerCase() == ".r"),

	loadSelection: function sv_loadPlacesSelection() {
		if(!sv.r.running) return;
		var files = ko.places.manager.getSelectedItems()
			.filter(function(x) (x.file.isLocal &&
				// for '.RData', .ext is ''
				(x.file.ext || x.file.leafName).toLowerCase() == ".rdata"))
			.map(function(x) x.file.path);
		if (!files.length) return;
		var cmd = files.map(function(x) "load('" +
			sv.string.addslashes(x) +"')" ).join("\n");
		sv.rconn.eval(cmd, function(z) {
			sv.rbrowser.smartRefresh(true);
			}, false);
	},

	get anyRDataFilesSelected()
		sv.r.running &&
		ko.places.manager.getSelectedItems().some(
			function(x) x.file.isLocal &&
			(x.file.ext || x.file.leafName).toLowerCase() == ".rdata")

}

//}
// TODO: move this to sv.onLoad:
this.onLoad = function(event) {
	setTimeout(function() {
		_setControllers();
		_this.updateRStatus(false); // XXX: workaround for some items in
									//'cmdset_rApp' commandset being grayed out
									//at startup...
		_this.updateRStatus(sv.rconn.testRAvailability(false));
		if(sv.r.running) sv.rbrowser.smartRefresh(true);

		// For completions
		var cuih = ko.codeintel.CompletionUIHandler;
		cuih.prototype.types.argument = cuih.prototype.types.interface;
		cuih.prototype.types.environment = cuih.prototype.types.namespace;
		cuih.prototype.types.file = "chrome://sciviewsk/skin/images/cb_file.png";
	}, 600);


	var osName = Components.classes['@activestate.com/koOs;1']
		.getService(Components.interfaces.koIOs).name;

	if(!_setKeybindings(false, osName)) // use system specific keybindings
		_setKeybindings(false, '') // fallback - use default

	sv.rconn.startSocketServer();
}
addEventListener("load", _this.onLoad, false);


// Just in case, run a clean-up before quitting Komodo:
function svCleanup() sv.rconn.stopSocketServer();
ko.main.addWillCloseHandler(svCleanup);


function ObserveR () {
	var el = document.getElementById('cmd_svRStarted');
	el.setAttribute("checked", _isRRunning());
}
addEventListener("r_app_started_closed", ObserveR, false);

}).apply(sv.command);






// XXX: for DEBUG only
//sv.getScimoz = function sv_getScimoz ()
//ko.views.manager.currentView? ko.views.manager.currentView.scimoz : null;

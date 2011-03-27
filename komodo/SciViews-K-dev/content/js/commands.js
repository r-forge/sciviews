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
		sv.cmdout.message("SciViews-R is closed with code" + exitCode, 2000, true);
		_this.updateRStatus(false);
		alert("R is closed with code " + exitCode);
	}

	// Start R
	this.startR = function () {
		var exitCode;
		if (_this.RProcess && _this.RProcess.uuid) try {
			exitCode = _this.RProcess.wait(0);
		} catch(e) {
			var result = ko.dialogs.customButtons("Another instance is running" +
			"already. Before continuing, you should either quit currently running" +
			"R or kill its process (if it did not exit cleanly).",
			['&Kill', '&Quit', "&Cancel"], "Cancel", null, "SciViews-K");
			switch (result) {
				case "Kill":
					try {
						sv.command.RProcess.kill(true);
						sv.command.RProcess.wait(3);
					} catch(e) {}
					break;
				case "Quit":
					sv.r.quit();
					break;
				case "Cancel":
				default:
					return;
			}
			return;
		}

		var cwd = sv.tools.file.path("ProfD", "extensions", "sciviewsk@sciviews.org", "defaults");
		var cmd = sv.pref.getPref("svRCommand");

		// Remove /defaults/00LOCK if remained after a fail-start
		try {
			var lockFile = sv.tools.file.getfile(cwd, "00LOCK");
			if (lockFile.exists())	lockFile.remove(true);
		} catch(e) { }

		// PhG: on Mac OS X, R.app is not a file, but a dir!!!
		if (!cmd || (sv.tools.file.exists(sv.tools.string.trim(
			sv.pref.getPref("svRDefaultInterpreter"))) == sv.tools.file.TYPE_NONE)) {
			if(ko.dialogs.okCancel(
			sv.translate("Default R interpreter is not (correctly) set in " +
				"Preferences. Do you want to do it now?"),
				"OK", null, "SciViews-K") == "OK") {
				prefs_doGlobalPrefs("svPrefRItem", true);
			}
			return;
		}

		var isWin = navigator.platform.indexOf("Win") === 0;
		var id = sv.pref.getPref("svRApplication",
			isWin? "r-gui" : "r-terminal");

		// runIn = "command-output-window", "new-console",
		// env strings: "ENV1=fooJ\nENV2=bar"
		// gPrefSvc.prefs.getStringPref("runEnv");
		var env = ["koId=" + sv.pref.getPref("sciviews.client.id",
			"SciViewsK"),
			"koHost=localhost",
			"koActivate=FALSE",
			"Rinitdir=" + sv.pref.getPref("sciviews.session.dir", "~"),
			//"koType=" + sv.clientType, // Changed value considered only after Komodo restarts!
			"koType=" + sv.pref.getPref("sciviews.client.type", "socket"), // XXX
			"koServe=" + sv.pref.getPref("sciviews.r.port", 8888),
			"koPort=" + sv.pref.getPref("sciviews.ko.port", 7052),
			"koDebug=" + (sv.log.isAll()? "TRUE" : "FALSE"),
			"koAppFile=" + sv.tools.file.path("binDir", "komodo" + (isWin? ".exe" : ""))
		];
		var runInConsole = false;
		env.push("Rid=" + id);

		switch (id) {
			case "r-tk":
				env.push("Rid=R-tk");
				// Set DISPLAY only when not set:
				var XEnv = Components.classes["@activestate.com/koEnviron;1"]
					.createInstance(Components.interfaces.koIEnviron);
				if (!XEnv.has("DISPLAY"))	env.push("DISPLAY=:0");
				delete(XEnv);
			break;
			case "r-terminal":
				//runIn = "new-console";
				runInConsole = true;
			break;
			default:
		}

		var runSvc = Components.classes['@activestate.com/koRunService;1']
			.getService(Components.interfaces.koIRunService);

		var process;
		if(runInConsole) {
			// XXX: This does not return a process!
			runSvc.Run(cmd, cwd, env.join("\n"), runInConsole, null);
			process = null;
			// Observe = 'status_message'
			// subject.category = "run_command"
			// subject.msg = "'%s' returned %s." % (command, retval)
		} else {
			process = runSvc.RunAndNotify(cmd, cwd, env.join("\n"), null);
			// Observe = 'run_terminated'
			// subject = child
			// data = command
			RProcessObserver = new _ProcessObserver(cmd, process, _RterminationCallback);
		}

		//RProcessObserver = new _ProcessObserver(cmd, process, _RterminationCallback);
		this.RProcess = process;
		_this.updateRStatus(true);

	}

	this.updateRStatus = function (running) {
        // Toggle status if no argument
		if (running === undefined) {
            running = !sv.r.running; // toggle
		} else {
			running = !!running; // convert to boolean
			//running = true;
		}
		if (running != sv.r.running) {
			sv.r.running = running;
			xtk.domutils.fireEvent(window, 'r_app_started_closed');
			window.updateCommands('r_app_started_closed');
			sv.cmdout.message("R status: " + (running? "" : "not ") + "running" );
		}
	}

this.openPkgManager = function () {
	var win = _getWindowRef("chrome://sciviewsk/content/RPkgManager.xul",
		"RPkgMgr", "chrome=yes,dependent" +
		"scrollbars=yes,status=no,close,dialog=no", true, sv);
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
		// local paths should be of the form: file:///
		// Philippe, any ideas why sv.tools.file.getfile() returns null on Mac OS X?

		// This should hopefully work on all platforms (it does on Win and Linux)
		// First, check if "uri" is an URI already:
		var isUri = uri.search(/^((f|ht)tps?|chrome|about|file):\/{0,3}/) === 0;
		try {
			if (!isUri) {
				if (isWin) uri = uri.replace(/\//g, "\\");
				uri = sv.tools.file.getURI(uri);
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
		// 'cmd_svUpdateRInfo': ['sv.socket.rUpdate();', XRRunning],
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

// Code below is for extra items in editor context menu (eg. "run selection"),
// Commented out because it is still buggy
//	function editorContextMenuOnShowing (event) {
//		//try{
//
//		var ids = ["editor-context-sep-sv", "editor-context-sv-r-send-line-sel"];
//
//		var langNotR = ko.views.manager.currentView.koDoc.language != "R";
//		var visibility = langNotR? "collapse" : "visible";
// /*
//		for (i in ids)
//			document.getElementById(ids[i]).style.visibility = visibility;
//*/
//		//} catch(e) {}
//
//	}
//var editorContextMenu = document.getElementById("editorContextMenu");
//editorContextMenu.addEventListener("popupshowing", editorContextMenuOnShowing, false);
// Set default keybindings from file
// chrome://sciviewsk/content/default-keybindings.kkf
// preserving user modified ones and avoiding key conflicts

function _setKeybindings (clearOnly) {
	var keybindingSvc = Components
		.classes["@activestate.com/koKeybindingSchemeService;1"]
		.getService(Components.interfaces.koIKeybindingSchemeService);

	//TODO: use of gKeybindingMgr could simplify this code
	//gKeybindingMgr.keybindingSchemeService

	var svSchemeDefault = sv.tools.file
		.readURI("chrome://sciviewsk/content/default-keybindings.kkf");

	//gKeybindingMgr.currentScheme.name
	var currentSchemeName = sv.pref.getPref("keybinding-scheme");

	var sch = keybindingSvc.getScheme(currentSchemeName);

	//gKeybindingMgr.parseConfiguration
	var bindingRx = /[\r\n]+(# *SciViews|binding cmd_sv.*)/g;
	if (clearOnly != true) {
		function _getSvKeys (data, pattern) {
			if (!pattern) pattern = "";
			var keys = data.match(new RegExp("^binding " + pattern +
			".*$", "gm"));
			var res = {};
			for (var j in keys) {
			try {
				keys[j].search(/^binding\s+(\S+)\s+(\S+)$/);
				res[RegExp.$1] = RegExp.$2;
			} catch(e) {  // XXX _setKeybindings
				sv.log.warn("_setKeybindings" + e + "\n*keys[j]=" + keys[j] + "*");
			}
			}
			return(res);
		}

		var svCmdPattern = "cmd_sv";
		var svKeysDefault = _getSvKeys (svSchemeDefault, svCmdPattern);
		var svKeysCurrent = _getSvKeys (sch.data, svCmdPattern);

		// Temporarily delete SciViews keybindings
		sch.data = sch.data.replace(bindingRx, "");

		// Check for key conflicts
		//var usedbys = this.usedBy([keysequence]);
		var svKeysCurrentOther = _getSvKeys (sch.data, "");
		var currKeyArr = [];
		for (var k in svKeysCurrentOther)
		currKeyArr.push(svKeysCurrentOther[k]);
		for (var k in svKeysDefault) {
			if (currKeyArr.indexOf(svKeysDefault[k]) != -1)
			delete svKeysDefault[k];
		}

		var newSchemeData = "";
		var key, updatedKeys = [];
		for (var k in svKeysDefault) {
			//sv.log.debug(k);
			if (svKeysCurrent[k]) {
				key = svKeysCurrent[k];
			} else {
				key = svKeysDefault[k];
				updatedKeys.push(k);
			}
			newSchemeData += "binding " + k + " " + key + "\n";
		}
		sch.data += "\n\n# SciViews\n" + newSchemeData;
		sv.log.debug(" SciViews keybindings (" + updatedKeys.length +
			") have been updated in \"" +
		currentSchemeName + "\" scheme.");
	} else {
		//gKeybindingMgr.removeCommandsWithPrefix("cmd_sv");
		sch.data = sch.data.replace(bindingRx, "");
		sv.log.debug("SciViews keybindings (" + updatedKeys.length +
			") have been cleared in \"" + currentSchemeName + "\" scheme.");
	}
	sch.save();
	//gKeybindingMgr.saveAndApply();
	//gKeybindingMgr.saveCurrentConfiguration();

	//sv.log.debug("You may need to restart Komodo.");

	// A (temporary) hack to allow for R autocompletion/calltips to be
	// triggered with the same key-shortcut as for other languages.
	// cmd_svRTriggerCompletion will exit for files other than R
	//var tpc_cmd = document.getElementById("cmd_triggerPrecedingCompletion");
	//tpc_cmd.setAttribute("oncommand", [tpc_cmd.getAttribute("oncommand"),
	//	"ko.commands.doCommandAsync('cmd_svRTriggerCompletion',
	//  event);"].join(";"));
	//sv.log.debug("Keybindings has been applied.");
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
		var files = ko.places.manager.getSelectedItems()
			.filter(function(x)(x.name.search(/\.[Rr]$/) != -1))
			.map(function(x) x.file.path);
		if (!files.length) return;
		var cmd = files.map(function(x) "source('" + sv.tools.string.addslashes(x) +"')" ).join("\n");
		sv.rconn.eval(cmd, null, false);
	},

	get anyRFilesSelected()
		ko.places.manager.getSelectedItems()
		.some(function(x) /\.[Rr]$/.test(x.name))
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
	}, 600);
	 _setKeybindings();

	sv.rconn.startSocketServer();
}

addEventListener("load", _this.onLoad, false);

}).apply(sv.command);

// XXX: for DEBUG only
sv.getScimoz = function sv_getScimoz ()
ko.views.manager.currentView? ko.views.manager.currentView.scimoz : null;

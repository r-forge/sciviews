// SciViews-K command functions
// Define the 'sv.command' namespace
// Copyright (c) 2009-2011, K. Barton & Ph. Grosjean (phgrosjean@sciviews.org)
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
	// Continuous checking is now disabled - R often hanged
	function _keepCheckingR (stopMe) {
		/*
		//clearInterval(sv.r.testInterval);
		if (!stopMe) {
			// checking every second may cause problems when R is busy, changed to 5000
			//sv.r.testInterval = window.setInterval(sv.r.test, 5000);
		}
		//sv.r.running = true;
		//setTimeout(window.updateCommands, 1000, 'r_app_started_closed');
		//xtk.domutils.fireEvent(window, 'r_app_started_closed');
		*/
	}

	function _isRRunning () {
		//TODO: temporary solution
		return(true);
		//return(sv.r.running);
	}

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

	// Start R
	this.startR = function () {
		// Check if R is not already running and servicing on server port
		if (sv.r.test(false, false, true)) {
			ko.statusBar.AddMessage("R is already running!", "SciViews-K",
				3000, true);
			return;
		}
		
		var cwd = sv.tools.file.path("ProfD", "extensions",
			"sciviewsk@sciviews.org", "defaults");
		var cmd = sv.prefs.getString("svRCommand");
	
		// Remove /defaults/00LOCK if remained after a fail-start
		try {
			var lockFile = sv.tools.file.getfile(cwd, "00LOCK");
			if (lockFile.exists())	lockFile.remove(true);
		} catch(e) { }
	
		// PhG: on Mac OS X, R.app is not a file, but a dir!!!
		if (!cmd || (sv.tools.file.exists(sv.tools.strings.trim(
			sv.prefs.getString("svRDefaultInterpreter"))) ==
			sv.tools.file.TYPE_NONE)) {
			if(ko.dialogs.okCancel(
			sv.translate("Default R interpreter is not (correctly) set in " +
				"Preferences. Do you want to do it now?"),
				"OK", null, "SciViews-K") == "OK") {
					prefs_doGlobalPrefs("svPrefRItem", true);
				}
			return;
		}

	var isWin = navigator.platform.indexOf("Win") === 0;
	var id = sv.prefs.getString("svRApplication",
        isWin? "r-gui" : "r-terminal");

	// runIn = "command-output-window", "new-console",
	// env strings: "ENV1=fooJ\nENV2=bar"
	// gPrefSvc.prefs.getStringPref("runEnv");
	// Calculate output width
	var scimoz = document.getElementById("rconsole-scintilla2").scimoz;
	var width = (Math.floor(window.innerWidth /
		scimoz.textWidth(0, "0")) - 7)
	// min = 66, max = 200 (otherwise, it is harder to read) 
	if (width < 66) width = 66;
	if (width > 266) width = 266;
	
	var clientType = sv.prefs.getString("sciviews.client.type", "socket");
	var env = ["koId=" + sv.prefs.getString("sciviews.client.id", "SciViewsK"),
		"koHost=localhost",
		"koActivate=FALSE",
		"Rinitdir=" + sv.prefs.getString("sciviews.session.dir", "~"),
		"koType=" + clientType,
		"koServe=" + sv.prefs.getString("sciviews.client.socket", "8888"),
		"koPort=" + sv.prefs.getString("sciviews.server.socket", "7052"),
		"koDebug=" + String(sv.socket.debug).toUpperCase(),
		"koAppFile=" + sv.tools.file.path("binDir", "komodo" + (isWin? ".exe" : "")),
		"OutDec=" + sv.prefs.getString("r.csv.dec", "."),
		"OutSep=" + sv.prefs.getString("r.csv.sep", ","),
		"width=" + width
	];
		// Not done here!! "width=" + width
	var runIn = "no-console";
	env.push("Rid=" + id);

	switch (id) {
		case "r-tk":
			env.push("Rid=R-tk");
			// Set DISPLAY only when not set:
			var XEnv = Components.classes["@activestate.com/koEnviron;1"]
				.createInstance(Components.interfaces.koIEnviron);
			if (!XEnv.has("DISPLAY")) env.push("DISPLAY=:0");
			delete(XEnv);
			break;
		case "r-terminal":
			runIn = "new-console";
			break;
		default:
	}

	ko.run.runCommand(window, cmd, cwd, env.join("\n"), false,
		false, false, runIn, false, false, false);

	// Register observer of application termination
	this.rObserver = new AppTerminateObserver(cmd);
	
	// Ensure the client type is correct for everyone
	sv.socket.setSocketType(clientType);
	
	// ... make sure to start with a clear R Output window
	sv.cmdout.clear(false);
}

	// This will observe status message notification to be informed about
	// application being terminated. A more straightforward way would be to use
	// runService.RunAndNotify but this wouldn't allow to start app in a console
	// window. So we have to do this trick here.
	function AppTerminateObserver (command) {
		this.register(command);
	};

	AppTerminateObserver.prototype = {
		command: "",
		// This is launched when status message is set, we then check if it was
		// about terminated application
		observe: function (subject, topic, data) {
			var matches;

			if ((subject.category == "run_command") && (matches =
				subject.msg.match(/^(['`"])(.+)\1 returned ([0-9]+).$/))
				!= null && matches[2] == this.command) {
				// Seems like this is a 'R quit' msg
				this.unregister();
				// Do something here like activate/deactivate commands...
			}
		},
		register: function (command) {
			var observerSvc = Components.
				classes["@mozilla.org/observer-service;1"].
				getService(Components.interfaces.nsIObserverService);
			this.command = command;
			observerSvc.addObserver(this, 'status_message', false);
			sv.log.debug("R has been started with command: " + command);
			// Sending commands to R does not seem to work, I think it is
			// too early, R is still starting. This should be in .Rprofile
			//sv.socket.rUpdate();
			// Possibly refresh the GUI by running SciViews-specific
			// R task callbacks and make sure R Objects pane is updated
			//sv.r.evalHidden("try(koRefresh(force = TRUE), silent = TRUE)");

			// this hopefully will be called from R, when it starts:
			_this.updateRStatus(true);
		},
		unregister: function () {
			var observerSvc = Components.
				classes["@mozilla.org/observer-service;1"].
				getService(Components.interfaces.nsIObserverService);
			observerSvc.removeObserver(this, 'status_message');

			sv.log.debug("R has been closed. Command was: " + this.command);

			_this.updateRStatus(false);
		}
	};

	this.updateRStatus = function (running) {
		running = !!running;
        // Toggle status if no argument
		if (running === undefined) {
            running = !sv.r.running;
		} else {
			running = true;
		}
       // if (running != sv.r.running) {
			//sv.r.running = running;
			//sv.r.running = running;
			//xtk.domutils.fireEvent(window, 'r_app_started_closed');
			// PhG: these events are disabled for now, because menus are
			//      sometimes disabled when they shouldn't be!!! Very ennoying!
			//window.updateCommands('r_app_started_closed');
			//sv.cmdout.message("R status: " + (running? "" : "not ") + "running" );
		//}
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

		var rhelpTabbed = sv.prefs.getString("rhelp.tabbed", false) == "true";
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
			//RHelpWin.go(uri);
			// PhG: it seems we could enter in a deadlock situation here
			// => defer display of the page
			window.setTimeout(sv.command.RHelpWin.go, 10, uri);
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
				//RHelpWin.go(uri);
				// PhG: it seems we could enter in a deadlock situation here
				// => defer display of the page
				window.setTimeout(sv.command.RHelpWin.go, 10, uri);
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
                'cmd_svSessionMgr': [ "sv.command.openSessionMgr();", XRRunning ],
                'cmd_svStartR': ['sv.command.startR();', 0], // XRStopped],
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
        function _isRRunning () {
            return(true);
        }

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
			return(true);
		}
            //var test = handlers[command][1];
            // PhG: since _isRRunning() returns always true, we are currently
			// NOT able to start R!
			// KB: Yes, but startR is enabled by on Komodo load and event
			// "r_app_started_closed" is never fired.
			//return (((test & XRRunning) != XRRunning) || _isRRunning())
			//&& (((test & XRStopped) != XRStopped) || !_isRRunning())
				// PhG: it is NOT the program, but the user who decides when it possible
				// to send a command to R... There are possibles situations where
				// executable R code live somewhere else than in a .R document
				// Let's think at examples in .Rd files, <code R> sections in a
				// wiki page, etc.
				// Thus, for the nth time, I don't want this restriction on commands
				// running code to R: I want them available EVERYWHERE!
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
///*
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
		var currentSchemeName = sv.prefs.getString("keybinding-scheme");

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
					keys[j].search(/^binding\s+(\S+)\s+(\S+)$/);
					res[RegExp.$1] = RegExp.$2;
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
				sv.log.debug(k);
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
	}

    this.sourcePlacesSelection = function sv_sourcePlacesSelection() {
        var files = ko.places.manager.getSelectedItems()
            .filter(function(x)(x.name.search(/\.[Rr]$/) != -1))
            .map(function(x) x.file.path);
        if (!files.length) return;
        var cmd = files.map(function(x) "source('" + sv.tools.string.addslashes(x) +"')" )
            .join("\n");
        sv.r.eval(cmd);
    }

	addEventListener("load", function() setTimeout(_setControllers, 600), false);
	addEventListener("load", _setKeybindings, false);

}).apply(sv.command);

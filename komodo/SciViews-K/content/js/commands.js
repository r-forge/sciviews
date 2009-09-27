// SciViews-K command functions
// Define the 'sv.command' namespace
// Copyright (c) 2009, K. Barton & Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.command.getRApp(event);  	// Select a preferred R application in the list
// sv.command.setMenuRApp(el); 	// Set up 'R application' submenu (checked item
								// and hide incompatible items.
// sv.command.startR();			// Start the preferred R app and connect to it
// sv.command.openPkgManager(); // Open the package manager window
// sv.command.openHelp(webpage);// Open the R Help window at this web page
// sv.command.setControllers(); // Set controllers for R related commands
// sv.command.setKeybindings(clearOnly); // Set SciViews-K default keybindings
///////////////////////////////////////////////////////////////////////////////

if (typeof(sv.command) == 'undefined') {
    sv.command = {};
}

// sv.command object constructor
(function () {
	var RHelpWin;  // A reference to the R Help Window

	// private methods
	function _keepCheckingR (stopMe) {
		clearInterval(sv.r.testInterval);
		if (!stopMe) {
			// checking every second may cause problems when R is busy, changed to 5000
			sv.r.testInterval = window.setInterval(sv.r.test, 5000);
		}
		setTimeout(window.updateCommands, 1000, 'r_app_started_closed');
	}

	function _isRRunning () {
		//sv.log.debug("is R Running? " + sv.r.running);
		return sv.r.running;
	}

	function _RControl_supported () {
		var currentView = ko.views.manager.currentView;
		if (!currentView || !currentView.document)
			return false;
		//return(_isRRunning() && currentView.document.language == "R");
		return(currentView.document.language == "R");
	}

	function _RControlSelection_supported () {
		var currentView = ko.views.manager.currentView;
		if (!currentView || !currentView.scimoz)
			return false;

		return _RControl_supported()
			&&  ((currentView.scimoz.selectionEnd -
				currentView.scimoz.selectionStart) != 0);
	}

	// Start R, if not already running
	this.startR = function () {
		// runIn = "command-output-window", "new-console",
		// env strings: "ENV1=fooJ\nENV2=bar"
		// gPrefSvc.prefs.getStringPref("runEnv");
		var defRApp = "r-terminal";
		var isWin = navigator.platform == "Win32";
		// Default preferredRApp on Windows is r-gui
		if (isWin) defRApp = "r-gui";
		var preferredRApp = sv.prefs.getString("sciviews.preferredRApp",
			defRApp);
		var env = ["koId=" + sv.prefs.getString("sciviews.client.id",
			"SciViewsK"),
			"koHost=localhost",
			"koActivate=FALSE",
			"Rinitdir=" + sv.prefs.getString("sciviews.session.dir", "~"),
			"koServe=" + sv.prefs.getString("sciviews.client.socket", "8888"),
			"koPort=" + sv.prefs.getString("sciviews.server.socket", "7052"),
			"koAppFile=" + sv.tools.file.path("CurProcD",
				["komodo" + (isWin? ".exe" : "")])
		];
		var cwd = sv.tools.file.path("ProfD",
			["extensions", "sciviewsk@sciviews.org", "templates"]);
		var command, runIn = "no-console";

		ko.statusBar.AddMessage(sv.translate("Starting R... please wait"),
			"StartR", 10000, true);
		switch (preferredRApp) {
			case "r-gui":
				env.push("Rid=Rgui");
				command = "Rgui --sdi";
				break;
			case "r-xfce4-term":
				env.push("Rid=R-xfce4-term");
				command = "xfce4-terminal --title \"SciViews-R\" -x R --quiet";
				break;
			case "r-gnome-term":
				env.push("Rid=R-gnome-term");
				command = "gnome-terminal --hide-menubar --title=SciViews-R -x R --quiet";
				break;
			case "r-kde-term":
				env.push("Rid=R-kde-term");
				command = "konsole --nomenubar --notabbar --noframe -T SciViews-R -e R --quiet";
				break;
			case "r-tk":
				env.push("Rid=R-tk");
				// Set DISPLAY only when not set:
				var XEnv = Components.classes["@activestate.com/koEnviron;1"]
					.createInstance(Components.interfaces.koIEnviron);
				if (!XEnv.has("DISPLAY"))
					env.push("DISPLAY=:0");
				delete XEnv;
				command = "R --quiet --save --gui=Tk";
				// runIn = "no-console";
				break;
			case "r-app":
				env.push("Rid=R.app");
				command = "open -a /Applications/R.app \"" + cwd + "\"";
				break;
			case "r64-app":
				env.push("Rid=R64.app");
				command = "open -a /Applications/R64.app \"" + cwd + "\"";
				break;
			case "svr-app":
				env.push("Rid=svR.app");
				command = "open -a \"/Applications/SciViews R.app\" \"" +
					cwd + "\"";
				break;
			case "svr64-app":
				env.push("Rid=svR64.app");
				command = "open -a \"/Applications/SciViews R64.app\" \"" +
					cwd + "\"";
				break;
			// This does start, but ignore initial dir and thus SciViews is
			// not initialized
			case "jgrmac-app": // TODO: JGR on other platforms too!
				env.push("Rid=JGR.app");
				command = "open -a /Applications/JGR.app \"" +
					cwd + "\"";
				break;
			default:
				env.push("Rid=R");
				command = "R --quiet";
				runIn = "new-console";
		}
		sv.log.debug("Running: " + command);

		// Debugging garbage...
		//var command = "CMD /C \"SET\" > c:\\env.txt & notepad c:\\env.txt";
		//ko.run.runCommand(window,
		//	"CMD /C \"SET\" > c:\\env.txt & notepad c:\\env.txt", cwd, {});
		//var runSvc = Components.classes["@activestate.com/koRunService;1"]
		//	.getService(Components.interfaces.koIRunService);
		//var Rapp = runSvc.RunAndNotify(command, cwd, env.join("\n"), null);
		//ko.run.runCommand(window, command, cwd, env.join("\n"), false,

		ko.run.runCommand(window, command, cwd, env.join("\n"), false,
			false, false, runIn, false, false, false);

		// Register observer of application termination.
		this.rObserver = new AppTerminateObserver(command);
	};

	// This will observe status message notification to be informed about
	// application being terminated. A more straightforward way would be to use
	// runService.RunAndNotify but this wouldn't allow to start app in a console
	// window. So we have to do this trick here.
	// This is not used for anything yet.
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
			sv.r.running = true;
			sv.socket.updateCharset(true);
			// Possibly refresh the GUI by running SciViews-specific
			// R task callbacks and make sure R Objects pane is updated
			sv.r.evalHidden("try(guiRefresh(force = TRUE), silent = TRUE)");

			//xtk.domutils.fireEvent(window, 'r_app_started_closed');
			window.updateCommands('r_app_started_closed');
		},
		unregister: function () {
			var observerSvc = Components.
				classes["@mozilla.org/observer-service;1"].
				getService(Components.interfaces.nsIObserverService);
			observerSvc.removeObserver(this, 'status_message');

			sv.log.debug("R has been closed. Command was: " + this.command);

			sv.r.running = false;
			//xtk.domutils.fireEvent(window, 'r_app_started_closed');
			window.updateCommands('r_app_started_closed');
		}
	};

	// Selects the checkbox on selected element, while deselecting others
	this.getRApp = function (event) {
		var el = event.originalTarget;
		var siblings = el.parentNode.childNodes;
		for (var i = 0; i < siblings.length; i++) {
			try {
				siblings[i].setAttribute("checked", siblings[i] == el);
			} catch(e) {}
		}
		// This will preserve the selection
		el.parentNode.setAttribute('selected',  el.id);
		// Set the preference string
		sv.prefs.setString("sciviews.preferredRApp", el.id, true);

		document.getElementById("cmd_sv_start_R").setAttribute("label",
			sv.translate("Start R") + " (" + el.getAttribute('label') + ")");
	}

	// Selects checkbox on the 'preferred R application' menu on its first
	// display and hides unsupported commands
	// It is triggered on popupshowing event, onload would be better,
	// but it is for compatibility with Komodo 4 which doesn't support onload()
	this.setMenuRApp = function (el) {
		var selected = el.getAttribute('selected');
		var siblings =  el.childNodes;

		var isLinux = navigator.platform.toLowerCase().indexOf("linux") > -1;
		var isMac = navigator.platform.toLowerCase().indexOf("mac") > -1;

		// This will tell whether an app is present on the *nix system
		function whereis(app) {
			var runSvc = Components.
				classes["@activestate.com/koRunService;1"].
				getService(Components.interfaces.koIRunService);
			var err = {}, out = {};
			var res = runSvc.RunAndCaptureOutput("whereis -b " + app,
				null, null, null, out, err);
			var path = out.value.substr(app.length + 2);
			if (!path) return false;
			return out.value.substr(app.length + 2).split(" ");
		}

		var validPlatforms, showItem;
		var platform = navigator.platform;
		for (var i = 0; i < siblings.length; i++) {
			try {
				validPlatforms = siblings[i].getAttribute("platform").
					split(/\s*[,\s]\s*/);
				showItem = false;
				for (var j in validPlatforms) {
					if (platform.indexOf(validPlatforms[j]) > -1) {
						// On linux, try to determine which terminals are
						// not available and remove these items from menu
						if (isLinux) {
							if (whereis(siblings[i].getAttribute("app"))) {
								showItem = true;
								break;
							}
						} else if (isMac) {
							// Check that we find the application
							var Rapp = siblings[i].getAttribute("app");
							if (Rapp == "R" || sv.tools.file.exists(Rapp)) {
								showItem = true;
								break;
							}
						} else { // Windows, RGui & RTerm always available?
							showItem = true;
							break;
						}
					}
				}

				if (!showItem) {
					siblings[i].style.display = "none";
					// This does not work on the Mac, but the following is fine
					siblings[i].setAttribute("hidden", true);
				} else {
					sv.log.debug("R application supported: " +
						siblings[i].getAttribute("app"));
					siblings[i].setAttribute("checked",
						siblings[i].id == selected);
				}
			} catch(e) {
				sv.log.exception(e, "Error looking for R apps in setMenuRApp");
			}
		}

		// Set the preference string
		sv.prefs.setString("sciviews.preferredRApp", selected, false);

		document.getElementById("cmd_sv_start_R").setAttribute("label",
			sv.translate("Start R") + " (" + document.getElementById(selected).
				getAttribute('label') + ")"
		);

		// We do not need to run it anymore
		el.removeAttribute("onpopupshowing");
	}

	this.openPkgManager = function () {
		window.openDialog(
			"chrome://sciviewsk/content/pkgManagerOverlay.xul",
			"RPackageManager",
			"chrome=yes,dependent,centerscreen,resizable=yes,scrollbars=yes,status=no",
			sv);
	}

	this.openHelp = function (webpage) {
		if (typeof(webpage) == "undefined") {
			// We are asking for the R help home page
			if (typeof(RHelpWin) == "undefined" || RHelpWin.closed) {
				sv.log.debug("Starting R help");
				sv.r.helpStart(true);
			} else {
				sv.log.debug("Displaying R help and going home");
				RHelpWin.home();
				RHelpWin.focus();
			}
		} else {
			// Webpage should be of the form: file:///
			// Commented out and replaced by a bad hack (prepending 'file://')
			// because:
			// 1) sv.tools.file.getfile() returns null on Mac OS X
			// 2) sv.tools.file.getURI() raises an error on Mac OS X
			//webpage = sv.tools.file.getURI(sv.tools.file.getfile(webpage.replace(/\//g, "\\")));
			webpage = "file://" + webpage;
			
			// We want to display a specific page
			if (typeof(RHelpWin) == "undefined" || RHelpWin.closed) {
				sv.log.debug("Starting R help with page " + webpage);
				try {
					RHelpWin = window.openDialog(
						"chrome://sciviewsk/content/RHelpOverlay.xul",
						"RHelp",
							"chrome=yes,dependent,resizable=yes,scrollbars=yes,status=no,close,dialog=no",
						sv, webpage);
				// Recalculate home page for R Help only
				} catch (e) {
					sv.log.exception(e, "Unable to display R help", true);
				}
				sv.r.helpStart(false);
			} else {
				sv.log.debug("Showing R help for page " + webpage);
				RHelpWin.display(webpage);
			}
			RHelpWin.focus();
		}
	}

	this.setControllers = function () {
		//sv.log.debug("this.setControllers");
		// Allow some commands only when R is running...
		// using this needs solving an issue of running R in some terminals
		// on linux (mac?) that send terminate signal right after start.

		var vmProto = ko.views.viewManager.prototype;

		var cmdsIfRRunning = ['OpenPkgManager', 'BrowseWD', 'quit_R',
			'update_charset'];
		var cmdsIfRNotRunning = ['start_R'];

		// Make these commands active only when current document language is R
		var cmdsIfIsRView = ["RunAll", "SourceAll", "RunBlock", "RunFunction",
			"RunLine", "RunPara", "SourceBlock", "SourceFunction", "SourcePara",
			"TriggerCompletion"];
		// ... and if some text is selected
		var cmdsIfIsRViewAndSelection = ["RunSelection", "SourceSelection"];

		function _setCommandCtrl1 (arr, fun, pfx) {
			pfx = "is_cmd_" + pfx;
			for (var i in arr) {
				vmProto[pfx + arr[i] + "_supported"] = fun;
				vmProto[pfx + arr[i] + "_enabled"] = fun;
			}
		}

		_setCommandCtrl1(cmdsIfRRunning, _isRRunning, "sv_");
		_setCommandCtrl1(cmdsIfRNotRunning, function() {
			return !_isRRunning()}, "sv_");
		_setCommandCtrl1(cmdsIfIsRView, _RControl_supported, "sv_R");
		_setCommandCtrl1(cmdsIfIsRViewAndSelection,
			_RControlSelection_supported, "sv_R");

		vmProto.do_cmd_sv_quit_R = function () {
			sv.r.quit();
		};

		vmProto.do_cmd_sv_update_charset = function () {
			sv.socket.updateCharset(true);
			window.setTimeout(function() {
				sv.log.info(sv.translate("R uses \"%S\" encoding.",
				sv.socket.charset));
			}, 100);
		};

		_keepCheckingR();

		// This is no longer needed:
		// To run it with the same key as autocompletion with other languages
		// command "cmd_triggerPrecedingCompletion" is replaced in XUL
		// ko.commands.doCommandAsync('cmd_sv_RTriggerCompletion', event)
		//vmProto.do_cmd_sv_RTriggerCompletion = function () {
		//	sv.r.complete();
		//};

		vmProto.do_cmd_sv_RRunLine = function () {
			sv.r.send("line");
		};
		vmProto.do_cmd_sv_RRunAll = function ()	{
			sv.r.send("all");
		};
		vmProto.do_cmd_sv_RSourceAll = function () {
			sv.r.source("all");
		};
		vmProto.do_cmd_sv_RSourcePara = function () {
			sv.r.source("para");
		};
		vmProto.do_cmd_sv_RRunPara = function () {
			sv.r.send("para");
		};
		vmProto.do_cmd_sv_RRunSelection = function () {
			sv.r.send("sel");
		};
		vmProto.do_cmd_sv_RSourceSelection = function () {
			sv.r.source("sel");
		};
		vmProto.do_cmd_sv_RRunBlock = function () {
			sv.r.send("block");
		};
		vmProto.do_cmd_sv_RSourceBlock = function () {
			sv.r.source("block");
		};
		vmProto.do_cmd_sv_RRunFunction = function () {
			sv.r.send("function");
		};
		vmProto.do_cmd_sv_RSourceFunction = function () {
			sv.r.source("function");
		};
		vmProto.do_cmd_sv_start_R = function () {
			sv.command.startR();
		};
	}

	// Set default keybindings from file
	// chrome://sciviewsk/content/default-keybindings.kkf
	// preserving user modified ones and avoiding key conflicts
	this.setKeybindings = function (clearOnly) {
		var keybindingSvc = Components
			.classes["@activestate.com/koKeybindingSchemeService;1"]
			.getService(Components.interfaces.koIKeybindingSchemeService);

		var svSchemeDefault = sv.tools.file
			.readURI("chrome://sciviewsk/content/default-keybindings.kkf");
		var currentSchemeName = sv.prefs.getString("keybinding-scheme");

		// Perhaps this should be redone for each scheme?
		//var currentSchemeName = "Default";
		//var schemeNames = {};
		//keybindingSvc.getSchemeNames(schemeNames, {});
		//schemeNames = schemeNames.value;
		var sch = keybindingSvc.getScheme(currentSchemeName);

		var bindingRx = /[\r\n]+(# *SciViews|binding cmd_sv_.*)/g;
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
				return res;
			}

			var svCmdPattern = "cmd_sv_";
			var svKeysDefault = _getSvKeys (svSchemeDefault, svCmdPattern);
			var svKeysCurrent = _getSvKeys (sch.data, svCmdPattern);

			// Temporarily delete SciViews keybindings
			sch.data = sch.data.replace(bindingRx, "");

			// Check for key conflicts
			var svKeysCurrentOther = _getSvKeys (sch.data, "");
			var currKeyArr = [];
			for (var k in svKeysCurrentOther)
				currKeyArr.push(svKeysCurrentOther[k]);
			for (var k in svKeysDefault) {
				if (currKeyArr.indexOf(svKeysDefault[k]) != -1) {
					delete svKeysDefault[k];
				}
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
			sv.log.debug(updatedKeys.length +
				"SciViews keybindings have been updated in \"" +
				currentSchemeName + "\" scheme.");
		} else {
			sch.data = sch.data.replace(bindingRx, "");
			sv.log.debug("SciViews keybindings have been cleared in \"" +
				currentSchemeName + "\" scheme.");
		}
		sch.save();
		sv.log.debug("You may need to restart Komodo.");

		// A (temporary) hack to allow for R autocompletion/calltips to be
		// triggered with the same key-shortcut as for other languages.
		// cmd_sv_RTriggerCompletion will exit for files other than R
		//var tpc_cmd = document.getElementById("cmd_triggerPrecedingCompletion");
		//tpc_cmd.setAttribute("oncommand", [tpc_cmd.getAttribute("oncommand"),
		//	"ko.commands.doCommandAsync('cmd_sv_RTriggerCompletion',
		//  event);"].join(";"));
	}
}).apply(sv.command);


addEventListener("load", sv.command.setControllers, false);
addEventListener("load", sv.command.setKeybindings, false);

// SciViews-K R functions
// Define functions to pilot R from Komodo Edit 'sv.r' & 'sv.r.pkg'
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org) & K. Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// To cope with versions incompatibilities, we define this:
// sv.alert(sv.r.RMinVersion); // Display minimum R version required
// sv.r.sep; // Item separator that R should use returning data.
// sv.r.running; // Is the linked R interpreter currently running?
// sv.r.test();  // Check if an R interpreter is communicating with us
//
// sv.r.eval(cmd); // Evaluate 'cmd' in R
// sv.r.evalHidden(cmd, earlyExit); // Evaluate 'cmd' in R in a hidden way
// sv.r.evalCallback(cmd, procfun, ...); // Evaluate 'cmd' in R and call 'procfun'
// sv.r.escape(cmd); // Escape R multiline mode, 'cmd' to run then
// sv.r.setwd(); // Set the working dir (choose or set to current buffer)
// sv.r.run(); // Run current selection or line in R and goto next line
// sv.r.runEnter(breakLine = false); // Run current line to pos in R
									 // and add a line feed
// sv.r.source(what); // Source various part of current buffer to R
// sv.r.send(what); // Send various part of current buffer to R
// sv.r.calltip(code); // Get a calltip for a piece of code (current code if "")
// sv.r.calltip_show(tip);		// Companion functions for sv.r.calltip
// sv.r.complete(code); // AutoComplete mechanism for R
// sv.r.display(topic, what); // Display 'topic' according to 'what' type
// sv.r.help(topic, package); // Get help in R for 'topic', 'package' is optional
// sv.r.example(topic); // Run example in R for 'topic', 'topic' is optional
// sv.r.search(topic); // Search R help for 'topic'
// sv.r.search_select(topics); // Callback function: display a list of
                               // choices to select help page from
// sv.r.siteSearch(topic); // Search R web sites for 'topic'
// sv.r.dataList(loaded); // List R datasets in "loaded" or "all" packages
// sv.r.data(); // Select one dataset to load
// sv.r.data_select(data); // Callback function for sv.r.data()
// sv.r.browseVignettes(); // Open a web page listing all installed vignettes
// sv.r.saveWorkspace(file, title);  // Save data in a .Rdata file
// sv.r.loadWorkspace(file, attach); // Load the content of a .RData file into
									 // the workspace, or attach it
// sv.r.addHistory(data, cmd);  // Add current command to R's history, used as
								// a procfun in sv.socket.rCommand call
// sv.r.saveHistory(file, title); // Save the history in a file
// sv.r.loadHistory(file, title); // Load the history from a file
// sv.r.saveGraph(type, file, title, height, width, method);
//                  // Save the current R graph in different formats
// sv.r.obj(objClass); // Set active object for objClass (data.frame if omitted)
// sv.r.obj_select(data); // The callback for sv.r.obj() to select an object
// sv.r.obj_select_dataframe(objname); // Select one data frame to activate
// sv.r.obj_select_lm(objname);		   // Select one lm object to activate
// sv.r.obj_refresh_dataframe(data);   // Refresh active data frame's MRUs
// sv.r.obj_refresh_lm(data); 		   // Refresh active 'lm' object
// sv.r.obj_message(); // Refresh statusbar message about active df and lm
// sv.r.refreshSession(); // Refresh MRU lists associated with current session
// sv.r.initSession(dir, datadir, scriptdir, reportdir);
// sv.r.setSession(dir, datadir, scriptdir, reportdir, saveOld, loadNew);
                    // Initialize R session with corresponding directories
					// setSession() also do the change in R and is to be used
					// preferably, except at Komodo startup!
                    // dir: session directory, xxxdir: xxx subdirectory,
                    // saveOld (default true): do we save old session data?
                    // loadNew (default true): do we load data from new session?
// sv.r.switchSession(inDoc); // Switch to another R session (possibly create it)
// sv.r.exploreSession(); // Explore the session dirs in default file browser
// sv.r.clearSession();   // Clear session's .RData and .Rhistory files
// sv.r.reloadSession();  // Reload .RData nd .Rhistory files from session dir
// sv.r.quit(save); // Quit R (ask to save in save in not defined)
//
// Note: sv.r.objects is implemented in robjects.js
//       sv.r.console functions are implemented in rconsole.js
//
// sv.r.pkg namespace: /////////////////////////////////////////////////////////
// sv.r.pkg.repositories(); // Select repositories for installing R packages
// sv.r.pkg.chooseCRANMirror(andInstall); // replacement for .CRANmirror,
							// optionally calls .install after execution
// sv.r.pkg.available();    // List available R packages on selected repository
// sv.r.pkg.installed();    // List installed R packages
// sv.r.pkg.new(); // List new R packages available on CRAN
// sv.r.pkg.old(); // List older installed R packages than distributed versions
// sv.r.pkg.update(); // Update installed R packages from the repositories
// sv.r.pkg.status(); // Show status of installed R packages
// sv.r.pkg.loaded(); // Show which R packages are loaded
// sv.r.pkg.load(); // Load one R package
// sv.r.pkg.unload(); // Unload one R package
// sv.r.pkg.unload_select(pkgs); // Callback function for sv.r.pkg.unload()
// sv.r.pkg.remove(); // Remove one R package
// sv.r.pkg.remove_select(pkgs); // Callback function for sv.r.pkg.remove()
// sv.r.pkg.install(pkgs, repos); // Install R package(s) from local files or repositories


/// REMOVED! replaced by sv.r.pkg.install
// sv.r.pkg.installLocal(); // Install one or more R packages from local files
// sv.r.pkg.installSV(); // Install the SciViews-R packages from CRAN
// sv.r.pkg.installSVrforge(); // Install development versions of SciViews-R
                               // from R-Forge
// sv.r.pkg.CRANmirror();   // Select preferred CRAN mirror

/// REMOVED! use sv.command.openHelp instead
// sv.r.helpStart(start); // Start R help in the browser, unless start is false

////////////////////////////////////////////////////////////////////////////////
//
// TODO: in overlay: add "source file" context menu item in the project tab
// TODO: get R encoding immediatelly after first connection/track further change

// Define the 'sv.r' namespace
if (typeof(sv.r) == 'undefined')
	sv.r = {
		RMinVersion: "2.10.0",
		sep: ";;"
	};

// TODO: get R encoding after server starts:
//sv.r.init = function(cmd) {
//}

// Indicate if R is currently running
sv.r.running = false;

// Used to record pending commands while R is starting
sv.r.pendingCmd = "";
sv.r.pendingFun = null;
sv.r.pendingContext = "";

sv.r.test = function sv_RTest () {
	function sv_RTest_callback (response) {
		var wasRRunning = sv.r.running;
		var isRRunning = response == "ok!";

		sv.r.running = isRRunning;
		if (wasRRunning != isRRunning) {
			if (isRRunning) {
				// Remove message in the statusbar
				sv.cmdout.message("");
				// update character set used by R
				sv.socket.updateCharset(true);
				window.setTimeout(function() {
					sv.log.info(sv.translate("R uses \"%S\" encoding.",
					sv.socket.charset));
				}, 1000);
				// If there is a pending command, then run it now
				var cmd = sv.r.pendingCmd;
				if (cmd != "") {
					sv.r.pendingCmd = ""; 	// Clear command
					// If pendingFun is defined, use evalCallback
					if (sv.r.pendingFun != null) {
						sv.r.evalCallback(cmd, sv.r.pendingFun,
							sv.r.pendingContext);
						// Clear pendingFun and pendingContext
						sv.r.pendingFun = null;
						sv.r.pendingContext = "";
					} else { 				// Just run this command
						sv.r.eval(cmd);
					}
				} else {
					// Possibly refresh the GUI by running SciViews-specific
					// R task callbacks and make sure R Objects pane is updated
					sv.r.evalCallback("try(guiRefresh(force = TRUE), " +
						"silent = TRUE)", function () {
							sv.r.objects.getPackageList(true); });
				}
			}
			//xtk.domutils.fireEvent(window, 'r_app_started_closed');
			window.updateCommands('r_app_started_closed');
			sv.log.debug("R state changed: " + wasRRunning + "->" + isRRunning);
		}
	}
	var res = sv.socket.rCommand("<<<h>>>cat('ok!');", false, null,
		sv_RTest_callback, "R test");
	return res;
}

// Evaluate code in R
sv.r.eval = function (cmd) {
	// If R is not running, start it now
	if (!sv.r.running) {
		// Indicate R should be started
		sv.cmdout.message(sv.translate("R must be started for this command (R -> Start R)"),
						  5000, true);
		// Indicate that we want to execute this command when R is started
		//sv.r.pendingCmd = cmd;
		// and start R now
		//sv.command.startR();
		return null;
	}
	cmd = cmd.rtrim();
	// Store the current R command
	if (sv.socket.prompt == ":> ") {
		// Special case for q() and quit() => use sv.r.quit() instead
		if (cmd.search(/^q(?:uit)?\s*\(\s*\)$/) > -1) return(sv.r.quit());
		// This is a new command
		sv.socket.cmd = cmd;
	} else {
		// We continue previous multiline command
		sv.socket.cmd += '<<<n>>>' + cmd;
	}
	if (sv.socket.cmdout) {
		if (sv.socket.prompt == ":> ") {
			sv.cmdout.clear();
			sv.cmdout.append(":> " + cmd);
		} else {
			sv.cmdout.append(cmd);
		}
	}
	var res = sv.socket.rCommand('<<<e>>>' + cmd, sv.socket.cmdout, null,
		sv.r.addHistory, sv.socket.cmd);
	return(res);
}

// Evaluate code in R in a hidden way
sv.r.evalHidden = function (cmd, earlyExit) {
	// If R is not running, do nothing
	if (!sv.r.running) { return null; }
	var preCode = "<<<h>>>";
	if (earlyExit) preCode = "<<<H>>>";
	// Evaluate a command in hidden mode (contextual help, calltip, etc.)
	var res = sv.socket.rCommand(preCode + cmd, false);
	return(res);
}
// Tests:
//sv.r.evalHidden("Sys.sleep(5); cat('done\n')");
//sv.r.evalHidden("Sys.sleep(5); cat('done\n')", earlyExit = true);
//sv.r.evalHidden("Sys.sleep(3); cat('done\n');" +
//   " koCmd('alert(\"koCmd is back\");')", earlyExit = true);

// Evaluate R expression and call procfun in Komodo with the result as argument
// all additional arguments will be passed to procfun,
// result will be stored in procfun.value
sv.r.evalCallback = function (cmd, procfun) {
	// If R is not running, do nothing
	if (!sv.r.running) {
		// Indicate R should be started
		sv.cmdout.message("R must be started for this command (R -> Start R)", 5000, true);
		// Indicate that we want to execute this command when R is started
		// We don't use this any more if R is not started automatically
		//... but we keep it for now for a future implementation using okCancel
		//sv.r.pendingCmd = cmd;
		//sv.r.pendingFun = procfun;
		//sv.r.pendingContext = context;
		// and start R now
		//sv.command.startR();
		return null;
	}
	var args = Array.apply(null, arguments);
	args.splice(0, 1, "<<<h>>>" + cmd, false, null);

	// Evaluate a command in hidden mode (contextual help, calltip, etc.)
	// and call 'procfun' at the end of the evaluation
	var res = sv.socket.rCommand.apply(sv.socket, args);
	return(res);
}

// Escape R calculation
sv.r.escape = function (cmd) {
	// If R is not running, do nothing
	if (!sv.r.running) { return null; }
	// Send an <<<esc>>> sequence that breaks multiline mode
	sv.socket.cmd = "";
	sv.socket.prompt == ":> ";
	if (sv.socket.cmdout) { sv.cmdout.clear(); }
	var listener = { finished: function(data) {} }
	if (typeof(cmd) == "undefined") {
		var res = sv.socket.rCommand('<<<esc>>>', false);
	} else {
		var res = sv.socket.rCommand('<<<esc>>>' + cmd, false);
	}
	return(res);
}

// Set the current working directory (to current buffer dir, or ask for it)
// TODO: make it update sv.prefs.setSession?
sv.r.setwd = function (dir, ask, type) {
	// TODO: simplify this:
	// for compatibility with previous versions
	switch (arguments.length) {
		case  1:
			type = dir;
			dir = null;
			ask = false;
		break;
		case 2:
			type = dir;
			dir = null;
		break;
		default:
	}

	var getDirFromR = "";

	if (!dir || (sv.tools.file.exists(dir) == 2)) { // Not there or unspecified
		//sv.log.debug(dir + ":" + type)
		checkType:
		switch (type) {
			case "this":
				break;
			case "session":
				getDirFromR = "getOption(\"R.initdir\")";
				break;
			case "previous":
				getDirFromR = "if (exists(\".odir\")) .odir else getwd()";
				break;
			case "init":
				getDirFromR = "getOption(\"R.initdir\")";
				break;
			case "current":
				getDirFromR = "getwd()";
				ask = true;	// Assume ask is always true in this case
				break;
			case "file":
				var kv = ko.views.manager.currentView;
				if (kv) {
					kv.setFocus();
					if (!kv.document.isUntitled) {
						// If not, look for current file directory
						dir = kv.document.file.dirName;
					}
					break;
				}
			case "project":
			default:
				dir = "";
				// try to set current project dir ar default directory
				var ap = ko.projects.manager.getCurrentProject();
				var kv = ko.views.manager.currentView;
				if (ap != null) {
					dir = ko.projects.getDefaultDirectory(ap);
				} else {
					type = "file";
					break checkType;
				}
		}
	}

	var res;
	if (getDirFromR) {
		var cmd = "cat(path.expand(" + getDirFromR + "))";
		sv.cmdout.message(sv.translate("Asking R for directory..."));

		res = sv.r.evalCallback(cmd, function(curDir) {
			sv.cmdout.message();
			if (!curDir) {
				sv.alert(sv.translate("Cannot retrieve directory from R." +
					" Make sure R is running."));
				return null;
			}
			if (navigator.platform.search(/^Win/) == 0) {
				curDir = curDir.replace(/\//g, '\\');
			}
			return sv.r.setwd(curDir, ask, "this");
		});
		return res;
	}

	if (ask || !dir)
		dir = ko.filepicker.
			getFolder(dir, sv.translate("Choose working directory"));

	if (dir != null) {
		// No, we want to make it a regular R command (should be included in a
		// script)
		//res = sv.r.evalHidden(".odir <- setwd(\"" + dir.addslashes() + "\")");
		//sv.cmdout.message(sv.translate("Current R's working directory is:"
		//	  + "\"%S\"", dir), 10000);
		sv.r.eval(".odir <- setwd(\"" + dir.addslashes() + "\")");
	}
    return res;
}

// Run current selection or line buffer in R
sv.r.run = function () {
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return false; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		var currentLine = ke.lineFromPosition(ke.currentPos);
		if (ke.selText == "") {
			ke.home();
			ke.lineEndExtend();
			// while ke.selText contains no code, look for next line
			while (ke.selText.replace(/^\s*$/, "") == "") {
				//Are we at the last line?
				currentLine = ke.lineFromPosition(ke.currentPos);
				if( currentLine == ( ke.lineCount - 1 ) )
					return false;
				// Select next line
				ke.lineDown();
				ke.home();
				ke.lineEndExtend();
			}
		}
		var res = sv.r.eval(ke.selText);
		ke.currentPos = ke.selectionEnd; // We want to go past the highest pos
		ke.lineDown();
		ke.homeDisplay();
	} catch(e) {
		return e;
	}
	return res;
}

// Run current line (or selection) up to position and optionally add line feed
sv.r.runEnter = function (breakLine) {
	try {
		var res = false;
		var kv = ko.views.manager.currentView;
		if (!kv)
			return false; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		if (ke.selText == "") {	// Only proceed if selection is empty
			// get text from a line and move caret to the eol
			// do we want to break line here or execute it to the end?
			var text = sv.getTextRange(breakLine? "linetobegin" : "line", true);
			ko.commands.doCommand('cmd_newlineExtra');
			if (text != "") res = sv.r.eval(text);
		} else {
			var res = sv.r.eval(ke.selText);
			ke.currentPos = ke.selectionEnd; // We want to go past the highest pos
			ke.selectionStart = ke.selectionEnd; // Collapse selection
			ko.commands.doCommand('cmd_newlineExtra');
		}
	} catch(e) {
		return e;
	}
	return res;
}

// Source the current buffer or some part of it
sv.r.source = function (what) {
	var res = false;
	try {
		var kv = ko.views.manager.currentView;
		if (!kv)
			return false; // No current view, do nothing!
		kv.setFocus();
		var scimoz = kv.scimoz;
		var doc = kv.document;

		var file;
		if (!doc.isUntitled) {
			file = doc.file.path.addslashes();
		} else {
			file = doc.baseName;
		}

		if (!what)
			what = "all"; // Default value

		// Special case: if "all" and local document is saved, source as the original file
		if (what == "all" && doc.file.isLocal && !doc.isUntitled && !doc.isDirty) {
			res = sv.r.eval('source("' + file +  '", encoding = "' +
				kv.encoding + '")');
		} else {
			// save all or part in the temporary file and source that file
			// After executing, tell R to delete it.
			var code = sv.getTextRange(what);
			sv.cmdout.clear();
			sv.cmdout.append(':> #source("' + file + '*") # buffer: ' +
				what);

			var tempFile = sv.tools.file.temp();
			sv.tools.file.write(tempFile, code, 'utf-8', false);
			tempFile = tempFile.addslashes();

			var cmd = 'tryCatch(source("' + tempFile + '", encoding =' +
				' "utf-8"), finally = {unlink("' + tempFile + '")});';

			sv.r.evalCallback(cmd, function(data) {
				sv.cmdout.append(sv.tools.strings.removeLastCRLF(data));
				sv.cmdout.append(":>");
			});
		}
	} catch(e) {
		sv.log.exception(e, "Unknown error while sourcing R code in"
			+ " sv.r.source().", true);
	}
	return res;
}

// Send whole or a part of the current buffer to R
// place cursor at next line
sv.r.send = function (what) {
	//sv.log.debug("sv.r.send " + what);
	var res = false;
	var kv = ko.views.manager.currentView;
	if (!kv)
		return false; // No current view, do nothing!
	kv.setFocus();
	var ke = kv.scimoz;

	try {
		if (!what)
			what = "all"; // Default value

		var code = sv.getTextRange(what, what.indexOf("sel") == -1).rtrim();
		if (code) {
			// indent multiline commands
			code = code.replace(/\r?\n/g, "\n   ")
			res = sv.r.eval(code);
		}
		if (what == "line" || what == "linetoend") // || what == "para"
			ke.charRight();

	} catch(e) {
		return e;
	}
	return res;
}

// Get a calltip for a R function
sv.r.calltip = function (code) {
	// If code is not defined, get currently edited code
	if (typeof(code) == "undefined" | code == "") {
		code = sv.getTextRange("codefrag");
	}
	var cmd = 'cat(CallTip("' + code.replace(/(")/g, "\\$1") +
		'", location = TRUE))';
	var res = sv.r.evalCallback(cmd, sv.r.calltip_show);
	return(res);
}

// The callback for sv.r.calltip
//TODO: make private
sv.r.calltip_show = function (tip) {
	if (tip != "") {
		//sv.cmdout.message(tip, 2000, true);
		var ke = ko.views.manager.currentView.scimoz;
		ke.callTipCancel();
		ke.callTipShow(ke.anchor, tip.replace(/[\r\n]+/g, "\n"));
	}
}

// AutoComplete mechanism for R
// deprecated??
sv.r.complete = function (code) {

	// If code is not defined, get currently edited code
	if (typeof(code) == "undefined" | code == "") {
		code = sv.getTextRange("codefrag");
	}
	code = code.replace(/(")/g, "\\$1");

	var scimoz = ko.views.manager.currentView.scimoz;
	var cmd = 'Complete("' + code + '", print = TRUE, types = "scintilla")';

	var res = sv.r.evalCallback(cmd, function(autoCstring) {
		// these should be set only once?:
		scimoz.autoCSeparator = 9;
		scimoz.autoCSetFillUps(" []{}<>/():;%+-*@!\t\n\r=$`");

		var autoCSeparatorChar = String.fromCharCode(scimoz.autoCSeparator);
		autoCstring = autoCstring.replace(/^(.*)[\r\n]+/, "");

		var trigPos = RegExp.$1;

		autoCstring = autoCstring.replace(/\r?\n/g, autoCSeparatorChar);

		// code below taken from "CodeIntelCompletionUIHandler"
		var iface = Components.interfaces.koICodeIntelCompletionUIHandler;
		scimoz.registerImage(iface.ACIID_FUNCTION, ko.markers.
			getPixmap("chrome://komodo/skin/images/ac_function.xpm"));
		scimoz.registerImage(iface.ACIID_VARIABLE, ko.markers.
			getPixmap("chrome://komodo/skin/images/ac_variable.xpm"));
		scimoz.registerImage(iface.ACIID_XML_ATTRIBUTE, ko.markers.
			getPixmap("chrome://komodo/skin/images/ac_xml_attribute.xpm"));
		scimoz.registerImage(iface.ACIID_NAMESPACE, ko.markers.
			getPixmap("chrome://komodo/skin/images/ac_namespace.xpm"));
		scimoz.registerImage(iface.ACIID_KEYWORD, ko.markers.
			getPixmap("chrome://komodo/skin/images/ac_interface.xpm"));
		scimoz.autoCChooseSingle = true;
		scimoz.autoCShow(trigPos, autoCstring);
	});
	return res;
}

// Display R objects in different ways
// TODO: allow custom methods + arguments + forcevisible + affect to var
// TODO: this duplicates rObjectsTree.do(), so do something with it
sv.r.display = function (topic, what) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "")
		topic = sv.getTextRange("word");
	if (topic == "") {
		//sv.alert("Nothing is selected!");
	} else {
		// Display data in different ways, depending on what
		switch(what) {
		 case "names":
			res = sv.r.eval("names(" + topic + ")");
			break;
		 case "structure":
			res = sv.r.eval("str(" + topic + ")");
			break;
		 case "summary":
			res = sv.r.eval("summary(" + topic + ")");
			break;
		 case "plot":
			res = sv.r.eval("plot(" + topic + ")");
			break;
		 case "content":
		 case "print":
		 case "show":
		 default:
			res = sv.r.eval(topic);
		}
	}
	return(res);
}


// Get help in R (HTML format)
sv.r.help = function (topic, pkg) {
	var res = false;

	if (typeof(topic) == "undefined" || topic == "")
		topic = sv.getTextRange("word");

	if (topic == "")
		sv.cmdout.message(sv.translate("Selection is empty..."), 1000);

	if (!topic && !pkg) {
		return false;
	} else {
		var cmd = '';
		cmd += pkg? ' package = "' + pkg + '", ' : "";
		cmd += topic? ' topic = "' + topic + '", ' : "";
		cmd = 'cat(getHelpURL(help(' + cmd + ' htmlhelp = TRUE)))';
		// Old version for R < 2.10: cmd = 'cat(unclass(help(' + cmd + ' htmlhelp = TRUE)))';
		// TODO: error handling when package does not exists
		res = sv.r.evalCallback(cmd, sv.command.openHelp);
		sv.cmdout.message(sv.translate("R help asked for \"%S\"", topic),
						  5000, true);
	}
	return res;
}

// Run the example for selected item
// TODO: merge with sv.r.help
sv.r.example = function (topic) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "")
		topic = sv.getTextRange("word");
	if (topic == "") {
		sv.cmdout.message(sv.translate("Selection is empty..."), 1000, false);
	} else {
		res = sv.r.eval("example(" + topic + ")");
		sv.cmdout.message(sv.translate("R example run for \"%S\"", topic),
			5000, true);
	}
	return(res);
}

// Search R help for topic
sv.r.search = function (topic, internal) {
	var res = false;
	if (!topic) {
		topic = sv.getTextRange("word");
		// Ask for the search string
		topic = ko.dialogs.prompt(sv.translate("Search R objects using a regular" +
			" expression (e.g. '^log' for objects starting with 'log')"),
			sv.translate("Pattern"), topic,
			sv.translate("Search R help"), "okRsearchPattern");
	}
	if (topic) {
		// Get list of matching items and evaluate it with sv.r.search_select()
		res = sv.r.evalCallback('cat(apropos("' + topic + '"), sep = "' +
			sv.r.sep + '")', sv.r.search_select);
		sv.cmdout.message(sv.translate("Searching_R_help_for", topic),
			5000, true);
	}
	return(res);
}


sv.r.pager = function(file, title) {
	var rSearchUrl = "chrome://sciviewsk/content/rsearch.html";
	var content = sv.tools.file.read(file);
	//content = content.replace(/([\w\.\-]+)::([\w\.\-]+)/ig, '<a href="javascript:sv.r.help(\'$2\', \'$1\');">$1::$2</a>');
	content = content.replace(/([\w\.\-]+)::([\w\.\-\[]+)/ig,
		'<a href="' + rSearchUrl + '?$1::$2">$1::$2</a>');

	content = "<pre id=\"rPagerTextContent\" title=\"" + title + "\">" + content + "</div>";

	sv.tools.file.write(file, content, sv.socket.charset);
	sv.command.openHelp(rSearchUrl + "?file:" + file);
}

// The callback for sv.r.search
//TODO: make private
sv.r.search_select = function (topics) {
	sv.cmdout.message("");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(topics) == "") {
		sv.cmdout.message(sv.translate("R help for %S not found.", topics));
	} else {	// Something is returned
		var items = topics.split(sv.r.sep);
		if (items.length == 1) {
			// Only one item, show help for it
			res = sv.r.help(sv.tools.strings.removeLastCRLF(topics));
		} else {
			// Select the item you want in the list
			var topic = ko.dialogs.selectFromList("R help topics",
				"Select a topic:", items, "one");
			if (topic != null)
				res = sv.r.help(sv.tools.strings.removeLastCRLF(topic.join("")));
		}
	}
	return(res);
}


// Search R web sites for topic
sv.r.siteSearch = function (topic, idxname) {
	var res = false;
	if (!topic)
		topic = sv.getTextRange("word");
	topic = topic.trim();


	if (!idxname)
		idxname = ["Rhelp08", "functions", "views"];
	else {
		var idxsep = "&idxname=";
		var idxnameAllow = ["Rhelp08", "Rhelp01", "Rhelp02", "functions",
		"views", "R-devel", "R-sig-mixed-models"];

		for (var i in idxname)
			if (idxnameAllow.indexOf(idxname[i]) == -1)
				idxname.splice(i, 1);
	}

	if (!topic) {
		sv.cmdout.message(sv.translate("Selection is empty..."), 1000, false);
		return;
	}

	idxname = idxsep + idxname.join(idxsep);

	// TODO: make it a pref:
	var url = "http://search.r-project.org/cgi-bin/namazu.cgi?query=" + topic +
	"&max=20&result=normal&sort=score" + idxname;

	sv.command.openHelp(url);

}

// List available datasets ("loaded" or not defined = loaded packages, or "all")
// TODO: display results in RHelp window
sv.r.dataList = function (which) {
	var res = false;
	if (typeof(which) == "undefined" | which == "" | which == "loaded") {
		var res = sv.r.eval('data()');
	} else {	// which == "all"
		var res = sv.r.eval('data(package = .packages(all.available = TRUE))');
	}
	return(res);
}

// Load one R dataset
sv.r.data = function () {
	var res = false;
	// Get list of all datasets
	res = sv.r.evalCallback('.tmp <- data();' +
		'cat(paste(.tmp$results[, "Item"], .tmp$results[, "Title"],' +
		' sep = "\t  -  "), sep = "\n"); rm(.tmp)', sv.r.data_select);
	sv.cmdout.message(sv.translate("Listing available R datasets... please wait"),
		20000, true);
	return(res);
}

// The callback for sv.r.data
sv.r.data_select = function (data) {
	sv.cmdout.message("");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(data) == "") {
		sv.alert("Problem retrieving the list of R datasets!");
	} else {	// Something is returned
		var items = data.split("\n");
		// Select the item you want in the list
		var item = ko.dialogs.selectFromList("R Datasets",
			"Select one R dataset:", items, "one");
		if (item != null) {
			// We need to eliminate the definition
			var dat = item[0].split("\t");
			var datname = dat[0];
			// Sometimes, we got 'item (data)' => retrieve 'data' in this case
			datname = datname.replace(/^[a-zA-Z0-9._ ]*[(]/, "");
			datname = datname.replace(/[)]$/, "");
			res = sv.r.evalCallback('data(' + datname + '); cat("' + datname +
				'"); invisible(try(guiRefresh(force = TRUE), silent = TRUE))',
				sv.r.obj_select_dataframe);
		}
	}
	return(res);
}

// Open a menu with all installed vignettes in the default web browser
sv.r.browseVignettes = function () {
	var res = sv.r.eval('browseVignettes()');
	return(res);
}

// Save the content of the workspace in a file
sv.r.saveWorkspace = function (file, title) {
	// Ask for the filename if not provided
	if (typeof(file) == "undefined") {
		if (typeof(title) == "undefined") {
			title = 'Save the R workspace in a file';
		}
		file = ko.filepicker.saveFile("", ".RData", title);
		if (file == null) return;	// User clicked cancel
	}
	sv.r.eval('save.image("' + file + '")');
}

// Load the content of a .RData file into the workspace, or attach it
sv.r.loadWorkspace = function (file, attach, callback, param) {
	// Ask for the filename if not provided
	if (!file) {
		file = sv.fileOpen("", ".RData",
			sv.translate("Browse for R workspace file"),
		    [sv.translate("R workspace") + " (*.RData)|*.RData"], true);
	} else if (typeof file == "string") {
		file = file.split(/[;,]/);
	}
	if (!file || !file.length)
	      return;

	var load = attach?  "attach" : "load";
	var cmd = [];
	for (var i in file) {
		cmd[i] = load + "(\"" + (new String(file[i])).addslashes() + "\")";
	}
	cmd = cmd.join("\n");
	if (callback) {
		sv.r.evalCallback(cmd, callback, param);
	} else {
		sv.r.eval(cmd);
	}
}

// Add current command to R's history,
// used as a procfun in sv.socket.rCommand call
sv.r.addHistory = function (data, cmd) {
	if (sv.socket.prompt == ":> ") {
		var quotedCmd = cmd.trim();
		quotedCmd = quotedCmd.replace(/([\\"'])/g, "\\$1").replace(/[\r\n]+/,
			"\\n").replace("\t", " ");
		sv.socket.rCommand("<<<H>>>" + ".sv.tmp <- strsplit(\"" + quotedCmd +
			"\", \"\\\\s*([\\r\\n]|<<<n>>>)+\\\\s*\", perl = TRUE)[[1]]; " +
			".sv.tmp <- .sv.tmp[.sv.tmp != \"\"]; lapply(.sv.tmp, function(x)" +
			" {.Internal(addhistory((x))) }); rm(.sv.tmp);", false);
	}
}

// Save the history in a file
sv.r.saveHistory = function (file, title) {
	// Ask for the filename if not provided
	if (typeof(file) == "undefined") {
		if (typeof(title) == "undefined")
			title = 'Save the command history in a file';
		file = ko.filepicker.saveFile("", ".Rhistory", title);
		if (file == null) return;	// User clicked cancel
	}
	sv.r.eval('savehistory("' + file.addslashes() + '")');
}

// Load the history from a file
sv.r.loadHistory = function (file, title) {
	// Ask for the filename if not provided
	if (typeof(file) == "undefined") {
		if (typeof(title) == "undefined")
			title = 'Load the history from a file';
		file = ko.filepicker.openFile("", ".Rhistory", title);
		if (file == null) return;	// User clicked cancel
	}
	sv.r.eval('loadhistory("' + file.addslashes() + '")');
}

// There is also dev.copy2pdf() copy2eps() + savePlot windows
// and X11(type = "Cairo")
sv.r.saveGraph = function (type, file, title, height, width, method) {
	if (typeof(type) == "undefined") { type = "png256"; }
	// Get the file extension according to type
	var ext = type.substring(0, 4);
	if (ext != "pgnm" & ext != "tiff" & ext != "jpeg") {
		ext = ext.substring(0, 3);
	}
	if (ext.substring(0, 2) == "ps") { ext = "ps"; }
	if (ext == "jpeg") { ext = "jpg" }
	if (typeof(height) == "undefined") { height = 'dev.size()[2]'; }
	if (typeof(width) == "undefined") { width = 'dev.size()[1]'; }
	if (typeof(method) == "undefined") { method = "pdf"; }
	// Ask for the filename if not provided
	if (typeof(file) == "undefined") {
		if (typeof(title) == "undefined") {
			title = 'Save the graph as "' + type + '"';
		}
		file = ko.filepicker.saveFile("", "Rplot." + ext, title);
		if (file == null) return;	// User clicked cancel
	}
	// Save the current device in R using dev2bitmap()... needs gostscript!
	sv.r.eval('dev2bitmap("' + file.addslashes() + '", type = "' + type +
		'", height = ' + height + ', width = ' + width + ', method = "' +
		method + '")');
}

// Select one object of class 'objClass' from .GlobalEnv
sv.r.obj = function (objClass) {
	// By default, we look at data.frames in .GlobalEnv
	if (typeof(objClass) == "undefined") objClass = "data.frame";
	var res = false;
	// Get list of all objects with such a specification loaded in R
	// If there is a comment attribute, also get it
	res = sv.r.evalCallback('cat("' + objClass + '\n");' +
	  'cat(unlist(apply(matrix(objects(pos = 1)), 1, ' +
	  'function(x) try(if (inherits(get(x), "' + objClass +
	  '")) paste(x, "\t     ",  sub("[\t\n\r].*$", "", ' +
	  'comment(get(x))), sep = ""), silent = TRUE))), sep = ",,,")',
	  sv.r.obj_select);
	sv.cmdout.message("Listing available '" + objClass +
		"'... please wait", 20000, true);
	return(res);
}

// The callback for sv.r.obj
sv.r.obj_select = function (data) {
	sv.cmdout.message("");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(data) == "") {
		sv.alert("Select R objects", "Problem retrieving the list of objects!");
	} else {	// Something is returned
		var res = data.split("\n");
		// First item is objClass, second one is the list of objects
		var objclass = sv.tools.strings.removeLastCRLF(res[0]);
		if (typeof(res[1]) == "undefined") {
			sv.alert("Select R objects", "No object of class '" + objclass +
				"' currently loaded in R memory!");
		} else {	// At least one object, display a selection list
			var items = res[1].split(",,,");
			// TODO: highlight current active object...
			// Select the item you want in the list
			var item = ko.dialogs.selectFromList("Currently loaded '" +
				objclass + "' objects in R",
				"Select one '" + objclass + "' to make it active in Komodo:",
				items, "one");
			if (item != null) {
				// Update default object
				// We need to eliminate the comment first
				var obj = item[0].split("\t");
				var objname = obj[0];
				// The rest of the treatment depends on objClass
				if (objclass == "data.frame") {
					sv.r.obj_select_dataframe(objname);
				} else if (objclass == "lm") {
					sv.r.obj_select_lm(objname);
				} else {
					// Not implemented yet for other objects!
					//alert("Update of MRU lists not implemented yet for other " +
					//	"objects than 'data.frame'");
					// Temporary code: at least set pref value
					sv.prefs.setString("r.active." + objclass, objname, true);
					// Refresh statusbar message in case an 'lm' object is changed
					if (objclass == "lm") sv.r.obj_message();
				}
			}
		}
	}
	return(res);
}

// Display which objects (data frame and lm model, as for Rcmdr) are currently
// active in the Komodo statusbar
sv.r.obj_message = function () {
	// Get the directory of current session
	var ses = sv.prefs.getString("sciviews.session.dir", "~");
	ses = sv.tools.strings.filename(ses);
	// Get currently active data frame
	var df = sv.prefs.getString("r.active.data.frame", "<none>");
	if (df == "<df>") df = "<none>";
	// Get currently active 'lm' object
	var lm = sv.prefs.getString("r.active.lm", "<none>")
	if (lm == "<lm>") lm = "<none>";
	sv.cmdout.message(sv.translate("R session: %S  data: %S linear model: %S", ses, df, lm));
}

// Select one data frame
sv.r.obj_select_dataframe = function (objname) {
	// Refresh the default val and list of vars
	res = sv.r.evalCallback(
		'.active.data.frame <- list(object = "' + objname +
		'", fun = function () {\n' +
		'	if (exists(.active.data.frame$object, envir = .GlobalEnv)) {\n' +
		'		obj <- get(.active.data.frame$object, envir = .GlobalEnv)\n' +
		'		res <- paste(c(.active.data.frame$object, names(obj)), "\t",\n' +
		'		c(class(obj), sapply(obj, class)), "\n", sep = "")\n' +
		'		return(.active.data.frame$cache <<- res)\n' +
		'	} else return(.active.data.frame$cache <<- NULL)\n' +
		'}, cache = "")\n' +
		'cat(.active.data.frame$fun(), sep = "")',
		sv.r.obj_refresh_dataframe);
}

// Callback for sv.r.obj_select_dataframe to refresh the associated MRUs
sv.r.obj_refresh_dataframe = function (data) {
	sv.cmdout.message("");
	// If we got nothing, then the object does not exists any more... clear MRUs
	if (data == "<<<data>>>") {
		//var oldobj = sv.prefs.getString("r.active.data.frame", "");
		sv.prefs.setString("r.active.data.frame", "<df>", true); // Default value
		sv.prefs.mru("var", true, "");
		sv.prefs.mru("var2", true, "");
		sv.prefs.mru("x", true, "");
		sv.prefs.mru("x2", true, "");
		sv.prefs.mru("y", true, "");
		sv.prefs.mru("factor", true, "");
		sv.prefs.mru("factor2", true, "");
		sv.prefs.mru("blockFactor", true, "");
		// Update message in the statusbar
		sv.r.obj_message();
		return(false);
	}

	var items = data.split("\n");
	// First item contains the name of the active object and its class
	var item = sv.tools.strings.removeLastCRLF(items[0]).split("\t");
	var objname = item[0];
	var objclass = item[1];
	// Make sure r.active.data.frame pref is set to obj
	sv.prefs.setString("r.active.data.frame", objname, true);
	items.shift(); // Eliminate first item from the array
	// Create three lists: vars collects all var names, nums and facts do so for
	// only numeric and factor variables (separate items by "|")
	var vars = "", nums = "", facts = "";
	for (i in items) {
		item = sv.tools.strings.removeLastCRLF(items[i]).split("\t");
		// Fill the various lists according to the nature of item
		vars = vars + "|" + item[0];
		if (item[1] == "numeric" | item[1] == "integer")
			nums = nums + "|" + item[0];
		if (item[1] == "factor") facts = facts + "|" + item[0];
	}
	// Eliminate first "|"
	vars = vars.substr(1);
	nums = nums.substr(1);
	facts = facts.substr(1);
	// Add these lists in various MRUs
	// vars => var and var2
	sv.prefs.mru("var", true, vars, "|");
	sv.prefs.mru("var2", true, vars, "|");
	// nums => x, x2, y
	sv.prefs.mru("x", true, nums, "|");
	sv.prefs.mru("x2", true, nums, "|");
	sv.prefs.mru("y", true, nums, "|");
	// facts => factor, factor2, blockFactor
	sv.prefs.mru("factor", true, facts, "|");
	sv.prefs.mru("factor2", true, facts, "|");
	sv.prefs.mru("blockFactor", true, facts, "|");
	// Update message in the statusbar
	sv.r.obj_message();
	return(true);
}

// Select one data frame
sv.r.obj_select_lm = function (objname) {
	// Refresh the default lm object in R session
	res = sv.r.evalCallback(
		'.active.lm <- list(object = "' + objname +
		'", fun = function () {\n' +
		'	if (exists(.active.lm$object, envir = .GlobalEnv)) {\n' +
		'		obj <- get(.active.lm$object, envir = .GlobalEnv)\n' +
		'		res <- paste(.active.lm$object, class(obj), sep = "\t")\n' +
		'		return(.active.lm$cache <<- res)\n' +
		'	} else return(.active.lm$cache <<- NULL)\n' +
		'}, cache = "")\n' +
		'cat(.active.lm$fun(), sep = "")',
		sv.r.obj_refresh_lm);
}

// Callback for sv.r.obj_select to refresh the MRUs associated with lm objects
sv.r.obj_refresh_lm = function (data) {
	sv.cmdout.message("");
	// If we got nothing, then the object does not exists any more... clear MRUs
	if (data == "<<<data>>>") {
		//var oldobj = sv.prefs.getString("r.active.lm", "");
		sv.prefs.setString("r.active.lm", "<lm>", true); // Default value
		// Update message in the statusbar
		sv.r.obj_message();
		return(false);
	}

	var items = data.split("\n");
	// First item contains the name of the active object and its class
	var item = sv.tools.strings.removeLastCRLF(items[0]).split("\t");
	var objname = item[0];
	var objclass = item[1];
	// Make sure r.active.data.frame pref is set to obj
	sv.prefs.setString("r.active.lm", objname, true);
	// Update message in the statusbar
	sv.r.obj_message();
	return(true);
}

// Refresh MRU lists associated with the current session
sv.r.refreshSession = function () {
	var i;
	// Refresh lists of dataset
	var items = sv.tools.file.list(sv.prefs.getString("sciviews.data.localdir"),
		/\.[cC][sS][vV]$/, true);
	sv.prefs.mru("datafile", true, items);
	ko.mru.reset("datafile_mru");
	for (i = items.length - 1; i >= 0; i--) {
		if (items[i] != "")
			ko.mru.add("datafile_mru", items[i], true);
	}

	// Refresh lists of scripts
	items = sv.tools.file.list(sv.prefs.getString("sciviews.scripts.localdir"),
		/\.[rR]$/, true);
	sv.prefs.mru("scriptfile", true, items);
	ko.mru.reset("scriptfile_mru");
	for (i = items.length - 1; i >= 0; i--) {
		if (items[i] != "")
			ko.mru.add("scriptfile_mru", items[i], true);
	}

	// Refresh lists of reports
	items = sv.tools.file.list(sv.prefs.getString("sciviews.reports.localdir"),
		/\.[oO][dD][tT]$/, true);
	sv.prefs.mru("reportfile", true, items);
	ko.mru.reset("reportfile_mru");
	for (i = items.length - 1; i >= 0; i--) {
		if (items[i] != "")
			ko.mru.add("reportfile_mru", items[i], true);
	}
}

// Initialize R session preferences in Komodo
// use sv.r.setSession() except at startup!
sv.r.initSession = function (dir, datadir, scriptdir, reportdir) {
	// Initialize the various arguments
	if (typeof(dir) == "undefined")
		dir = sv.prefs.getString("sciviews.session.dir", "~");
	if (typeof(datadir) == "undefined")
		datadir = sv.prefs.getString("sciviews.session.data", "");
	if (typeof(scriptdir) == "undefined")
		scriptdir = sv.prefs.getString("sciviews.session.scripts", "");
	if (typeof(reportdir) == "undefined")
		reportdir = sv.prefs.getString("sciviews.session.reports", "");

	var localdir = sv.tools.file.path(dir);
	var sep = "/";

	// Refresh preferences
	sv.prefs.setString("sciviews.session.dir", dir, true);
	sv.prefs.setString("sciviews.session.localdir", localdir, true);
	// Subdirectories for data, reports and scripts
	sv.prefs.setString("sciviews.session.data", datadir, true);
	sv.prefs.setString("sciviews.session.scripts", scriptdir, true);
	sv.prefs.setString("sciviews.session.reports", reportdir, true);
	// Combination of these to give access to respective dirs
	if (datadir == "") {
		sv.prefs.setString("sciviews.data.dir", dir, true);
		sv.prefs.setString("sciviews.data.localdir", localdir, true);
	} else {
		sv.prefs.setString("sciviews.data.dir", dir + sep + datadir, true);
		sv.prefs.setString("sciviews.data.localdir",
			sv.tools.file.path(localdir, datadir), true);
	}
	if (scriptdir == "") {
		sv.prefs.setString("sciviews.scripts.dir", dir, true);
		sv.prefs.setString("sciviews.scripts.localdir", localdir, true);
	} else {
		sv.prefs.setString("sciviews.scripts.dir", dir + sep + scriptdir, true);
		sv.prefs.setString("sciviews.scripts.localdir",
			sv.tools.file.path(localdir, scriptdir), true);
	}
	if (reportdir == "") {
		sv.prefs.setString("sciviews.reports.dir", dir, true);
		sv.prefs.setString("sciviews.reports.localdir", localdir, true);
	} else {
		sv.prefs.setString("sciviews.reports.dir", dir + sep + reportdir, true);
		sv.prefs.setString("sciviews.reports.localdir",
			sv.tools.file.path(localdir, reportdir), true);
	}

	var DIRECTORY_TYPE = Components.interfaces.nsIFile.DIRECTORY_TYPE;

	// Look if the session directory exists, or create it
	var file = sv.tools.file.getfile(localdir);

	if (!file || !file.exists() || !file.isDirectory()) {
		sv.log.debug( "Creating session directory... " );
		file.create(DIRECTORY_TYPE, 511);
	}
	// ... also make sure that Data, Script and Report subdirs exist
	var subdirs = [datadir, scriptdir, reportdir];
    for (var i in subdirs) {
		if (subdirs[i] != "") {
            var file = sv.tools.file.getfile(sv.tools.file.path(dir, subdirs[i]));
            // TODO: check for error and issue a message if the file is not a dir
			if (!file.exists() || !file.isDirectory())
            	file.create(DIRECTORY_TYPE, 511);
            delete file;
        }
	}
	// refresh lists of data, scripts and reports found in the session
	sv.r.refreshSession();
	return(dir);
}

// Set a R session dir and corresponding dir preferences both in R and Komodo
sv.r.setSession = function (dir, datadir, scriptdir, reportdir,
	saveOld, loadNew) {
	// Set defaults for saveOld and loadNew
	if (typeof(saveOld) == "undefined") saveOld = true;
	if (typeof(loadNew) == "undefined") loadNew = true;

	// cmd is the command executed in R to switch session (done asynchronously)
	var cmd = "";

	// If dir is the same as current session dir, do nothing
	if (typeof(dir) != "undefined" &
		dir == sv.prefs.getString("sciviews.session.dir", "")) {
		return(false);
	}

	// Before switching to the new session directory, close current one
	// if R is running
	if (saveOld) {
		// Save .RData & .Rhistory in the the session directory and clean WS
		// We need also to restore .required variable
		cmd = 'assignTemp(".required", .required)\nTempEnv()$.Last.sys()\n' +
			'save.image()\nsavehistory()\nrm(list = ls())\n' +
			'.required <- getTemp(".required")\n';

	} else {
		// Clear workspace (hint, we don't clear hidden objects!)
		cmd = 'rm(list = ls())\n'
	}
	// TODO: possibly close the associated Komodo project

	// Initialize the session
	dir = sv.r.initSession(dir, datadir, scriptdir, reportdir);

	// Switch to the new session directory in R
	cmd = cmd + 'setwd("' + dir.addslashes() + '")\noptions(R.initdir = "'
	+ dir.addslashes() + '")\n';

	// Do we load .RData and .Rhistory?
	// TODO: loadhistory APPENDS a history. Make R clear the current history first.
	if (loadNew) {
		cmd = cmd + 'if (file.exists(".RData")) load(".RData")\n' +
					 'if (file.exists(".Rhistory")) loadhistory()\n';
	}

	// Execute the command in R (TODO: check for possible error here!)
	// TODO: run first in R; make dirs in R; then change in Komodo!
	sv.r.evalCallback(cmd, function(data) {
		// Indicate everything is fine
		sv.cmdout.message(sv.translate("R session directory set to '%S'", dir),
			20000, true);
        // Break possible partial multiline command in R from previous session
        // and indicate that we are in a new session now in the R console
        // TODO: report if we load something or not
        sv.r.escape('cat("Session directory is now ' + dir.addslashes() +
            '\n", file = stderr())');
		// Refresh active objects support

        // We most probably need to update the R Objects browser and active objs
		//sv.r.objects.getPackageList(true); // Old command, but refresh only object browser
		sv.r.evalHidden("try(guiRefresh(force = TRUE), silent = TRUE)");
	});

	// TODO: possibly open the Komodo project associated with this session

	return(true);
}

// Switch to another R session (create it if it does not exists yet)
sv.r.switchSession = function (inDoc) {
	var baseDir = "";
	var sessionDir = "";
	// Base directory is different on Linux/Mac OS X and Windows
	if (navigator.platform.indexOf("Win") == 0) {
		baseDir = "~";
	} else {
		baseDir = "~/Documents";
	}
	if (inDoc) {
		// Ask for the session subdirectory
		var Session = "SciViews R Session"
		Session = ko.dialogs.prompt(sv.translate("Session in my documents " +
			"(use '/' for subdirs, like in 'dir/session')"),
			sv.translate("Session"), Session,
			sv.translate("Switch to R session"), "okRsession");
		if (Session != null & Session != "") {
			// Make sure that Session does not start with /, or ./, or ../
			Session = Session.replace(/\^.{0,2}\//, "");
			// Construct session dir
			sessionDir = baseDir + "/" + Session;
		} else sessionDir = "";
	} else {
		// Ask for the session path
		sessionDir = ko.filepicker.
			getFolder(baseDir, sv.translate("Choose session directory"));
	}
	if (sessionDir != null & sessionDir != "") {
		// Subdirectories for data, scripts and reports
		var datadir = "";
		var scriptdir = "";
		var reportdir = "";
		var cfg = "";
		var cfgfile = sv.tools.file.path(sessionDir, ".svData");
		var filefound = false;
		// Look if this directory already exists and contains a .svData file
		if (sv.tools.file.exists(sessionDir) == 2 &
			sv.tools.file.exists(cfgfile) == 1) {
			// Try reading .svData file
			try {
				cfg = sv.tools.file.read(cfgfile, "utf-8");
				filefound = true;
				// Actualize values for datadir, scriptdir and reportdir
				cfg = cfg.split("\n");
				var key, value;
				for (i in cfg) {
					key = cfg[i].split("=");
					if (key[0].trim() == "datadir") datadir = key[1].trim();
					if (key[0].trim() == "scriptdir") scriptdir = key[1].trim();
					if (key[0].trim() == "reportdir") reportdir = key[1].trim();
				}
			} catch (e) { }
		}
		// If no .svData file found, ask for respective directories
		if (!filefound) {
			datadir = ko.dialogs.prompt(
				sv.translate("Subdirectory for datasets (nothing for none):"),
				"", "data", sv.translate("R session configuration"), "okRsesData");
			if (datadir == null) return false;
			scriptdir = ko.dialogs.prompt(
				sv.translate("Subdirectory for R scripts (nothing for none):"),
				"", "R", sv.translate("R session configuration"), "okRsesScript");
			if (scriptdir == null) return false;
			reportdir = ko.dialogs.prompt(
				sv.translate("Subdirectory for reports (nothing for none):"),
				"", "doc", sv.translate("R session configuration"), "okRsesReport");
			if (reportdir == null) return false;
		}
		// Now create or switch to this session directory
		sv.r.setSession(sessionDir, datadir, scriptdir, reportdir);
		// If there were no .svData file, create it now
		if (!filefound) {
			// Save these informations to the .svData file in the session dir
		sv.tools.file.write(cfgfile,
			"datadir=" + datadir + "\nscriptdir=" + scriptdir +
			"\nreportdir=" + reportdir, "utf-8", false);
		}
	return true;
	}
}

// Show the session directory in the file explorer, finder, nautilus, ...
sv.r.exploreSession = function () {
	var dataDir = sv.prefs.getString("sciviews.session.localdir", "~");
	var file = Components.classes["@mozilla.org/file/local;1"]
		.createInstance(Components.interfaces.nsILocalFile);
	file.initWithPath(dataDir);
	if (file.exists() == true) {
		try {
			file.reveal();
		} catch(e) { // On Linux, this does not work...
			// First try nautilus, and then, try konqueror
			try {
				ko.run.runEncodedCommand(window,
					'nautilus "' + file.path + '" & ');
			} catch(e) {
				ko.run.runEncodedCommand(window,
					'konqueror --profile filemanagement "' + file.path + '" & ');
			}
		}
	}
}

// Reload .RData and .Rhistory files from session directory
sv.r.reloadSession = function () {
	// Ask for confirmation first
	if (ko.dialogs.okCancel("Are you sure you want to delete all objects " +
		"and reload them from disk?", "OK", "You are about to delete all " +
		"objects currently in R memory, and reload the initial content from " +
		"disk (.RData and .Rhistory files)...", "Reload session") == "OK") {
		// Switch temporarily to the session directory and try loading
		// .RData and Rhistory files
		var dir = sv.prefs.getString("sciviews.session.dir", "");
		var cmd = 'rm(list = ls(pattern = "[.]active[.]", all.names = TRUE))\n' +
			'rm(list = ls()); .savdir. <- setwd("' + dir + '")\n' +
			'if (file.exists(".RData")) load(".RData")\n' +
			'if (file.exists(".Rhistory")) loadhistory()\n' +
			'setwd(.savdir.); rm(.savdir.)\n' +
			'try(guiRefresh(force = TRUE), silent = TRUE)';
		sv.r.evalHidden(cmd);
	}
}

// Clear .RData and .Rhistory files from session directory
sv.r.clearSession = function () {
	// Ask for confirmation first
	if (ko.dialogs.okCancel("Are you sure you want to delete .RData and " +
		".Rhistory files from disk?", "OK", "You are about to delete the data" +
		" saved in .RData and the command history saved in .Rhistory for the " +
		"current session...", "Clear session") == "OK") {
		// Delete .RData and Rhistory files
		var dir = sv.prefs.getString("sciviews.session.dir", "");
		var cmd = '.savdir. <- setwd("' + dir + '")\n' +
			'unlink(".RData"); unlink(".Rhistory")\n' +
			'setwd(.savdir.); rm(.savdir.)';
		sv.r.evalHidden(cmd);
	}
}

// Quit R (ask to save in save in not defined)
sv.r.quit = function (save) {
	if (typeof(save) == "undefined") {
		// Ask for saving or not
		var response = ko.dialogs.customButtons("Do you want to save the" +
			" workspace (.RData) and the command history (.Rhistory) in" +
			" the session directory first?", ["Yes", "No", "Cancel"], "No",
			null, "Exiting R");
		if (response == "Cancel") { return; }
	} else {
		response = save? "yes" : "no";
	}
	// Quit R
	sv.r.eval('q("' + response.toLowerCase() + '")');
	// Clear the R-relative statusbar message
	sv.cmdout.message("");
	// Clear the objects browser
	sv.r.objects.clearPackageList();
}


//// Define the 'sv.r.pkg' namespace ///////////////////////////////////////////
if (typeof(sv.r.pkg) == 'undefined') sv.r.pkg = new Object();

// Select repositories
// TODO: a Komodo version of this that returns pure R code
sv.r.pkg.repositories = function () {
	var res = sv.r.eval('setRepositories(TRUE)');
	return(res);
}

// Select CRAN mirror, with optional callback
sv.r.pkg.chooseCRANMirror = function (callback) {
	var res = false;

	var cmd = 'assignTemp("cranMirrors", getCRANmirrors(all = FALSE, local.only = FALSE));' +
		'write.table(getTemp("cranMirrors")[, c("Name", "URL")], col.names = FALSE, quote = FALSE, sep ="' + sv.r.sep + '", row.names = FALSE)';

	res = sv.r.evalCallback(cmd, function (repos) {
			var res = false;

			if (repos.trim() == "") {
				sv.alert("Error getting CRAN Mirrors list.");
			} else {
				repos = repos.split(/[\n\r]+/);
				var names = [], urls = [];
				for (i in repos) {
					var m = repos[i].split(sv.r.sep);
					names.push(m[0]);
					urls.push(m[1]);
				}
				items = ko.dialogs.selectFromList(sv.translate("CRAN mirrors"),
					sv.translate("Select CRAN mirror to use:"), names, "one");

				repos = urls[names.indexOf(items[0])].replace(/\/$/, "");
				sv.cmdout.message(sv.translate("Current CRAN mirror is set to %S",
					repos), 5000, false);

				sv.r.eval('with(TempEnv(), { repos <- getOption("repos");' +
						  'repos["CRAN"] <- "' + repos + '"; ' +
						  'options(repos = repos) } )');
				sv.r.pkg.repos = repos;
				if (callback)	callback(repos);

			}
			return(res);
		});
	sv.cmdout.message(sv.translate("Retrieving CRAN mirrors list... please wait."),
					  20000, true);
	return(res);
}


// List available packages on the selected repositories
sv.r.pkg.available = function () {
	var res = sv.r.eval('.pkgAvailable <- available.packages()\n' +
		'as.character(.pkgAvailable[, "Package"])');
	sv.cmdout.message(sv.translate("Looking for available R packages... please wait"),
		5000, true);
	return(res);
}

// List installed packages
sv.r.pkg.installed = function () {
	var res = sv.r.eval('.pkgInstalled <- installed.packages()\n' +
		'as.character(.pkgInstalled[, "Package"])');
	sv.cmdout.message(sv.translate("Looking for installed R packages... please wait"),
		5000, true);
	return(res);
}

// List new packages in the repositories
sv.r.pkg.new = function () {
	var res = sv.r.eval('(.pkgNew <- new.packages())');
	sv.cmdout.message(sv.translate("Looking for new R packages... please wait"),
		5000, true);
	return(res);
}

// List installed packages which are older than those in repository (+ versions)
sv.r.pkg.old = function () {
	var res = sv.r.eval('.pkgOld <- old.packages()\n' +
		'noquote(.pkgOld[, c("Installed", "ReposVer")])');
	sv.cmdout.message(sv.translate("Looking for old R packages... please wait"),
		5000, true);
	return(res);
}

// Update installed packages
sv.r.pkg.update = function () {
	var res = sv.r.eval('update.packages(ask = "graphics")');
	sv.cmdout.message(sv.translate("Updating R packages... please wait"), 5000, true);
	return(res);
}

// Some statistics about R packages
sv.r.pkg.status = function () {
	var res = sv.r.eval('(.pkgStatus <- packageStatus())');
	sv.cmdout.message(sv.translate("Compiling R packages status... please wait"),
		5000, true);
	return(res);
}

// Which R packages are currently loaded?
sv.r.pkg.loaded = function () {
	var res = sv.r.eval('(.packages())');
	return(res);
}

// Load one R package
sv.r.pkg.load = function () {
	var res = false;
	sv.cmdout.message(sv.translate("ListingPackages"),
		20000, true);

	// Get list of installed R packages that are not loaded yet
	res = sv.r.evalCallback('.tmp <- .packages(all.available = TRUE);' +
		'cat(.tmp[!.tmp %in% .packages()], sep = "' + sv.r.sep + '"); rm(.tmp)',
		function (pkgs) {
			sv.cmdout.message("");
			var res = false;
			if (pkgs.trim() == "") {
				sv.alert("All installed R packages seem to be already loaded!");
			} else {	// Something is returned
				var items = pkgs.split(sv.r.sep);
				// Select the item you want in the list
				var topic = ko.dialogs.selectFromList(
					sv.translate("Load R package"),
					sv.translate("Select R package(s) to load") + ":", items);
				if (topic != null) {
					// TODO: make a R function in svMisc instead!
					res = sv.r.evalCallback('cat(paste(lapply(c("' +
						topic.join('", "') + '"), function(pkg) { res <- try('
						+ 'library(package = pkg, character.only = TRUE)); ' +
						'paste("Package", sQuote(pkg), if (inherits(res,' +
						' "try-error")) "could not be loaded" else "loaded")' +
						'}), collapse = "\\n"), "\\n")', sv.cmdout.append);
				}
			}
			return(res);
		});
	return(res);
}

// Unload one R package
sv.r.pkg.unload = function () {
	var res = false;
	// Get list of loaded packages, minus required ones we cannot unload
	res = sv.r.evalCallback('.tmp <- .packages(); cat(.tmp[!.tmp %in%' +
		' c(if (exists(".required")) .required else NULL, "base")],' +
		' sep = "' + sv.r.sep + '"); rm(.tmp)', sv.r.pkg.unload_select);
	sv.cmdout.message(sv.translate("Listing loaded R packages... please wait"),
		20000, true);
	return(res);
}

// The callback for sv.r.pkg.unload
//TODO: make private
sv.r.pkg.unload_select = function (pkgs) {
	sv.cmdout.message("");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		sv.alert("None of the loaded packages are safe to unload!");
	} else {	// Something is returned
		var items = pkgs.split(sv.r.sep);
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Unload R package",
			"Select one R package to unload:", items, "one");
		if (topic != null) {
            res = sv.r.eval("detach(\"package:" + topic[0].trim()+ "\")");
		}
	}
	return(res);
}

// Remove one R package
sv.r.pkg.remove = function () {
	var res = false;
	// Get list of all packages, minus required/recommended we cannot remove
	res = sv.r.evalCallback('.tmp <- installed.packages(); ' +
		'.tmp <- rownames(.tmp)[is.na(.tmp[, "Priority"])]; ' +
		'cat(.tmp[!.tmp %in% c(if (exists(".required")) .required else NULL,' +
		' "svMisc", "svIDE", "svGUI", "svSocket", "svIO", "svViews",' +
		' "svWidgets", "svDialogs")], sep = "' + sv.r.sep + '"); rm(.tmp)',
		sv.r.pkg.remove_select);
	sv.cmdout.message(sv.translate("Listing removable R packages... please wait"),
		20000, true);
	return(res);
}

// The callback for sv.r.pkg.remove
sv.r.pkg.remove_select = function (pkgs) {
	sv.cmdout.message("");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		sv.alert(sv.translate("None of the installed R packages are safe to remove!"));
	} else {	// Something is returned
		var items = pkgs.split(sv.r.sep);
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Remove R package",
			"Select one R package to remove:", items, "one");
		if (topic != null) {
			var pkg = (sv.tools.strings.removeLastCRLF(topic.join('')));
			var response = ko.dialogs.customButtons(
				"You are about to remove the '" + pkg +
				"' R package from disk! Are you sure?",
				["&Continue...", "Cancel"], "Continue...", null,
				"Removing an R package");
			if (response == "Cancel") { return res; }

			res = sv.r.eval('remove.packages("' + pkg +
				'", lib = installed.packages()["' + pkg + '", "LibPath"])');
		}
	}
	return(res);
}


// sv.r.pkg.install - install R packages
// examples:
// sv.r.pkg.install() // use default CRAN mirror
// sv.r.pkg.install("", true) // re-set CRAN mirror
// sv.r.pkg.install(["boot", "lme4"])
// sv.r.pkg.install("", "local") // local installation, popups "Open file" dialog
// sv.r.pkg.install("/path/to/packages", "local") // with initial path
// sv.r.pkg.install("sciviews") // install all sciViews packages
// sv.r.pkg.install("sciviews", "r-forge") // ... from R-Forge
// sv.r.pkg.install("sciviews", "http://r.meteo.uni.wroc.pl") // use different CRAN mirror

sv.r.pkg.install = function (pkgs, repos) {
	// Just in case, to prevent infinite callbacks
	// but such should never happen
	var allowCCM = arguments.length < 3;

	var res = false;
	var reset = repos === true;

	function _installCallback() {
			sv.r.pkg.install(pkgs, sv.r.pkg.repos, true);
	};

	if (!repos && sv.r.pkg.repos) {
		repos = sv.r.pkg.repos;
	} else if (reset && allowCCM) {
		res = sv.r.pkg.chooseCRANMirror(_installCallback);
		return;
	} else if (!repos && allowCCM) {
		res = sv.r.evalCallback("cat(getOption(\"repos\")[\"CRAN\"])",
			function(cran) {
				var res = false;
				cran = cran.trim();
				if (cran == "@CRAN@") {
					res = sv.r.pkg.chooseCRANMirror(_installCallback);
				} else {
					sv.r.pkg.repos = cran;
					res = sv.r.pkg.install(pkgs, sv.r.pkg.repos, true);
				}
				return;
			}
		);
		return;
	}

	// At this point repos should be always set
	sv.cmdout.append(sv.translate("Using repository at %S", repos));

	repos = repos.toLowerCase();

	var startDir = null;
	if (typeof pkgs == "string" &&
		sv.tools.file.exists(pkgs) == sv.tools.file.TYPE_DIRECTORY) {
		repos = "local";
		startDir = pkgs;
	}

	// no packages provided, popup a list with available ones
	// then callback again
	if (!pkgs && repos != "local") {
		sv.cmdout.message(sv.translate("Listing available packages..."), 5000);
		res = sv.r.evalCallback('cat(available.packages()[,1], sep="' +
			sv.r.sep + '")', function (pkgs) {
				sv.cmdout.message("");

				var res = false;
				if (pkgs.trim() != "") {
					pkgs = pkgs.split(sv.r.sep);
					// Case insensitive sorting:
					pkgs.sort(function(a,b) a.toUpperCase() > b.toUpperCase());

					pkgs = ko.dialogs.selectFromList(
						sv.translate("Install R package"),
						sv.translate("Select package(s) to install") + ":", pkgs);

					if (pkgs != null) {
						res = sv.r.pkg.install(pkgs, repos, true);
					}
				}
			});
		return;

	}

	// Expand short names
	if (repos == "r-forge") {
		repos = "http://r-forge.r-project.org";
	} else if (repos == "local") {
		repos = "NULL";

		if (!pkgs || startDir) {
			// Get list of files to install
			pkgs = sv.fileOpen(startDir, null,
				sv.translate("Select package(s) to install"),
					['Zip archive (*.zip)|*.zip', 'Gzip archive (*.tgz;*.tar.gz)|*.tgz;*.tar.gz'], true);

			if (pkgs == null)
				return;

			for (i in pkgs)
				pkgs[i] = pkgs[i].addslashes();
		}
	}

	if (repos != "NULL")
		repos = "\"" + repos + "\"";

	if (typeof pkgs == "string") {
		if (pkgs.toLowerCase() == "sciviews") {
			pkgs = ["svMisc", "svSocket", "svGUI", "svIDE", "svDialogs", "svWidgets",
				"svSweave", "svTools", "svUnit", "tcltk2"];
		} else {
			pkgs = [pkgs];
		}
	}

	var cmd = "install.packages(c(\"" + pkgs.join('", "') + "\"), repos = " +
		repos + ")";
	//sv.cmdout.append(cmd);

	sv.r.eval(cmd);
}


// Initialize the default (last used) R session
sv.r.initSession();

// Temp code
//sv.r.RinterpreterTrial = function (code) {
//	var R = Components
//		.classes["@sciviews.org/svRinterpreter;1"]
//		.getService(Components.interfaces.svIRinterpreter);
//
//	return R.calltip(code);
//}

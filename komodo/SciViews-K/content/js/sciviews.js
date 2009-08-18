// SciViews-K general functions
// Define the basic 'sv' namespace, plus 'sv.cmdout', 'sv.log' & 'sv.prefs'
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.version; // Get current SciViews-K version (major.minor)
// sv.release; // The release (bug fixes). Full version is "version.release"
// sv.showVersion; // Do we display version in an alert() box or just set it?
// sv.checkVersion(version); // Check the SciViews-K extension version is fine
//
// Various functions defined in the 'sv' namespace directly
// sv.alert(header, text); // Own alert box; text is optional
// sv.getText(); // Get current selection, or word under the cursor
// sv.getLine(); // Get current line in the active buffer
// sv.getPart(what, resel, clipboard); // Get a part of text in the buffer
            // or copy it to the clipboard (reset selection if resel == false)

// sv.getTextRange(what, gotoend, select);  // Get a part of text in the buffer,
                                            // but do not operate on selection
// sv.fileOpen(directory, filename, title, filter, multiple); // file open dlg,
            // more customizable replacement for ko.filepicker.open()

// sv.browseURI(URI, internal); // Show URI in internal or external browser
// sv.showFile(path, readonly); // Show a file in Komodo, possibly as read-only
// sv.helpURL(URL); // Display URL help in the default browser
// sv.helpContext(); // Get contextual help for selected word in buffer in R or
                     // for active snippet in toolbox/project (see Help context)
// sv.translate(textId); // translate messages using data from
						 // chrome://sciviewsk/locale/main.properties
//
// SciViews-K preferences management ('sv.prefs' namespace) ////////////////////
// sv.prefs.getString(pref, def); // Get a preference, use 'def' is not found
// sv.prefs.setString(pref, value, overwrite); // Set a preference string
// sv.prefs.askString(pref, defvalue); // Ask for the value of a preference
// sv.prefs.mru(mru, reset, items, sep); //Simplify update of MRU lists
//
// SciViews-K Command Output management ('sv.cmdout' namespace) ////////////////
// sv.cmdout.append(str, newline, scrollToStart); // Append to Command Output
// sv.cmdout.clear(); // Clear the Command Output pane
// sv.cmdout.message(msg, timeout); // Display message in Command Output pane
//
// SciViews-K logging feature ('sv.log' namespace) /////////////////////////////
// sv.log.logger;           // The SciViews-K Komodo logger object
// sv.log.exception(e, msg, showMsg); // Log an exception with error message
                            // and stack. If showMsg == true, also display the
                            // msg in an alert box (optional)
// sv.log.critical(msg);    // Log a critical error
// sv.log.error(msg);       // Log an error
// sv.log.warn(msg);        // Log a warning
// sv.log.warnStack(msg);   // Log a warning and print the calling stack
// sv.log.info(msg);        // Log an info message (if sv.log.isAll() == true)
// sv.log.debug(msg);       // Log a debug message (if sv.log.isAll() == true) 
// sv.log.all(debug);       // Toggle logging of debug/info messages on/off
// sv.log.isAll();          // Do we currently log all messages?
// sv.log.show();           // Show the Komodo log file 
//
// Not used any more?
// sv.checkToolbox(); // Check that the correct SciViews-K toolbox is installed
//
////////////////////////////////////////////////////////////////////////////////

if (typeof(sv) == 'undefined') {
	var sv = {
		// TODO: set this automatically according to the plugin version
		version: 0.8,
		release: 1,
		showVersion: true,
		checkVersion: function (version) {
			if (this.version < version) {
				var title = "SciViews-K"
				var prompt = "Outdated SciViews-K extension..."
				var text = "One or more macros require the SciViews-K plugin "
				text += version + ".x"
				text += " but the currently installed version is "
				text += this.version + "." + this.release
				text += ". You should update it."
				text += " Would you like to open the extension manager"
				text += " and check for available updates now?"
				var res = ko.dialogs.yesNo(prompt, "Yes", text, title);
				if (res == "Yes") ko.launch.openAddonsMgr();
				return(false);
			} else return(true);
		}
	};
}

//DEBUG: this is now obsolete, please, use sv.log.debug()!
// global debugging flag:
//sv.debug = false;
//
//sv.debugMsg = function (msg) {
//	if (sv.debug)
//		sv.cmdout.append("debug: " + msg);
//}


// Create the 'sv.tools' namespace
if (typeof(sv.tools) == 'undefined') sv.tools = new Object();


//// Other functions directly defined in the 'sv' namespace ////////////////////
// Our own alert box
sv.alert = function (header, text) {
    ko.dialogs.alert(header, text, "SciViews-K");
}
//sv.alert("Error:", "Some message");
// -or-
//sv.alert("Message");

// Gets current selection, or word under the cursor in the active buffer
sv.getText = function () {
	var kv = ko.views.manager.currentView;
	if (!kv) return("");
	kv.setFocus();
	var ke = kv.scimoz;
	var txt = ke.selText;
	// If selection is empty, get the word under the cursor
	if (txt == "") txt = ko.interpolate.getWordUnderCursor(ke);
	return(txt);
}

// Get current line of text in the active buffer
sv.getLine = function () {
	var kv = ko.views.manager.currentView;
	if (!kv) return("");
	kv.setFocus();
	var ke = kv.scimoz;
	// retain these so we can reset the selection after the replacement
	var curAnchor = ke.anchor;
	var curPos = ke.currentPos;
	// Get the text in the current line
	ke.home();
	ke.lineEndExtend();
	var currentLine = ke.selText;
	// Reset the selection
	ke.setSel(curAnchor, curPos);
	// Return the content of the current line
	return(currentLine);
}

// Select a part of text in the current buffer and return it
sv.getPart = function (what, resel, clipboard) {
	var range;
	var text = sv.getTextRange(what, false, !resel, range);
	if (clipboard) {
		// Copy to clipboard instead of returning the text
		ke.copyRange(range.value.start, range.value.end);
	}
	return(text);
}

// Select a part of text in the current buffer and return it
// differs from sv.getPart that it does not touch the selection
sv.getTextRange = function (what, gotoend, select, range) {
	var text = "";
	var kv = ko.views.manager.currentView;
	if (!kv) {
		return "";
	}
	kv.setFocus();
	var ke = kv.scimoz;
	// retain these so we can reset the selection after the extraction
	var curPos = ke.currentPos;
	var curLine = ke.lineFromPosition(curPos);

	var pStart = Math.min (ke.anchor, curPos);
	var pEnd = Math.max (ke.anchor, curPos);

	// Depending on 'what', we select different parts of the file
	// By default, we keep current selection
	switch(what) {
	case "sel":
	   // Simply retain current selection
	   break;
	case "function":
	   // tricky one: select an entire R function
	   // this should work even with extremely messy coded ones.

		// function declaration pattern:
		var funcRegExStr = "\\S+\\s*(<-|=)\\s*function\\s*\\(";

		var findSvc = Components.classes['@activestate.com/koFindService;1']
			 .getService(Components.interfaces.koIFindService);

		// save previous find settings
		var oldFindPref = {searchBackward: true, matchWord: false,
            patternType: 0};
		for (var i in oldFindPref) oldFindPref[i] = findSvc.options[i];

		findSvc.options.matchWord = false;
		findSvc.options.patternType = 2;

		var line0, line1, pos1, pos2, pos3, pos4;
		var lineArgsStart, lineBodyStart, firstLine; //lineArgsEnd lineBodyEnd,
		var pos0 = ke.getLineEndPosition(curLine);
		var findRes;

		do {
			//  search for function pattern backwards:
			findSvc.options.searchBackward = true;
			findRes = findSvc.find("", // view.document.displayPath
									ke.text, funcRegExStr,
									ke.charPosAtPosition(pos0), 0); //start, end
			if (!findRes) break;

			// function declaration start:
			pos0 = ke.positionAtChar(0, findRes.start);
			// opening brace of function declaration
			pos1 = ke.positionAtChar(0, findRes.end);
			// closing brace of function declaration
			pos2 = ke.braceMatch(pos1 - 1) + 1;

			// find first character following the closing brace
			findSvc.options.searchBackward = false;
			findRes = findSvc.find("",  //view.document.displayPath
									ke.text, "\\S",
									ke.charPosAtPosition(pos2) + 1,
									ke.charPosAtPosition(ke.length));
			if (!findRes) break;

			//  beginning of the function body:
			pos3 = ke.positionAtChar(0, findRes.end);

			lineArgsStart = ke.lineFromPosition(pos1);
			lineBodyStart = ke.lineFromPosition(pos3);

			// get first line of the folding block:
			firstLine = (ke.getFoldParent(lineBodyStart) != lineArgsStart)?
				lineBodyStart : lineArgsStart;

			// get end of the function body
			if (ke.getWCharAt(pos3 - 1) == "{") {
				pos4 = ke.braceMatch(pos3 - 1) + 1;
			} else {
				pos4 = ke.getLineEndPosition(lineBodyStart);
			}

		// repeat if selected function does not embrace cursor position and if
		// there are possibly any functions enclosing it:
		} while (pos4 < curPos && ke.getFoldParent(lineArgsStart) != -1);

		if (pos4 >= curPos) {
			pStart = pos0;
			pEnd = pos4;
		}

		// restore previous find settings
		for (var i in oldFindPref) findSvc.options[i] = oldFindPref[i];

	   break;
	case "block":
		// Select all content between two bookmarks
		var Mark1, Mark2;
		Mark1 = ke.markerPrevious(curLine, 64);
		if (Mark1 == -1)	Mark1 = 0;
		Mark2 = ke.markerNext(curLine, 64);
		if (Mark2 == -1)	Mark2 = ke.lineCount - 1;

		pStart = ke.positionFromLine(Mark1);
		pEnd = ke.getLineEndPosition(Mark2);

	   break;
	case "para":
	   // Select the entire paragraph
	   // go up from curLine until
	   for (var i = curLine; i >= 0
			&& ke.lineLength(i) > 0
			&& ke.getTextRange(
			   pStart = ke.positionFromLine(i),
			   ke.getLineEndPosition(i)).trim() != "";
			i--) {		}

	   for (var i = curLine; i <= ke.lineCount
			&& ke.lineLength(i) > 0
			&& ke.getTextRange(ke.positionFromLine(i),
			   pEnd = ke.getLineEndPosition(i)).trim() != "";
			i++) {		}

	   break;
	case "line":
		 // Select whole current line
		pStart = ke.positionFromLine(curLine);
		pEnd = ke.getLineEndPosition(curLine);
	   break;
	case "linetobegin":
	   // Select line content from beginning to anchor
	   pStart = ke.positionFromLine(curLine);
	   break;
	case "linetoend":
	   // Select line from anchor to end of line
	   pEnd = ke.getLineEndPosition(curLine);
	   break;
	case "end":
	   // take text from current line to the end
	   pStart = ke.positionFromLine(curLine);
	   pEnd = ke.textLength;

	   break;
	case "all":
	default:
	   // Take everything
	   text = ke.text;
	}

	if (what != "all") {
		text = ke.getTextRange(pStart, pEnd).trim();
		if (gotoend) {
			ke.gotoPos(pEnd);
		}
		if (select) {
			ke.setSel(pStart, pEnd);
		}
	}
	if (typeof (range) == "object") {
		range.value = {start: pStart, end: pEnd};
	}
	return(text);
}

// file open dialog, more customizable replacement for ko.filepicker.open
sv.fileOpen = function (directory, filename, title, filter, multiple) {
	const nsIFilePicker = Components.interfaces.nsIFilePicker;
    var fp = Components.classes["@mozilla.org/filepicker;1"]
        .createInstance(nsIFilePicker);
    if (!title) title = sv.translate("Open file");
    var mode = multiple? nsIFilePicker.modeOpenMultiple : nsIFilePicker.modeOpen;

    fp.init(window, title, mode);
	if (filter) {
        if (typeof(filter) == "string") {
            filter = filter.split(',');
        }
        var fi;
        for (var i = 0; i  < filter.length; i++) {
            fi = filter[i].split("|");
            if (fi.length == 1)
                fi[1] = fi[0];
            fp.appendFilter(fi[0], fi[1]);
        }
    }
    fp.appendFilters(nsIFilePicker.filterAll);

    if (directory) {
        var lf = Components.classes["@mozilla.org/file/local;1"].
            createInstance(Components.interfaces.nsILocalFile);
        lf.initWithPath(directory);
        fp.displayDirectory = lf;
    }
    if (filename) {
        fp.defaultString = filename;
    }

    var rv = fp.show();
    if (rv == nsIFilePicker.returnOK || rv == nsIFilePicker.returnReplace) {
        var path;
        if (multiple) {
            var files = fp.files;
            path = new Array();
            while (files.hasMoreElements()) {
                var file = files.getNext().
                    QueryInterface(Components.interfaces.nsILocalFile);
                path.push(file.path);
            }
        } else {
            path = fp.file.path;
        }
        return(path);
    }
    return (null);
}

// Browse for the URI, either in an internal, or external (default) browser
sv.browseURI = function (URI, internal) {
	if (URI == "") {
		sv.alert(sv.translate("Item not found!"));	// Because we call this from
        // other functions that return "" when they don't find it, see sv.r.help
	} else {
		if (internal == null)
			internal = (sv.prefs.getString("sciviews.r.help",
				"internal") == "internal");
		if (internal == true) {
			// TODO: open this in the R help pane, or in a buffer
			ko.open.URI(URI, "browser");
		} else {
			ko.browse.openUrlInDefaultBrowser(URI);
		}
	}
}

// Show a text file in a buffer, possibly in read-only mode
sv.showFile = function (path, readonly) {
	if (path == "") {
		sv.alert(sv.translate("Item not found!")); // Same as for sv.browseURI()
	} else {
		ko.open.URI(path, "editor");
		if (readonly == true) {
			var kv = ko.views.manager.currentView;
			var ke = kv.scimoz;
			ke.readOnly = true;
			// TODO: use morekomodo approach
            // Make the caret a block and hatch the fold margin as indicator
			ke.caretStyle = 2;
			ke.setFoldMarginColour(true, 100);
			kv.setFocus();
		}
	}
}

// Show URL in the default browser with current selection or <keyword>
sv.helpURL = function (URL) {
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return(false);
		kv.setFocus();
		var ke = kv.scimoz;
		var sel = ke.selText;
		if (sel == "") {
			// Try to get the URL-escaped word under the cursor
			if (ko.interpolate.getWordUnderCursor(ke) == "") {
				sv.alert(sv.translate("Nothing is selected!"));
				return(false);
			} else {
				sel = ko.interpolate.interpolateStrings('%W');
			}
		} else {
			// Get the URL-escaped selection
			sel = ko.interpolate.interpolateStrings('%S');
		}
		var helpURL = URL.replace("<keyword>", sel);
		ko.browse.openUrlInDefaultBrowser(helpURL);
		return(true);
	} catch(e) {
		sv.log.exception(e, "Unable to show " + URL + " in the browser", true);
	}
	return(false);
}

// Get contextual help for a word in the buffer, or for snippets
sv.helpContext = function () {
	try {
		if (ko.window.focusedView() == null) {
			if (ko.projects.active) {
				var item = ko.projects.active.getSelectedItem();
				var content = item.value;
				// Look for a string defining the URL for associated help file
				// This is something like: [[%pref:URL|R|RWiki-help:<value>]]

				// Look for URL-help
				var help = content.replace(/^.*\[\[%pref:URL-help:([^\]]*)]].*$/,
					'$1');
				if (help != content) {	// Found!
					// Show in default browser
					// TODO: a quick 'R help' tab to show this
					ko.browse.openUrlInDefaultBrowser(help);
					return(true);
				}

				// Look for R-help
				help = content.replace(/^.*\[\[%pref:R-help:([^\]]*)]].*$/,
					'$1');
				if (help != content) {	// Found!
					// Do the help command in R
					sv.r.help(help);
					return(true);
				}

				// Look for RWiki-help
				help = content.replace(/^.*\[\[%pref:RWiki-help:([^\]]*)]].*$/,
					'$1');
				if (help != content) {	// Found!
					// Get the RWiki base URL
					var baseURL = "http:/wiki.r-project.org/rwiki/doku.php?id="
					baseURL = sv.prefs.getString("sciviews.rwiki.help.base",
						baseURL);
					// Display the RWiki page
					// TODO: display this in the quick 'R help' tab
					ko.browse.openUrlInDefaultBrowser(baseURL + help);
					return(true);
				}

				// No help data found
				var msg = sv.translate("No help found for this tool!");
				StatusBar_AddMessage(msg, "debugger", 5000, true);
				return(false);
			}
		} else {	// The focus is currently on a buffer
			// Try to get R help for current word
			topic = sv.getText();
			if (topic == "") {
				alert(sv.translate("Nothing is selected!"));
			} else sv.r.help(topic);
		}
		return(true);
	} catch(e) {
		sv.log.exception(e, "Error while trying to get contextual help", true);
		return(false);
	}
}

// translate messages using data from chrome://sciviewsk/locale/main.properties
sv.translate = function (textId) {
	var bundle = Components.classes["@mozilla.org/intl/stringbundle;1"]
		.getService(Components.interfaces.nsIStringBundleService)
		.createBundle("chrome://sciviewsk/locale/main.properties");
	var param;

	try {
		if (arguments.length > 1) {
			param = [];

			for (var i = 1; i < arguments.length; i++)
				param = param.concat(arguments[i]);
			//return strbundle.getFormattedString(textId, param);
			return bundle.formatStringFromName(textId, param, param.length);

		} else {
			//return strbundle.getString(textId);
			return bundle.GetStringFromName(textId);
		}
	} catch (e) {
		// fallback if no translation found
		if (param) { // a wannabe sprintf, just substitute %S and %nS patterns:
			var rx;
			for (var i = 0; i < param.length; i++) {
				rx = new RegExp("%("+ (i + 1) +")?S");
				textId = textId.replace(rx, param[i]);
			}
		}
		return textId;
	}
}


//// Preferences management ////////////////////////////////////////////////////
if (typeof(sv.prefs) == 'undefined') sv.prefs = new Object();

// Get a string preference, or default value
sv.prefs.getString = function (pref, def) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (prefs.hasStringPref(pref)) {
		return(prefs.getStringPref(pref));
	} else return(def);
}

// Set a string preference
sv.prefs.setString = function (pref, value, overwrite) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (overwrite == false & prefs.hasStringPref(pref)) return;
	prefs.setStringPref(pref, value);
}

// Display a dialog box to change a preference string
sv.prefs.askString = function (pref, defvalue) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	// If defvalue is defined, use it, otherwise, use current pref value
	if (defvalue == null & prefs.hasStringPref(pref))
		defvalue = prefs.getStringPref(pref);
	if (defvalue == null) defvalue == "";
	// Display a dialog box to change the preference value
	newvalue = ko.dialogs.prompt("Change preference value for:", pref,
		defvalue, "SciViews-K preference", "svPref" + pref)
	if (newvalue != null) prefs.setStringPref(pref, newvalue);
}

// Simplify update of MRU lists
sv.prefs.mru = function (mru, reset, items, sep) {
	var mruList = "dialog-interpolationquery-" + mru + "Mru";
	// Do we reset the MRU list?
	if (typeof(reset) == "undefined") reset = false;
	if (reset == true) ko.mru.reset(mruList);

	// Do we need to split items (when sep is defined)?
	if (typeof(sep) != "undefined") items = items.split(sep);

	// Add each item in items in inverse order
    for (var i = items.length - 1; i >= 0; i--) {
		ko.mru.add(mruList, items[i], true);
	}
}


//// Control the command output tab ////////////////////////////////////////////
if (typeof(sv.cmdout) == 'undefined') sv.cmdout = {};

// Append text to the Command Output pane
sv.cmdout.append = function (str, newline, scrollToStart) {
	try {
		var runout = ko.run.output;
		// Make sure the command output window is visible
		runout.show(window, false);
		// Make sure we're showing the output pane
		var deckWidget = document.getElementById("runoutput-deck");
		if (deckWidget.getAttribute("selectedIndex") != 0) {
			runout.toggleView();
		}
		// Find out the newline sequence uses, and write the text to it.
		var scimoz = document.getElementById("runoutput-scintilla").scimoz;
		var prevLength = scimoz.length;
		if (newline == null)
			str += ["\r\n", "\n", "\r"][scimoz.eOLMode];

		var str_byte_length = ko.stringutils.bytelength(str);
		var ro = scimoz.readOnly;
		try {
			scimoz.readOnly = false;
			scimoz.appendText(str_byte_length, str);
		} finally { scimoz.readOnly = ro; }

		if (scrollToStart) {
			// Bring the new text into view
			scimoz.gotoPos(prevLength + 1);
		} else {
			scimoz.gotoLine(scimoz.lineCount);
		}
	} catch(e) {
        sv.log.exception(e, "Problems printing [" + str + "]", true);
    }
}

// Clear text in the Output Command pane
sv.cmdout.clear = function () {
	sv.cmdout.message();

	try {
		var runout = ko.run.output;
		// Make sure the command output window is visible
		runout.show(window, false);
		// Make sure we're showing the output pane
		var deckWidget = document.getElementById("runoutput-deck");
		if (deckWidget.getAttribute("selectedIndex") != 0) {
			runout.toggleView();
		}
		var scimoz = document.getElementById("runoutput-scintilla").scimoz;
		var ro = scimoz.readOnly;
		try {
			scimoz.readOnly = false;
			scimoz.clearAll();
		} finally { scimoz.readOnly = ro; }
	} catch(e) {
        sv.log.exception(e, "Problems clearing the Command Output pane", true);
    }
}

// Display message on the command output bar
sv.cmdout.message = function (msg, timeout) {
	document.getElementById('output_tabpanels').selectedIndex = 0;
	var runoutputDesc = document.getElementById('runoutput-desc');
	if (msg == null) msg = "";
	runoutputDesc.style.color = "rgb(0, 0, 0)";
	runoutputDesc.setAttribute("value", msg);
	window.clearTimeout(runoutputDesc.timeout);
	if (timeout > 0)
		runoutputDesc.timeout = window.setTimeout("sv.cmdout.message();",
            timeout);
}


//// Logging management ////////////////////////////////////////////////////////
if (typeof(sv.log) == 'undefined') sv.log = {
	logger: ko.logging.getLogger("SciViews-K")
}

sv.log.exception = function (e, msg, showMsg) {
    if (typeof(showMsg) != 'undefined' & showMsg == true) {
        sv.alert("Error", msg);
    }
    this.logger.exception(e, msg);
}

sv.log.critical = function (msg) {
    this.logger.critical(msg);
}

sv.log.error = function (msg) {
    this.logger.error(msg);
}

sv.log.warn = function (msg) {
    this.logger.warn(msg);
}

sv.log.warnStack = function (msg) {
    this.logger.deprecated(msg);
}

sv.log.info = function (msg) {
    this.logger.info(msg);
}

sv.log.debug = function (msg) { 
    this.logger.debug(msg);
}

sv.log.all = function (debug) {
    if (typeof(debug) == "undefined" || debug == false) {
        this.logger.setLevel(false);
    } else {
        this.logger.setLevel(true); 
    }
}

sv.log.isAll = function () {
    return(this.logger.getEffectiveLevel() == 1);
}

sv.log.show = function () {
    var os = Components.classes['@activestate.com/koOs;1'].
        getService(Components.interfaces.koIOs);
    try {
        appdir = komodo.interpolate('%(path:hostUserDataDir)');
        var logFile = os.path.join(appdir, 'pystderr.log');
        var winOpts = "centerscreen,chrome,resizable,scrollbars,dialog=no,close";
        window.openDialog('chrome://komodo/content/tail/tail.xul',"_blank",
            winOpts,logFile);
    } catch(e) {
        sv.log.exception(e, "Unable to display the Komodo error log!", true);
    }
}

//// Tests... default level do not print debug and infos!
//sv.log.all(false);
//alert(sv.log.isAll());
//try {
//   test = nonexistingvar; 
//} catch(e) {sv.log.exception(e, "Test it exception"); }
//sv.log.critical("Test it critical");
//sv.log.error("Test it error");
//sv.log.warn("Test it warning");
//sv.log.info("Test it info");
//sv.log.debug("Test it debug");
//sv.log.warnStack("Test it warn with stack");
//// Set at debug/info level
//sv.log.all(true);
//alert(sv.log.isAll());
//sv.log.critical("Test it critical 2");
//sv.log.error("Test it error 2");
//sv.log.warn("Test it warning 2");
//sv.log.info("Test it info 2");
//sv.log.debug("Test it debug 2");
//sv.log.warnStack("Test it warn with stack 2");
//// Show Komodo log
//sv.log.show();


//// Not used any more? ////////////////////////////////////////////////////////
sv.checkToolbox = function () {
    try {
		var pkg = ko.interpolate.interpolateStrings("%(path:hostUserDataDir)");
		pkg += "/XRE/extensions/sciviewsk@sciviews.org/templates/SciViews-K.kpz";
		var partSvc = Components.classes["@activestate.com/koPartService;1"]
			.getService(Components.interfaces.koIPartService);
		var SciViewsK_folders = partSvc.getParts("folder", "name", "SciViews-K",
			"*", partSvc.currentProject, new Object());
		if (SciViewsK_folders.length == 0) {
			// The SciViews-K toolbox is not installed yet... do it now
			ko.toolboxes.importPackage(pkg);
		} else {
			// First, eliminate all SciViews-K toolboxes that are too old
			var VersionMacro;
			var SciViewsK_folder;
			sv.showVersion = false;
			for (var i = 0; i < SciViewsK_folders.length; i++) {
				SciViewsK_folder = SciViewsK_folders[i];
				VersionMacro = SciViewsK_folder.
                    getChildWithTypeAndStringAttribute(
					"macro", "name", "Version", true);
				if (VersionMacro) {
					ko.projects.executeMacro(VersionMacro);
					if (SciViewsKtoolboxVersion < sv.version) {
						// This toolbox is too old for our extension
						ko.toolboxes.user.removeItem(SciViewsK_folder, true);
					}
				} else {
					// Probably a corrupted SciViews-K toolbox => eliminate it
					ko.toolboxes.user.removeItem(SciViewsK_folder, true);
				}
			}
			// Recheck how many SciViews-K toolboxes are left
			SciViewsK_folders = partSvc.getParts("folder", "name", "SciViews-K",
				"*", partSvc.currentProject, new Object());
			if (SciViewsK_folders.length == 0) {
				// Install the new one now
				ko.toolboxes.importPackage(pkg);
			} else if (SciViewsK_folders.length > 1) {
				// There are duplications, keep only last one
				for (var i = 0; i < (SciViewsK_folders.length - 1); i++) {
					SciViewsK_folder = SciViewsK_folders[i];
					ko.toolboxes.user.removeItem(SciViewsK_folder, true);
				}
			}
		}
	} catch(e) {
        sv.log.exception(e, "Unable to install/update the SciViews-K toolbox");
    }
	finally { sv.showVersion = true; }
}

// Ensure we check the toolbox is installed once the extension is loaded
//addEventListener("load", function() {setTimeout (sv.checkToolbox, 5000) }, false);
//addEventListener("load", sv.checkToolbox, false);
// SciViews-K general functions
// Define the basic 'sv' namespace, plus 'sv.cmdout', 'sv.log' & 'sv.prefs'
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.version; // Get current SciViews-K version (major.minor.release)
// sv.showVersion; // Do we display version in an alert() box or just set it?
// sv.checkVersion(version); // Check the SciViews-K extension version is fine
//
// Various functions defined in the 'sv' namespace directly
// sv.alert(header, text); // Own alert box; text is optional
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

////////////////////////////////////////////////////////////////////////////////



if (typeof(sv) == 'undefined') sv = {};

// Create the 'sv.tools' namespace
if (typeof(sv.tools) == 'undefined') sv.tools = {};

// IMPORTANT: now sv.version is a "X.X.X" string, and sv.checkVersion accepts only such format
// please update all macros using sv.checkVersion 
sv.version = Components.classes["@mozilla.org/extensions/manager;1"]
				.getService(Components.interfaces.nsIExtensionManager)
				.getItemForID("sciviewsk@sciviews.org").version;
sv.showVersion = true;

sv._compareVersion = function (a, b) {
    if (!a)	return -1;
    if (!b)	return 1;

	// try is necessary only till I find where is that damn macro causing an error
	// at startup (-;
	try {
		a = a.split(/[.\-]/);
		for (i in a) a[i] = parseInt(a[i]);
		b = b.split(/[.\-]/);
		for (i in b) b[i] = parseInt(b[i]);

		for (k in a) {
			if (k < b.length) {
				if (a[k] > b[k])
					return 1;
				else if (a[k] < b[k])
					return -1;
			} else {
				return 1;
			}
		}
	   return (b.length > a.length)? -1 : 0;
	} catch(e) {
		return 1;
	}
}

sv.checkVersion = function (version) {
	if (sv._compareVersion(sv.version, version) < 0) {
		var text = sv.translate(
"One or more macros require the SciViews-K plugin %S, " +
"but currently installed version is %S. You should update it." +
"Would you like to open the extension manager and check for updates now?",
version, this.version);

		var sYes = sv.translate("Yes");
		var res = ko.dialogs.yesNo(sv.translate("Outdated SciViews-K extension"),
			sYes, text, "SciViews-K");
		if (res == sYes) 	ko.launch.openAddonsMgr();
		return(false);
	} else
		return(true);
}


//// Other functions directly defined in the 'sv' namespace ////////////////////
// Our own alert box
sv.alert = function (header, text) {
    ko.dialogs.alert(header, text, "SciViews-K");
}
//sv.alert("Error:", "Some message");
// -or-
//sv.alert("Message");

// Gets current selection, or word under the cursor in the active buffer
//DEPRECATED, use sv.getTextRange
sv.getText = function (includeChars) sv.getTextRange("word", false, false, null, includeChars);

// Select a part of text in the current buffer and return it
// differs from sv.getPart that it does not touch the selection
sv.getTextRange = function (what, gotoend, select, range, includeChars) {

	var currentView = ko.views.manager.currentView;
	if (!currentView) {
		return "";
	}

	currentView.setFocus();
	var scimoz = currentView.scimoz;

	var text = "";
	var curPos = scimoz.currentPos;
	var curLine = scimoz.lineFromPosition(curPos);

	var pStart = Math.min (scimoz.anchor, curPos);
	var pEnd = Math.max (scimoz.anchor, curPos);

	// Depending on 'what', we select different parts of the file
	// By default, we keep current selection

	if (what == "line/sel")
		what = (pStart == pEnd)? "line" : "sel";

	switch(what) {
	case "sel":
	   // Simply retain current selection
	   break;
	case "word":
	   if (pStart == pEnd) { // only return word if no selection
			if (!includeChars && currentView.languageObj.name == "R")
				includeChars = ".";

			var wordChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" + includeChars;

			function wordCharTest(s) {
				return (s.charCodeAt(0) > 0x80) ||
					wordChars.indexOf(s) > -1;
			}


			for (pStart = scimoz.positionBefore(curPos);
				 (pStart > 0) && wordCharTest(scimoz.getWCharAt(pStart));
				 pStart = scimoz.positionBefore(pStart)) {
				};

			// PhG: correction for infinite loop if the name is at the beginning
			// of the document
			if (pStart != 0 | !wordCharTest(scimoz.getWCharAt(0))) {
				pStart += 1;
			}

			for (pEnd = scimoz.currentPos;
				 (pEnd < scimoz.length) && wordCharTest(scimoz.getWCharAt(pEnd));
				 pEnd = scimoz.positionAfter(pEnd)) {
			}

			// TODO: this should be set for every R document by default. but how?
			//if (includeChars) {
			//	var wordChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" + includeChars;
			//	scimoz.setWordChars(wordChars);
			//}
			//pStart = scimoz.wordStartPosition(curPos, true);
			//pEnd = scimoz.wordEndPosition(curPos, true);
	   }
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
		var pos0 = scimoz.getLineEndPosition(curLine);
		var findRes;

		do {
			//  search for function pattern backwards:
			findSvc.options.searchBackward = true;
			findRes = findSvc.find("", // view.document.displayPath
									scimoz.text, funcRegExStr,
									scimoz.charPosAtPosition(pos0), 0); //start, end
			if (!findRes) break;

			// function declaration start:
			pos0 = scimoz.positionAtChar(0, findRes.start);
			// opening brace of function declaration
			pos1 = scimoz.positionAtChar(0, findRes.end);
			// closing brace of function declaration
			pos2 = scimoz.braceMatch(pos1 - 1) + 1;

			// find first character following the closing brace
			findSvc.options.searchBackward = false;
			findRes = findSvc.find("",  //view.document.displayPath
									scimoz.text, "\\S",
									scimoz.charPosAtPosition(pos2) + 1,
									scimoz.charPosAtPosition(scimoz.length));
			if (!findRes) break;

			//  beginning of the function body:
			pos3 = scimoz.positionAtChar(0, findRes.end);

			lineArgsStart = scimoz.lineFromPosition(pos1);
			lineBodyStart = scimoz.lineFromPosition(pos3);

			// get first line of the folding block:
			firstLine = (scimoz.getFoldParent(lineBodyStart) != lineArgsStart)?
				lineBodyStart : lineArgsStart;

			// get end of the function body
			if (scimoz.getWCharAt(pos3 - 1) == "{") {
				pos4 = scimoz.braceMatch(pos3 - 1) + 1;
			} else {
				pos4 = scimoz.getLineEndPosition(lineBodyStart);
			}

		// repeat if selected function does not embrace cursor position and if
		// there are possibly any functions enclosing it:
		} while (pos4 < curPos && scimoz.getFoldParent(lineArgsStart) != -1);

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
		Mark1 = scimoz.markerPrevious(curLine, 64);
		if (Mark1 == -1)	Mark1 = 0;
		Mark2 = scimoz.markerNext(curLine, 64);
		if (Mark2 == -1)	Mark2 = scimoz.lineCount - 1;

		pStart = scimoz.positionFromLine(Mark1);
		pEnd = scimoz.getLineEndPosition(Mark2);

	   break;
	case "para":
	   // Select the entire paragraph
	   // go up from curLine until
	   for (var i = curLine; i >= 0
			&& scimoz.lineLength(i) > 0
			&& scimoz.getTextRange(
			   pStart = scimoz.positionFromLine(i),
			   scimoz.getLineEndPosition(i)).trim() != "";
			i--) {		}

	   for (var i = curLine; i <= scimoz.lineCount
			&& scimoz.lineLength(i) > 0
			&& scimoz.getTextRange(scimoz.positionFromLine(i),
			   pEnd = scimoz.getLineEndPosition(i)).trim() != "";
			i++) {		}

	   break;
	case "line":
		 // Select whole current line
		pStart = scimoz.positionFromLine(curLine);
		pEnd = scimoz.getLineEndPosition(curLine);
	   break;
	case "linetobegin":
	   // Select line content from beginning to anchor
	   pStart = scimoz.positionFromLine(curLine);
	   break;
	case "linetoend":
	   // Select line from anchor to end of line
	   pEnd = scimoz.getLineEndPosition(curLine);
	   break;
	case "end":
	   // take text from current line to the end
	   pStart = scimoz.positionFromLine(curLine);
	   pEnd = scimoz.textLength;
	   break;
    case "codefrag":
        // This is used by calltip and completion. Returns all text backwards from current
		// position to the beginning of the current folding level
        pStart = scimoz.positionFromLine(scimoz.getFoldParent(curLine));
	case "all":
	default:
	   // Take everything
	   text = scimoz.text;
	}

	if (what != "all") {
		text = scimoz.getTextRange(pStart, pEnd).replace(/(^[\n\r]+|[\n\r]+$)/, "");
		if (gotoend) {
			scimoz.gotoPos(pEnd);
		}
		if (select) {
			scimoz.setSel(pStart, pEnd);
		}
	}
	if ((typeof range == "object") && (range != null)) {
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

// Get some help for a snippet, or a word in the buffer by hitting Shift+F1
sv.helpContext = function () {
	try {
		if (ko.window.focusedView() == null) {
			if (ko.projects.active) {
				var item = ko.projects.active.getSelectedItem();
				var content = item.value;
				// We need to eliminate newlines for easier regexp search
				content = content.replace(/[\n\r]/g, '\t');

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
			topic = sv.getTextRange("word");
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
// Display message on the status bar (default) or command output bar
sv.cmdout.message = function (msg, timeout, highlight, outputBar) {
	if (outputBar) {
		document.getElementById('output_tabpanels').selectedIndex = 0;
		var runoutputDesc = document.getElementById('runoutput-desc');
		if (msg == null) msg = "";

		runoutputDesc.parentNode.style.backgroundColor =
			(highlight && msg) ? "highlight" : "";

		runoutputDesc.style.color = "rgb(0, 0, 0)";
		runoutputDesc.setAttribute("value", msg);
		window.clearTimeout(runoutputDesc.timeout);
		if (timeout > 0)
			runoutputDesc.timeout = window.setTimeout("sv.cmdout.message('', 0, null, true);",
				timeout);
	} else {
		ko.statusBar.AddMessage(msg, "SciViews-K info", timeout, highlight);
	}
}


//// Logging management ////////////////////////////////////////////////////////
if (typeof(sv.log) == 'undefined')
	sv.log = {};


//const LOG_NOTSET = 0;	//const LOG_DEBUG = 10;	//const LOG_INFO = 20;
//const LOG_WARN = 30; 	//const LOG_ERROR = 40;	//const LOG_CRITICAL = 50;
// ko.logging.LOG_*

(function () {
	var logger = ko.logging.getLogger("SciViews-K");

	this.exception = function (e, msg, showMsg) {
		if (typeof(showMsg) != 'undefined' && showMsg == true) {
			sv.alert("Error", msg);
		}
		logger.exception(e, msg);
	}

	this.critical = function (msg) {
		logger.critical(msg);
	}

	this.error = function (msg) {
		logger.error(msg);
	}

	this.warn = function (msg) {
		logger.warn(msg);
	}

	this.warnStack = function (msg) {
		logger.deprecated(msg);
	}

	this.info = function (msg) {
		logger.info(msg);
	}

	this.debug = function (msg) {
		logger.debug(msg);
	}

	this.all = function (debug) {
		logger.setLevel(!!debug);
	}

	this.isAll = function () {
		return(logger.getEffectiveLevel() == 1);
	}

	this.show = function () {
		try {
			var logFile = sv.tools.file.path("ProfD", ["..", "pystderr.log"]);
			var winOpts = "centerscreen,chrome,resizable,scrollbars,dialog=no,close";
			window.openDialog('chrome://komodo/content/tail/tail.xul',"_blank",
				winOpts,logFile);
		} catch(e) {
			this.exception(e, "Unable to display the Komodo error log!", true);
		}
	}

}).apply(sv.log);




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
// Note: this is bit dangerous in its present form, removes current SciViews-K toolbox
// without notice, all modifications are lost.
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

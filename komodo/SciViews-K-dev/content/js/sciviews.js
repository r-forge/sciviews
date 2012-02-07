// SciViews-K general functions
// Define the basic 'sv' namespace, plus 'sv.cmdout', 'sv.log' & 'sv.prefs'
// Copyright (c) 2008-2010, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// _(); // A fake function used only to tag strings to be translated in projects
//         and toolbox macros
//
// sv.version; // Get current SciViews-K version (major.minor.release)
// sv.showVersion; // Do we display version in an alert() box or just set it?
// sv.checkVersion(version); // Check the SciViews-K extension version is fine
//
// Various functions defined in the 'sv' namespace directly
// sv.alert(header, text); // Own alert box; text is optional
// sv.getTextRange(what, gotoend, select);  // Get a part of text in the buffer,
// but do not operate on selection
// sv.marginClick(modifiers, position, margin);  // Custom margin click behaviour
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
// sv.cmdout.clear();						 // Clear the Command Output pane
// sv.cmdout.message(msg, timeout, highlight);	 // Message in Command Output
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

/*
FIXME: A loose list:
Key conflicts in toolbox: (to be removed/changed to unused combinations in SciViews toolbox)
*Run function (Ctrl+Shift+F) conflicts with "Find in Files..."
*Run paragraph (Ctrl+Shift+H) <--> "Replace in Files..."
*Run line and hit enter (Ctrl+Return) <--> "Insert Newline (no favors)"
*Working dir (current file): F7 <--> "Run marked block"
*In toolbox: Ctrl+Shift+M (toolbox) and F7 (menu) both defined for "Run marked block"
*Object structure (Ctrl+Shift+T) <--> Reopen the Last Closed Tab
*Session in my documents... (Ctrl+Shift+S) <--> Save As... (This one is quite important!)

*/

////////////////////////////////////////////////////////////////////////////////


// This function is used to tag strings to be translated in projects/toolbox
var _ = function(str) { return(str) }

if (typeof(sv) == "undefined") var sv = {};

// Create the 'sv.tools' namespace
if (typeof(sv.tools) == "undefined") sv.tools = {};

//sv._version
/*= (function() {
	var koVersion = Components.classes["@activestate.com/koInfoService;1"]
		.getService(Components.interfaces.koIInfoService).version;
	if(koVersion)
})();*/

try { // Komodo 7
	Components.utils.import("resource://gre/modules/AddonManager.jsm");
	AddonManager.getAddonByID("sciviewsk@sciviews.org", function(addon) {
		sv._version = addon.version; });
} catch(e) {
	sv._version = Components.classes["@mozilla.org/extensions/manager;1"]
	.getService(Components.interfaces.nsIExtensionManager)
	.getItemForID("sciviewsk@sciviews.org").version;
}
sv.__defineGetter__("version", function() sv._version);

// IMPORTANT: now sv.version is a "X.X.X" string, and sv.checkVersion accepts only such format
// please update all macros using sv.checkVersion
sv.showVersion = true;

sv._compareVersions = function(a, b) Components
	.classes["@mozilla.org/xpcom/version-comparator;1"]
	.getService(Components.interfaces.nsIVersionComparator).compare(a, b);

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
		if (res == sYes) ko.launch.openAddonsMgr();
		return(false);
	} else {
		return(true);
	}
}

//// Other functions directly defined in the 'sv' namespace ////////////////////
// Our own alert box
sv.alert = function (header, text) ko.dialogs.alert(header, text, "SciViews-K");

//sv.alert("Error:", "Some message");
// -or-
//sv.alert("Message");

// Gets current selection, or word under the cursor in the active buffer
//DEPRECATED, use sv.getTextRange
sv.getText = function (includeChars) {
	throw("sv.getText is DEPRECATED, use sv.getTextRange");
	sv.getTextRange("word", false, false, null, includeChars);
}

// Select a part of text in the current buffer and return it
// differs from sv.getPart that it does not touch the selection
sv.getTextRange = function (what, gotoend, select, range, includeChars) {

	var currentView = ko.views.manager.currentView;
	if (!currentView) return("");
	currentView.setFocus();
	var scimoz = currentView.scimoz;
	var text = "";
	var curPos = scimoz.currentPos;
	var curLine = scimoz.lineFromPosition(curPos);

	var pStart = Math.min (scimoz.anchor, curPos);
	var pEnd = Math.max (scimoz.anchor, curPos);

	// Depending on 'what', we select different parts of the file
	// By default, we keep current selection

	if (what == "line/sel") what = (pStart == pEnd) ? "line" : "sel";

	switch(what) {
	 case "sel":
		// Simply retain current selection
		var nSelections = scimoz.selections;
		if(nSelections > 1) { // rectangular selection
			var msel = [];
			for (var i = 0; i < scimoz.selections; i++) {
				msel.push(scimoz.getTextRange(scimoz.getSelectionNStart(i), scimoz.getSelectionNEnd(i)));
			}
			text = msel.join("\n");
			// TODO: What to do with multiple ranges?
			pStart = scimoz.getSelectionNStart(0);
			pEnd = scimoz.getSelectionNEnd(nSelections - 1);
		}
		break;
	 case "word":
		if (pStart == pEnd) { // only return word if no selection
			if (!includeChars && currentView.languageObj.name == "R")
			includeChars = ".";

			var wordChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" + includeChars;

			function wordCharTest(s) {
				return((s.charCodeAt(0) > 0x80) || wordChars.indexOf(s) > -1);
			}

			for (pStart = scimoz.positionBefore(curPos);
				 (pStart > 0) && wordCharTest(scimoz.getWCharAt(pStart));
			pStart = scimoz.positionBefore(pStart)) {
			};

			// PhG: correction for infinite loop if the name is at the beginning
			// of the document
			if (pStart != 0 | !wordCharTest(scimoz.getWCharAt(0))) pStart += 1;

			for (pEnd = scimoz.currentPos;
				 (pEnd < scimoz.length) && wordCharTest(scimoz.getWCharAt(pEnd));
			pEnd = scimoz.positionAfter(pEnd)) {
			}
		}
		break;
	 case "function":
		// tricky one: select an entire R function
		// this should work even with extremely messy coded ones.

		// function declaration pattern:
		var funcRegExStr = "\\S+\\s*(<-|=)\\s*function\\s*\\(";
		//var funcRegExStr = "\\b(([`'\\\"])(.+)\\2|([\w\u0100-\uFFFF\\.]+))\\s*(<-|=)\\s*function\\s*\\(";


		var findSvc = Components.classes['@activestate.com/koFindService;1']
			.getService(Components.interfaces.koIFindService);

		// save previous find settings
		var oldFindPref = {searchBackward: true, matchWord: false,
            patternType: 0};
		for (var i in oldFindPref)
			oldFindPref[i] = findSvc.options[i];

		findSvc.options.matchWord = false;
		findSvc.options.patternType = 2;

		var line0, line1, pos1, pos2, pos3, pos4;
		var lineArgsStart, lineBodyStart, firstLine; //lineArgsEnd lineBodyEnd,
		var pos0 = scimoz.getLineEndPosition(curLine);
		var findRes;

		do {
			//  search for function pattern backwards:
			findSvc.options.searchBackward = true;
			findRes = findSvc.find("", // view.koDoc.displayPath
				scimoz.text, funcRegExStr,
				scimoz.charPosAtPosition(pos0), 0); //start, end
			if (!findRes) break;

			// function declaration start:
			pos0 = scimoz.positionAtChar(0, findRes.start);
			// opening brace of function declaration
			pos1 = scimoz.positionAtChar(0, findRes.end);
			// closing brace of function declaration
			pos2 = scimoz.braceMatch(pos1 - 1); //+ 1;

			// find first character following the closing brace
			findSvc.options.searchBackward = false;
			findRes = findSvc.find("",  //view.koDoc.displayPath
			scimoz.text, "\\S",
			scimoz.charPosAtPosition(pos2) + 1,
			scimoz.charPosAtPosition(scimoz.length));
			if (!findRes) break;

			//  beginning of the function body:
			pos3 = scimoz.positionAtChar(0, findRes.end);

			lineArgsStart = scimoz.lineFromPosition(pos1);
			lineBodyStart = scimoz.lineFromPosition(pos3);

			// get first line of the folding block:
			firstLine = (scimoz.getFoldParent(lineBodyStart) !=
				lineArgsStart) ? lineBodyStart : lineArgsStart;

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
		for (var i in oldFindPref)	findSvc.options[i] = oldFindPref[i];

		break;
	 case "block":
		// Select all content between two bookmarks
		var Mark1, Mark2;
		Mark1 = scimoz.markerPrevious(curLine, 64);
		if (Mark1 == -1) Mark1 = 0;
		Mark2 = scimoz.markerNext(curLine, 64);
		if (Mark2 == -1) Mark2 = scimoz.lineCount - 1;

		pStart = scimoz.positionFromLine(Mark1);
		pEnd = scimoz.getLineEndPosition(Mark2);

		break;
	 case "para":
		// Select the entire paragraph
		// go up from curLine until
		for (var i = curLine; i >= 0
			&& scimoz.lineLength(i) > 0
			&& scimoz.getTextRange(pStart = scimoz.positionFromLine(i),
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

	if (!text) text = scimoz.getTextRange(pStart, pEnd);

	if (gotoend) scimoz.gotoPos(pEnd);
	if (select && what !="sel") scimoz.setSel(pStart, pEnd);


	if (range != undefined && (typeof range == "object")) {
		range.value = {start: pStart, end: pEnd};
	}
	return(text);
}

// Custom margin click behaviour
sv.marginClick = function (modifiers, position, margin) {
    //sv.log.info("Bookmark click");
    try {
        var v = ko.views.manager.currentView;
        // There is a problem with split pane and an error message when currentView is null
        // The following line was added, but it does not seem to solve the problem
        if (!v) return;
        var ke = v.scintilla.scimoz;
        //var ke = v.scimoz;
        var lineClicked = ke.lineFromPosition(position);
        if (margin == 2) {
            if (modifiers == 0) {
                // Simple click
                // From editor.js. This is implementation of do_cmd_bookmarkToggle with
                // different arguments
                var markerState = ke.markerGet(lineClicked);

                if (markerState & (1 << ko.markers.MARKNUM_BOOKMARK)) {
                    ke.markerDelete(lineClicked, ko.markers.MARKNUM_BOOKMARK);
                } else {
                    ko.history.note_curr_loc(v);
                    ke.markerAdd(lineClicked, ko.markers.MARKNUM_BOOKMARK);
                    //ke.markerAdd(lineClicked, ko.markers.MARKNUM_STDIN_PROMPT);
                }
            } else if (modifiers == 1) {
                // Shift click
                var markerState = ke.markerGet(lineClicked);

                if (markerState & (1 << ko.markers.MARKNUM_TRANSIENTMARK)) {
                    ke.markerDelete(lineClicked, ko.markers.MARKNUM_TRANSIENTMARK);
                } else {
                    ke.markerAdd(lineClicked, ko.markers.MARKNUM_TRANSIENTMARK);
                    //ke.markerAdd(lineClicked, ko.markers.MARKNUM_STDIN_PROMPT);
                }

            }
        } else if (margin == 1) {
            // From views-buffer.xml, method onMarginClick (original comments removed)
            if (ke.getFoldLevel(lineClicked) & ke.SC_FOLDLEVELHEADERFLAG) {
                if (ke.getFoldExpanded(lineClicked)) {
                    var level = ke.getFoldLevel(lineClicked);
                    var lineMaxSubord = ke.getLastChild(lineClicked, level);
                    var currentLine = ke.lineFromPosition(ke.currentPos);
                    if (currentLine > lineClicked && currentLine <= lineMaxSubord) {
                        var pos = ke.positionFromLine(lineClicked);
                        ke.selectionStart = pos;
                        ke.selectionEnd = pos;
                        ke.currentPos = pos;
                    }
                }
                ke.toggleFold(lineClicked);
            }
        }
    } catch(e) {};
}

// file open dialog, more customizable replacement for ko.filepicker.open
sv.fileOpen = function (directory, filename, title, filter, multiple, save,
filterIndex) {
	const nsIFilePicker = Components.interfaces.nsIFilePicker;
    var fp = Components.classes["@mozilla.org/filepicker;1"]
		.createInstance(nsIFilePicker);

	//Dialog should get default system title
    //if (!title) title = sv.translate(save? "Save file" : "Open file");

	var mode;
	if (!save) {
		mode = multiple ? nsIFilePicker.modeOpenMultiple : nsIFilePicker.modeOpen;
	} else {
		mode = nsIFilePicker.modeSave;
	}

    fp.init(window, title, mode);

	if (typeof(filterIndex) != "undefined")
		fp.filterIndex = (typeof(filterIndex) == "object") ?
		filterIndex.value : filterIndex;

	var filters = [];

	if (filter) {
        if (typeof(filter) == "string") filter = filter.split(',');
        var fi;
        for (var i = 0; i  < filter.length; i++) {
            fi = filter[i].split("|");
            if (fi.length == 1)
			fi[1] = fi[0];
            fp.appendFilter(fi[0], fi[1]);
			filters.push(fi[1]);
        }
    }
    fp.appendFilters(nsIFilePicker.filterAll);
	filters.push("");

    if (directory) {
        var lf = Components.classes["@mozilla.org/file/local;1"]
			.createInstance(Components.interfaces.nsILocalFile);
        lf.initWithPath(directory);
        fp.displayDirectory = lf;
    }
    if (filename) fp.defaultString = filename;

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

		// append extension according to active filter
		if (mode == nsIFilePicker.modeSave) {
			var os = Components.classes['@activestate.com/koOs;1']
				.getService(Components.interfaces.koIOs);
			if (!os.path.getExtension(path)) {
				var defaultExt = os.path.getExtension(filters[fp.filterIndex]);
				path += defaultExt;
			}
		}
		if (typeof filterIndex == "object") filterIndex.value = fp.filterIndex;
        return(path);
    }
    return(null);
}

// Browse for the URI, either in an internal, or external (default) browser
sv.browseURI = function (URI, internal) {
	if (URI == "") {
		sv.alert(sv.translate("Item not found!"));	// Because we call this from
        // other functions that return "" when they don't find it, see sv.r.help
	} else {
		if (internal == null)
			internal = (sv.pref.getPref("sciviews.r.help",
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

// Get some help for a snippet, or a word in the buffer by hitting Alt+F1
sv.helpContext = function () {
	try {
		if (ko.window.focusedView() == null) {
			if (ko.projects.active) {
				var item;
				if (ko.toolbox2 === undefined) {
					// Komodo 5 code
					item = ko.projects.active.getSelectedItem();
				} else {
					// Komodo 6 code
					item = ko.toolbox2.getSelectedItem();
				}
				var content = item.value;
				// We need to eliminate newlines for easier regexp search
				content = content.replace(/[\n\r]/g, "\t");

				// Look for a string defining the URL for associated help file
				// This is something like: [[%ask|pref:URL|R|RWiki-help:<value>]]

				// To ease search, replace all [[%ask by [[%pref
				content = content.replace(/\[\[%ask:/g, "[[%pref:");

				// Look for URL-help
				var help = content.replace(/^.*\[\[%pref:URL-help:([^\]]*)]].*$/,
					"$1");
				if (help != content) {	// Found!
					// Show in default browser
					// TODO: a quick 'R help' tab to show this
					ko.browse.openUrlInDefaultBrowser(help);
					return(true);
				}

				// Look for R-help
				help = content.replace(/^.*\[\[%pref:R-help:([^\]]*)]].*$/, "$1");
				if (help != content) {	// Found!
					// Do the help command in R
					sv.r.help(help);
					return(true);
				}

				// Look for RWiki-help
				help = content.replace(/^.*\[\[%pref:RWiki-help:([^\]]*)]].*$/, "$1");
				if (help != content) {	// Found!
					// Get the RWiki base URL
					var baseURL = "http:/wiki.r-project.org/rwiki/doku.php?id="
					baseURL = sv.pref.getPref("sciviews.rwiki.help.base",
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
			//return(strbundle.getFormattedString(textId, param));
			return(bundle.formatStringFromName(textId, param, param.length));

		} else {
			//return(strbundle.getString(textId));
			return(bundle.GetStringFromName(textId));
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
		return(textId);
	}
}

//// Control the command output tab ////////////////////////////////////////////
if (typeof(sv.cmdout) == 'undefined') sv.cmdout = {};

// Append text to the Command Output pane
// TODO: handle \b correctly to delete char up to the beginning of line
// TODO: what to do with \a? I already have a bell in R console...

sv.cmdout = {};
(function() {

var _this = this;

this.__defineGetter__('eolChar', function()
	["\r\n", "\n", "\r"][_this.scimoz.eOLMode]);

this.__defineGetter__('scimoz', function() {
	if(window.frames["runoutput-desc-tabpanel"]) // Komodo 7
		return window.frames["runoutput-desc-tabpanel"]
			.document.getElementById("runoutput-scintilla").scimoz;
	else
		return document.getElementById("runoutput-scintilla").scimoz;
});


function _rgb(r, g, b) {
	if (arguments.length == 3) color = arguments;
	else color = r;
	return color[0] | (color[1] << 8) | (color[2] << 16);
}

function _hexstr2rgb(hex) {
	var colorref = parseInt(hex.substr(1), 16);
	return _rgb(colorref >> 16 & 255, colorref >> 8 & 255, colorref & 255);
}

var styleNumCode = 22, styleNumResult = 0, styleNumErr = 23;

var initialized = false; ///
function _init() {
	var scimoz = _this.scimoz;

	//var colorForeCode =_rgb(80, 100, 255);
	//var colorForeErr = _rgb(255, 50, 50);
	var colorForeErr, colorForeCode, colorForeResult;

	//Get color from the color scheme: stdin, stdout, stderr
	//var schemeName = sv.pref.getPref('editor-scheme');
	// sv.pref may be not loaded yet
	var prefset = Components.classes["@activestate.com/koPrefService;1"]
		.getService(Components.interfaces.koIPrefService).prefs;
	var schemeName = prefset.getStringPref('editor-scheme');
	var currentScheme = Components.classes['@activestate.com/koScintillaSchemeService;1']
		.getService().getScheme(schemeName);

	//TODO: comment styling

	colorForeCode = _hexstr2rgb(currentScheme.getFore('', 'stdin'));
	colorForeResult = _hexstr2rgb(currentScheme.getFore('', 'stdout'));
	colorForeErr = _hexstr2rgb(currentScheme.getFore('', 'stderr'));

    scimoz.styleSetFore(styleNumCode, colorForeCode);
    scimoz.styleSetFore(styleNumErr, colorForeErr);
	scimoz.styleSetFore(styleNumResult, colorForeResult);

    //scimoz.styleSetBold(styleNumCode, true);
    //scimoz.styleSetBold(styleNumResult, false);
}

var observerSvc = Components.classes["@mozilla.org/observer-service;1"]
    .getService(Components.interfaces.nsIObserverService);

observerSvc.addObserver({ observe: _init }, 'scheme-changed', false);

this.print = function (str) {
	_this.clear();
	_this.append(str, true, false);
}

function fixEOL(str) str.replace(/(\r?\n|\r)/g, _this.eolChar);

this.print2 = function (command, result, done) {
	var scimoz = _this.scimoz;
	var eolChar = _this.eolChar;

	command = fixEOL(command);
	result = fixEOL(result);

	scimoz.readOnly = false;
	if (!done) {
		_this.clear();
		command = command.replace(/^ {3}(?= *\S)/gm, ":+ "); // + eolChar;
		result += eolChar;
		scimoz.appendText(ko.stringutils.bytelength(command), command);
		//scimoz.text += command;
		this.styleLines(0, scimoz.lineCount, styleNumCode);
		scimoz.appendText(ko.stringutils.bytelength(result), result);
		//scimoz.text += result;
		//alert(scimoz.lineCount);

	} else {
		var lineNum = scimoz.lineCount - 2;
		if(this.getLine(lineNum) == '...' + eolChar) {
			scimoz.targetStart = scimoz.positionFromLine(lineNum);
			scimoz.targetEnd = scimoz.getLineEndPosition(lineNum);
			scimoz.replaceTarget(result.length, result);
			var lineCount = scimoz.lineCount;
			this.styleLines(lineNum, lineCount - 2);
			this.styleLines(lineCount - 2, lineCount - 1, styleNumCode);
		}
	}
	var firstVisibleLine = Math.max(scimoz.lineCount - scimoz.linesOnScreen - 1, 0);
	scimoz.firstVisibleLine = firstVisibleLine;
}

this.replaceLine = function(lineNum, text, eol) {
	var scimoz = _this.scimoz;
	var eolChar = _this.eolChar;

	scimoz.targetStart = scimoz.positionFromLine(lineNum);
	scimoz.targetEnd = scimoz.getLineEndPosition(lineNum) +
		(eol? eolChar.length : 0);
	scimoz.replaceTarget(text.length, text);
}

this.append = function (str, newline, scrollToStart) {
	var scimoz = _this.scimoz;
	var eolChar = _this.eolChar;

	if (scrollToStart === undefined) scrollToStart = false;

	try {
		ko.run.output.show();
	} catch(e) { // Komodo 6
		ko.uilayout.ensureOutputPaneShown();
		ko.uilayout.ensureTabShown("runoutput_tab", false);

	}

	str = fixEOL(str);

	var lineCountBefore = scimoz.lineCount;

	if (newline || newline === undefined) str += eolChar;
	var readOnly = scimoz.readOnly;
	try {
		scimoz.readOnly = false;
		scimoz.appendText(ko.stringutils.bytelength(str), str);
	} catch(e) {
		alert(e);
	} finally {
		scimoz.readOnly = readOnly;
	}

	var firstVisibleLine;
	if (!scrollToStart) {
		firstVisibleLine = Math.max(scimoz.lineCount - scimoz.linesOnScreen, 0);
	} else {
		firstVisibleLine = Math.min(lineCountBefore - 1, scimoz.lineCount - scimoz.linesOnScreen);
	}
	scimoz.firstVisibleLine = firstVisibleLine;

}


this.getLine = function(lineNumber) {
	var scimoz = _this.scimoz;
	var lineCount = scimoz.lineCount;
	if (lineNumber === undefined) lineNumber = lineCount - 1;
	while (lineNumber < 0) lineNumber = lineCount + lineNumber;
	var oLine = {};
	//return lineNumber;
	scimoz.getLine(lineNumber, oLine);
	return oLine.value;
}

//var re = /[\x02\x03]/;
//var str0 = res, newStr = "";
//var pos = [], pos0;
//while(1){
//	pos0 = str0.search(re);
//	if (pos0 == -1) break;
//	pos.push(pos0 + newStr.length);
//	newStr += RegExp.leftContext;
//	str0 = RegExp.rightContext;
//}
//newStr += str0;

this.styleLines = function(startLine, endLine, styleNum) {
	_init();
	var scimoz = _this.scimoz;
	var eolChar = _this.eolChar;

	if (startLine == undefined) startLine = 0;
	if (endLine == undefined) endLine = scimoz.lineCount;
	var styleMask = (1 << scimoz.styleBits) - 1;
	var readOnly = scimoz.readOnly;
	scimoz.readOnly = false;

	if(styleNum == undefined) {
	// a simple lexer...
		var codeRx = /^:[>\+]\s/;
		var curStyle, txt, inStdErr = false;

		for (var line = startLine; line < endLine; line++) {
			//TODO: optimize this !!!
			txt = this.getLine(line);
			curStyle = (codeRx.test(txt))? styleNumCode : styleNumResult;
			if(curStyle == styleNumResult) {
				if(inStdErr) curStyle = styleNumErr;
				if(!inStdErr && /\x03/.test(txt)) { // {ETX}
					curStyle = styleNumErr;
					inStdErr = true;
				} else if (inStdErr && /\x02/.test(txt))  {// {STX}
					curStyle = styleNumResult;
					inStdErr = false;
				}
				this.replaceLine(line, txt.replace(/[\x02\x03]/g, ''), true);
			}
			startPos = scimoz.positionFromLine(line);
			endPos = scimoz.getLineEndPosition(line) + eolChar.length +  10;
			scimoz.startStyling(startPos, styleMask);
			scimoz.setStyling(endPos - startPos, curStyle);
		}
	} else {
		// all lines in the provided style
		startPos = scimoz.positionFromLine(startLine);
		endPos = scimoz.getLineEndPosition(endLine-1) + eolChar.length;
		scimoz.startStyling(startPos, styleMask);
		scimoz.setStyling(endPos - startPos, styleNum);
	}
	scimoz.readOnly = readOnly;
}

// Clear text in the Output Command pane
this.clear = function (all) {
	var scimoz = _this.scimoz;

	if (all) _this.message();
	var readOnly = scimoz.readOnly;
	try {
		scimoz.readOnly = false;
		scimoz.clearAll();
	} finally {
		scimoz.readOnly = readOnly;
	}

}
// Display message on the status bar (default) or command output bar
this.message = function (msg, timeout, highlight) {
	try {
		ko.run.output.show();
	} catch(e) { // Komodo 6
		ko.uilayout.ensureOutputPaneShown();
		ko.uilayout.ensureTabShown("runoutput_tab", false);

	}

	var win = (window.frames["runoutput-desc-tabpanel"])?
		window.frames["runoutput-desc-tabpanel"] : window;
	var runoutputDesc = win.document.getElementById('runoutput-desc');
	if (msg == null) msg = "";
	runoutputDesc.parentNode.style.backgroundColor =
		(highlight && msg) ? "highlight" : "";
	runoutputDesc.style.color = "rgb(0, 0, 0)";
	runoutputDesc.setAttribute("value", msg);
	window.clearTimeout(runoutputDesc.timeout);
	if (timeout > 0) runoutputDesc.timeout = window
		.setTimeout("sv.cmdout.message('', 0);", timeout);
}


}).apply(sv.cmdout);




//// Logging management ////////////////////////////////////////////////////////
if (typeof(sv.log) == 'undefined') sv.log = {};

//const LOG_NOTSET = 0;	//const LOG_DEBUG = 10;	//const LOG_INFO = 20;
//const LOG_WARN = 30; 	//const LOG_ERROR = 40;	//const LOG_CRITICAL = 50;
// ko.logging.LOG_*

(function () {
	var logger = ko.logging.getLogger("SciViews-K");

	this.exception = function (e, msg, showMsg) {
		if (typeof(showMsg) != 'undefined' && showMsg == true)
			sv.alert("Error", msg);
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
		if (logger.getEffectiveLevel() == 1) {
			ko.statusBar.AddMessage("SciViews error logging set to debug level",
				"svLog", 3000, true);
		} else {
			ko.statusBar.AddMessage("SciViews error logging set to level " +
				logger.getEffectiveLevel(), "svLog", 3000, true);
		}
	}

	this.isAll = function () {
		return(logger.getEffectiveLevel() == 1);
	}

	this.show = function () {
		var os = Components.classes['@activestate.com/koOs;1']
			.getService(Components.interfaces.koIOs);
		try {
			// Note that in Komodo 6, interpolateStrings is deprecated in favor of interpolateString!
			var appdir = ko.interpolate.interpolateStrings('%(path:userDataDir)');
			var logFile = os.path.join(appdir,'pystderr.log');
			var winOpts = "centerscreen,chrome,resizable,scrollbars,dialog=no,close";
			window.openDialog('chrome://komodo/content/tail/tail.xul',
				"_blank",winOpts,logFile);
		} catch(e) {
			this.exception(e,
				"Unable to display the Komodo error log (" + e + ")", true);
		}
	}

}).apply(sv.log);


sv.log.all(true);

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

// Installs toolboxes
sv.checkToolbox = function () {

	var svFile = sv.tools.file;

	// If Komodo 6, and new-style, zipped toolbox is present, redirect to sv.checkToolbox2
	if(ko.toolbox2 &&
	   svFile.getfile("ProfD", "extensions/sciviewsk@sciviews.org/defaults",
	   "toolbox.zip").exists()) {
		sv.checkToolbox2();
		return;
	}

	// otherwise, look for version 5 (kpf) toolboxes (DEPRECATED)
	sv.cmdout.message(sv.translate("(Re-)installing SciViews-K toolboxes..."));
    try {
		var path, tbxs;
		var os = Components.classes['@activestate.com/koOs;1'].
			getService(Components.interfaces.koIOs);

		var tbxMgr;
		if (ko.toolbox2 && ko.toolbox2.manager) { // Komodo >= 6.0.0?
			tbxMgr = ko.toolbox2.manager;
			var toolbox2Svc = tbxMgr.toolbox2Svc;
			var targetDirectory = toolbox2Svc.getStandardToolbox().path;
			function _installPkg(path) toolbox2Svc.importV5Package(targetDirectory, path);
		} else { // Komodo 5: (TODO: test is on Komodo 5!)
			function _installPkg(path) ko.toolboxes.importPackage(path);
			tbxMgr = null;
		}

		// Find all .kpz files in 'defaults', append/replace version string in filenames,
		// finally install as toolbox
		path = svFile.path("ProfD", "extensions",
			"sciviewsk@sciviews.org", "defaults");
		tbxs = svFile.list(path, "\\.kpz$");

		var file1, file2, path1, path2;
		for (var i in tbxs) {
			file1 = tbxs[i];
			path1 = svFile.path(path, file1);
			file2 = os.path.withoutExtension(file1.replace(/\s*(\([\s0-9a-c\.]+\)\s*)+/, ""));
			tbxs[i] = file2 + " (" + sv.version + ")";
			file2 = file2 + " (" + sv.version + ").kpz";
			path2 = svFile.path(path, file2);
			os.rename(path1, path2);
			try { 	_installPkg(path2);	} catch(e) { /***/ }
		}

		if(tbxMgr) tbxMgr.view.reloadToolsDirectoryView(-1);
		//Message prompting for removing old or duplicated toolboxes
		sv.alert(sv.translate("Toolboxes %S have been added. " +
			"To avoid conflicts, you should remove any previous or duplicated " +
			"versions. To update the toolbars, restart Komodo.", "\"" +
			tbxs.join("\" and \"") + "\""));

	} catch(e) {
		sv.log.exception(e, "Error while installing the SciViews-K & R reference toolboxes");
    }
	finally {
		sv.showVersion = true;
		sv.cmdout.message();
	}
}

// Use toolbox.zip file in 'defaults', unpack to toolbox directory
// appending version string in root folders names
sv.checkToolbox2 = function (path) {
	sv.cmdout.clear();
	sv.cmdout.message(sv.translate("(Re-)installing SciViews-K toolboxes..."));
	ko.dialogs.alert("SciViews-K toolboxes will be installed now. This may take some time.");

	var svFile = sv.tools.file;
	if(!path) path = svFile.path("ProfD", "extensions",
		"sciviewsk@sciviews.org", "defaults", "toolbox.zip");

	var tbxFile = svFile.getfile(path);
	if(!tbxFile.exists()) return;

	var os = Components.classes['@activestate.com/koOs;1'].
		getService(Components.interfaces.koIOs);
	var tbxMgr = ko.toolbox2.manager;
	var toolbox2Svc = tbxMgr.toolbox2Svc;
	var zipReader = Components.classes["@mozilla.org/libjar/zip-reader;1"]
	   .createInstance(Components.interfaces.nsIZipReader);

	var rxFolder1 = /^[^\/]+\/$/; // first level folder
	var tbxFolderPaths = [];

	// Need to replace name of top directories anyway, to avoid overwriting ones from
	// previous version. Appending also a short random string to make it unique
	var pathRx = /^([^\/]+)/;
	var pathReplacePat =  "$1_" + sv.version + "_" +
		Math.floor(Math.random() * 65536).toString(36);

	var fTargetDir = svFile.getfile("TmpD", "svtoolbox");
	if (fTargetDir.exists()) fTargetDir.remove(true);
	var targetDir = fTargetDir.path;

	var toolsDirectory = toolbox2Svc.getStandardToolbox().path;

	zipReader.open(tbxFile);
	var entries = zipReader.findEntries(null);
	var entryName, outFile, isFile, folderdata, tbxNames = [];
	while (entries.hasMore()) {
		entryName = entries.getNext();
		//Note, renaming directory works only if there is no .folderdata:
		outFile = svFile.getfile(targetDir, entryName.replace(pathRx, pathReplacePat));
		isFile = !(zipReader.getEntry(entryName).isDirectory);
		svFile.getDir(outFile, isFile, false);
		// Careful! This replaces current folders in 'tools' directory
		if(isFile) zipReader.extract(entryName, outFile);
	}
	zipReader.close();

	var tbxs = svFile.list(targetDir);
	for (var i = 0; i < tbxs.length; i++) {
		path = svFile.path(targetDir, tbxs[i]);
		toolbox2Svc.importDirectory(toolsDirectory, path);
		//sv.cmdout.append("path ->" + tbxs[i]);
	}
	fTargetDir.remove(true);

	toolbox2Svc.reloadToolsDirectory(toolsDirectory);
	tbxMgr.view.reloadToolsDirectoryView(-1);

	var rowCount = tbxMgr.view.rowCount;
	for (var i = 0; i < rowCount; i++) {
		toolPath = os.path.relpath(tbxMgr.view.getPathFromIndex(i), toolsDirectory);
		if (tbxs.indexOf(toolPath) != -1) {
			toolName = tbxMgr.view.getCellText(i, {}) + " (" + sv.version + ")";
			tbxNames.push(toolName);
			try { tbxMgr.view.renameTool(i, toolName) } catch(e) {
				// this giver error on Linux. Bug in ko.toolbox2?
				// the same when trying to rename manually.
				// "NameError: global name 'path' is not defined"
				// try other methods... edit .folderdata directly ???
			}
			//sv.cmdout.append("toolPath ->" + toolPath + " :: " + toolName);
		}
	}
	sv.cmdout.message("");

	sv.alert(sv.translate("Toolboxes %S have been added. " +
		"To avoid conflicts, you should remove any previous or duplicated " +
		"versions. To update the toolbars, restart Komodo.", "\"" +
		tbxNames.join("\" and \"") + "\""));
}

// Ensure we check the toolbox is installed once the extension is loaded
//addEventListener("load", function() {setTimeout (sv.checkToolbox, 5000) }, false);
//addEventListener("load", sv.checkToolbox, false);

// KB: "Remove 00LOCK" code moved to commands.js:sv.command.startR()

// SciViews-K general functions
// Define the basic 'sv' namespace
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

////////////////////////////////////////////////////////////////////////////////
// sv.version; // Get current SciViews-K version (major.minor)
// sv.release; // The release (bug fixes). Full version is "version.release"
// sv.checkVersion(version); // Check if the OpenKore extension version is fine
//
// Various functions defined in the 'sv' namespace directly
// sv.getText(); // Get current selection, or word under the cursor
// sv.getLine(); // Get current line in the active buffer
// sv.getPart(what, resel, clipboard); // Get a part of text in the buffer
            // or copy it to the clipboard (reset selection if resel == false)
// sv.browseURI(URI, internal); // Show URI in internal or external browser
// sv.showFile(path, readonly); // Show a file in Komodo, possibly as read-only
// sv.helpURL(URL); // Display URL help in the default browser
// sv.helpContext(); // Get contextual help for selected word in buffer in R or
                     // for active snippet in toolbox/project (see Help context)
//
// SciViews-K preferences management ('sv.prefs' namespace)
// sv.prefs.getString(pref, def); // Get a preference, use 'def' is not found
// sv.prefs.setString(pref, value, overwrite); // Set a preference string
// sv.prefs.askString(pref, defvalue): // Ask for the value of a preference
//
// OpenKore Command Output management ('sv.cmdout' namespace)
// sv.cmdout.append(str, newline); // Append text to the Command Output pane
// sv.cmdout.clear(); // Clear the Command Output pane
//
////////////////////////////////////////////////////////////////////////////////

if (typeof(sv) == 'undefined') {
	sv = {
		// TODO: set this automatically according to the plugin version
		version: 0.6,
		release: 0,
		checkVersion: function(version) {
			if (this.version < version) {
				var title = "SciViews-K"
				var prompt = "Outdated SciViews-K extension..."
				var text = "One or more macros require the SciViews-K extension "
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
// Create the 'sv.tools' namespace
if (typeof(sv.tools) == 'undefined') sv.tools = new Object();

// Other functions directly defined in the 'sv' namespace //////////////////////

// Gets current selection, or word under the cursor in the active buffer
sv.getText = function() {
	var kv = ko.views.manager.currentView;
	if (!kv) return("");
	kv.setFocus();
	var ke = kv.scimoz;
	var txt = ke.selText;
	// If selection is empty, get the word under the cursor
	if (txt == "") txt = ko.interpolate.getWordUnderCursor(ke);
	return(txt);
};

// Get current line of text in the active buffer
sv.getLine = function() {
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
};

// Select a part of text in the current buffer and return it
sv.getPart = function(what, resel, clipboard) {
	var text = "";
	var kv = ko.views.manager.currentView;
	if (kv) {
		kv.setFocus();
		var ke = kv.scimoz;
		// retain these so we can reset the selection after the extraction
		var curAnchor = ke.anchor;
		var curPos = ke.currentPos;
		var curLine = ke.lineFromPosition(curPos);
		// Depending on 'what', we select different parts of the file
		// By default, we keep current selection
		switch(what) {
		 case "sel":
			// Simply retain current selection
			break;
		 //case "function":
			// Try to select an entire R function
			// TODO...
			//break;
		 case "block":
			// Select all content between two bookmarks
			var Mark1 = ke.markerPrevious(curLine, -1);
			if (Mark1 == -1) Mark1 = 0; // Select from the start of the document
			var Mark2 = ke.markerNext(curLine, -1);
			if (Mark2 == -1) Mark2 = ke.lineCount - 1; // Select to end of doc
			ke.selectionStart = ke.positionFromLine(Mark1);
			ke.selectionEnd = ke.positionFromLine(Mark2);
			ke.lineEndExtend();
			break;
		 case "para":
			// Select the entire paragraph
			ke.paraDown();
			ke.paraUpExtend();
			break;
		 case "line":
			// Select whole current line
			ke.home();
			ke.lineEndExtend();
			break;
		 case "linetobegin":
			// Select line content from beginning to anchor
			ke.lineUpExtend();
			ke.lineEndExtend();
			ke.charRightExtend();
			break;
		 case "linetoend":
			// Select line from anchor to end of line
			ke.lineEndExtend();
			break;
		 case "end":
			// take text from current line to the end
			ke.home();
			ke.documentEndExtend();
			break;
		 case "all":
		 default:
			// Take everything
			ke.selectAll();
		}
		if (clipboard) {
			// Copy to clipboard instead of returning the text
			ke.copy();
		} else text = ke.selText;
		// Possibly reset the selection
		if (resel == false) ke.setSel(curAnchor, curPos);
	}
	return(text);
};

// Browse for the URI, either in an internal, or external (default) browser
sv.browseURI = function(URI, internal) {
	if (URI == "") {
		alert("Item not found!");	// Because we call this from other
		// functions that returns "" in case it doesn't find it (see sv.r.help)
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
};

// Show a text file in a buffer, possibly in read-only mode
sv.showFile = function(path, readonly) {
	if (path == "") {
		alert("Item not found!"); // Same remark as for sv.browseURI()
	} else {
		ko.open.URI(path, "editor");
		if (readonly == true) {
			var kv = ko.views.manager.currentView;
			var ke = kv.scimoz;
			ke.readOnly = true;
			// Make the caret a block and hatch the fold margin as indicator
			ke.caretStyle = 2;
			ke.setFoldMarginColour(true, 100);
			kv.setFocus();
		}
	}
};

// Show URL in the default browser with current selection or <keyword>
sv.helpURL = function(URL) {
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return(false);
		kv.setFocus();
		var ke = kv.scimoz;
		var sel = ke.selText;
		if (sel == "") {
			// Try to get the URL-escaped word under the cursor
			if (ko.interpolate.getWordUnderCursor(ke) == "") {
				alert("Nothing is currently selected!");
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
	} catch(e) { alert(e); }
};

// Get contextual help for a word in the buffer, or for snippets
sv.helpContext = function() {
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
				var msg = "No help found for this tool!";
				StatusBar_AddMessage(msg, "debugger", 5000, true);
				return(false);
			}
		} else {	// The focus is currently on a buffer
			// Try to get R help for current word
			topic = sv.getText();
			if (topic == "") {
				alert("Nothing is selected!");
			} else sv.r.help(topic);
		}
		return(true);
	} catch(e) {
		alert("Error while trying to get contextual help");
		return(false);
	}
};


// Preferences management //////////////////////////////////////////////////////
if (typeof(sv.prefs) == 'undefined') sv.prefs = new Object();

// Get a string preference, or default value
sv.prefs.getString = function(pref, def) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (prefs.hasStringPref(pref)) {
		return(prefs.getStringPref(pref));
	} else return(def);
};

// Set a string preference
sv.prefs.setString = function(pref, value, overwrite) {
	var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
		getService(Components.interfaces.koIPrefService);
	var prefs = prefsSvc.prefs;
	if (overwrite == false & prefs.hasStringPref(pref)) return;
	prefs.setStringPref(pref, value);
};

// Display a dialog box to change a preference string
sv.prefs.askString = function(pref, defvalue) {
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


// This is required by sv.helpContext() for attaching help to snippets (hack!)
// Create empty preference sets to be used with snippet help system hack
// [[%pref:R-help:value]] which displays nothing when the snippet is used
// but can be used to retrieve value to display a particular help page
// for this snippet
// Help page triggered by a given URL
sv.prefs.setString("URL-help", "", true);
// R HTML help pages triggered with '?topic'
sv.prefs.setString("R-help", "", true);
// Help page on the R Wiki
sv.prefs.setString("RWiki-help", "", true);


// Control the command output tab //////////////////////////////////////////////
if (typeof(sv.cmdout) == 'undefined') sv.cmdout = new Object();

// Append text to the Command Output pane
sv.cmdout.append = function(str, newline) {
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
		if (newline == null) str += ["\r\n", "\n", "\r"][scimoz.eOLMode];
		var str_byte_length = ko.stringutils.bytelength(str);
		var ro = scimoz.readOnly;
		try {
			scimoz.readOnly = false;
			scimoz.appendText(str_byte_length, str);
		} finally { scimoz.readOnly = ro; }
		// Bring the new text into view
		scimoz.gotoPos(prevLength + 1);
	} catch(e) { alert("Problems printing [" + str + "]:" + e + "\n"); }
};

// Clear text in the Output Command pane
sv.cmdout.clear = function() {
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
	} catch(e) { alert("problems clearing the Command Output pane\n"); }
};

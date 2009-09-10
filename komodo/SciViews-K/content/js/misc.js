// SciViews-K miscellaneous functions
// Define the 'sv.misc' namespace
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.misc.closeAllOthers();    // Close all buffer except current one
// sv.misc.colorPicker();       // Invoke a color picker dialog box
// sv.misc.moveLineDown();      // Move current line down
// sv.misc.moveLineUp();        // Move current line up
// sv.misc.searchBySel();       // Search next using current selection
// sv.misc.showConfig();        // Show Komodo configuration page
// sv.misc.swapQuotes();        // Swap single and double quotes in selection
// sv.misc.pathToClipboard(); // Copy file path to clipboard
// sv.misc.unixPathToClipboard(); // Copy file path in UNIX format to clipboard
// sv.misc.timeStamp(); // Stamp text with current date/time
// sv.misc.delLine(); // Delete current line in buffer
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.misc' namespace
if (typeof(sv.misc) == 'undefined')
	sv.misc = {};

// Close all buffers except current one (an start page)
sv.misc.closeAllOthers = function () {
    try {
        var view = ko.views.manager.currentView;
        if (view) {
            var curr_uri = view.document.file.URI;
            var views = ko.views.manager.topView.getDocumentViews(true);
            for (var i = views.length - 1; i >= 0; i--) {
                // Exclude the Start Page from "Close All".
                var thisView = views[i];
                if (thisView.getAttribute("type") != "startpage"
                    && thisView.document.file
                    && thisView.document.file.URI != curr_uri) {
                    if (! thisView.close()) {
                    return false;
                    }
                }
            }
        }
    } catch(e) {
        sv.log.exception(e, "sv.misc.closeAllOthers() error");
    }
}

/*
 * JavaScript macro to provide a basic color picker for hexadecimal colors.
 * Assign a useful keybinding to this macro and ka-zam, funky color picking!
 *
 * Version: 1.0
 *
 * Authored by: David Ascher
 * Modified by: Shane Caraveo
 *              Todd Whiteman
 *              Philippe Grosjean
 */
sv.misc.colorPicker_system = function (color) {
    var sysUtils = Components.classes['@activestate.com/koSysUtils;1'].
        getService(Components.interfaces.koISysUtils);
    if (!color)
        color = "#000000";
    newcolor = sysUtils.pickColor(color);
    if (newcolor) {
       var scimoz = ko.views.manager.currentView.scimoz;
       scimoz.replaceSel(newcolor);
       scimoz.anchor = scimoz.currentPos;
    }
}

sv.misc.colorPicker_onchange = function (event, cp) {
    var scimoz = ko.views.manager.currentView.scimoz;
    scimoz.insertText(scimoz.currentPos, cp.color);
    // Move cursor position to end of the inserted color
    // Note: currentPos is a byte offset, so we need to correct the length
    var newCurrentPos = scimoz.currentPos + ko.stringutils.bytelength(cp.color);
    scimoz.currentPos = newCurrentPos;
    // Move the anchor as well, so we don't have a selection
    scimoz.anchor = newCurrentPos;
    // for some reason we get the event twice, removing
    // onselect fixes the problem.  Tried to solve it
    // by canceling the event below, but it went on anyway
    cp.removeAttribute('onselect');
    cp.parentNode.hidePopup();

    event.preventDefault();
    event.stopPropagation();
    event.cancelBubble = true;
    sv.misc.colorPicker_remove();
}

sv.misc.colorPicker_remove = function () {
    // remove the popup from the document. This cleans up so
    // we can change the macro code if needed
    var p = document.getElementById('popup_colorpicker');
    if (p)
        p.parentNode.removeChild(p);
}

sv.misc.colorPicker_init = function () {
    sv.misc.colorPicker_remove();
    var p = document.createElement('popup');
    p.setAttribute('id', 'popup_colorpicker');
    var cp = document.createElement('colorpicker');
    cp.colorChanged = sv.misc.colorPicker_onchange;
    cp.setAttribute('onselect', 'this.colorChanged(event, this);');
    p.appendChild(cp);
    document.documentElement.appendChild(p);
}

sv.misc.colorPicker = function () {
    var currentView = ko.views.manager.currentView;
    if (currentView) {
        currentView.scintilla.focus();
        var os_prefix = window.navigator.platform.substring(0, 3).toLowerCase();
        if ((os_prefix == "win") || (os_prefix == "mac")) {
            var color = null;
            try {
                color = ko.interpolate.interpolate(window, ["%s"], [])[0];
            } catch(e) {
                // No selection, ignore this error.
            }
            sv.misc.colorPicker_system(color);
        } else {
            init_colorpicker();
            var scimoz = currentView.scimoz;
            var pos = scimoz.currentPos;
            var x = scimoz.pointXFromPosition(pos);
            var y = scimoz.pointYFromPosition(pos);
            var boxObject = currentView.boxObject;
            var cp = document.getElementById('popup_colorpicker');
            cp.showPopup(currentView.scintilla,
                x + boxObject.x, y + boxObject.y,
                'colorpicker',"topleft","topleft");
        }
    }
}

// Move Line Down, adapted by Ph. Grosjean from code by "mircho"
sv.misc.moveLineDown = function () {
    var currentView = ko.views.manager.currentView;
    if (currentView) {
        currentView.scintilla.focus();
        var ke = currentView.scimoz;
        var currentLine = ke.lineFromPosition(ke.currentPos);
        // Check if we are not at the last line
        if( currentLine < (ke.lineCount - 1)) {
            ke.lineDown();
            ke.lineTranspose();
        }
    }
}

// Move Line Up, adapted by Ph. Grosjean from code by "mircho"
sv.misc.moveLineUp = function () {
    var currentView = ko.views.manager.currentView;
    if (currentView) {
        currentView.scintilla.focus();
        var ke = currentView.scimoz;
        var currentLine = ke.lineFromPosition(ke.currentPos);
        // Check if we are not at the first line
        if (currentLine > 0) {
            ke.lineTranspose();
            ke.lineUp();
        }
    }
}

// Search next using current selection
sv.misc.searchBySel = function () {
    var currentView = ko.views.manager.currentView;
    if (currentView) {
        currentView.scintilla.focus();
        var ke = currentView.scimoz;
        var searchText = ke.selText;
        if (!searchText.length) {
            // use last pattern used
            searchText = ko.mru.get("find-patternMru");
        }

        // Search with last user find preferences
        var findSvc = Components.classes["@activestate.com/koFindService;1"]
                .getService(Components.interfaces.koIFindService);
        var context = Components.classes["@activestate.com/koFindContext;1"]
                .createInstance(Components.interfaces.koIFindContext);
        context.type = findSvc.options.preferredContextType;
        Find_FindNext(window, context, searchText);
    }
}

// Show current Komodo configuration page
sv.misc.showConfig = function () {
    try {
        ko.open.URI('about:config','browser');
    } catch(e) {
        sv.log.exception(e, "sv.misc.showConfig() error");
    }
}

// Swap quotes by 'Nicto', adapted in SciViews-K by Ph. Grosjean
sv.misc.swapQuotes = function() {
    try {
        var currentView = ko.views.manager.currentView;
        if (currentView) {
            currentView.scintilla.focus();
            var scimoz = currentView.scimoz;
            scimoz.beginUndoAction();

            // Retain these so we can reset the selection after the replacement
            var curAnchor = scimoz.anchor;
            var curPos = scimoz.currentPos;

            // Replace the currently selected text
            scimoz.replaceSel(
                // Find all single and double quote characters
                scimoz.selText.replace( /[\'\"]/g, function (value) {
                    // Return whatever the value isn't
                    return value == '"'?"'":'"';
                })
            );

            // Reset the selection
            scimoz.setSel(curAnchor, curPos);
        }
    } catch (e) {
        sv.log.exception(e, "sv.misc.showConfig() error");
    } finally {
        ko.views.manager.currentView.scimoz.endUndoAction();
    }
}

// Copy the path of current file to the clipboard
sv.misc.pathToClipboard = function () {
    var ch = Components.classes["@mozilla.org/widget/clipboardhelper;1"].
        getService(Components.interfaces.nsIClipboardHelper);
    try {
        ch.copyString(ko.views.manager.currentView.document.file.path);
    } catch(e) {
        sv.alert("Copy path to clipboard",
            "Unable to copy file path to clipboard (unsaved file?)")
    }
}

// Copy the UNIX version (using '/' as sep) path of current file to the clipboard
sv.misc.unixPathToClipboard = function () {
    var ch = Components.classes["@mozilla.org/widget/clipboardhelper;1"].
        getService(Components.interfaces.nsIClipboardHelper);
    try {
        ch.copyString(ko.views.manager.currentView.document.file.path.
            replace(/\\/g, "/"));
    } catch(e) {
        sv.alert("Copy path to clipboard",
            "Unable to copy file path to clipboard (unsaved file?)")
    }
}

// Stamp the current text with date - time
// Use preferences -> Internationalization -> Date & Time format to change it!
sv.misc.timeStamp = function () {
    try {
        var ke = ko.views.manager.currentView.scimoz;
        var strTime = ko.interpolate.interpolateStrings('%date');
        ke.replaceSel(strTime);
    } catch(e) {
        sv.log.exception(e, "sv.misc.timeStamp() error");
    }
}

// Delete current line
// not really necessary. to be removed??
sv.misc.delLine = function () {
    ko.commands.doCommand('cmd_lineDelete');
}

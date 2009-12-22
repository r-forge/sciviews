// SciViews-K interpolation function
// Copyright (c) 2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// ko.interpolate.interpolate();  	// A reworked version of the Komodo function
//   with more features needed by R code snippets (contextual help, description,
//   tooltips, ...)
////////////////////////////////////////////////////////////////////////////////

/**
  *  * Interpolate '%'-escape codes in the given list(s) of strings.
  *
  *  "editor" is a reference the komodo.xul window.
  *  "strings" is a list of raw strings to interpolate.
  *  "bracketedStrings" is a list of raw strings to interpolate, using the bracketed form
  *  "queryTitle" (optional) is a title for the possible query dialog raised
  *      during interpolation.
  *  "viewData" (optional) allows one to override specific view data used for
  *      interpolation. By default view data is retrieved from the current view.
  *      This may not always be appropriate. It may be an object with one or
  *      more of the following attributes:
  *          "fileName" is the filename of the current file (null, if N/A);
  *          "lineNum" is the current line number (0, if N/A);
  *          "word" is the current word under cursor (null if none);
  *          "selection" is the current selection (null if none).
  *
  * On success, this function returns a *double* list of interpolated strings:
  * For each string in "strings" and "bracketedStrings" two strings are
  * returned. The first is the interpolated string for use and the second for
  * *display*. In most cases these are the same but they may differ, for
  * example, if a password query response was interpolated into the string which
  * should not be displayed in the Komodo UI.
  *
  * Otherwise an exception is raised and an error set on the last error service:
  *      koILastError errno      reason
  *      ----------------------- -----------------------------------------
  *      NS_ERROR_ABORT          User cancelled the query dialog.
  *      NS_ERROR_INVALID_ARG    A normal interpolation failure because of
  *                              invalid interp code usage.
  */
ko.interpolate.interpolate = function Interpolate_interpolate(editor, strings,
	bracketedStrings,
    queryTitle /* =null */,
	viewData /* =<determined from current view> */)
{
    try {
    if (typeof queryTitle == 'undefined') queryTitle = null;
	log.info("interpolate.interpolate(editor, strings=["+strings+
                          "], bracketedStrings=["+bracketedStrings+"], queryTitle='"+
                          queryTitle+"', viewData)");
    viewData = ko.interpolate.getViewData(editor, viewData);

    var lastErrorSvc = Components.classes["@activestate.com/koLastErrorService;1"]
                       .getService(Components.interfaces.koILastErrorService);

    // Interpolation step 1: get queries.
    var queriesCountObj = new Object();
    var queriesObj = new Array();
    var i1countObj = new Object();
    var i1stringsObj = new Array();

    //XXX The prefset used may need to be the project prefs at some point in
    //    the future, for now we'll stick with the current view's prefset.
    var iSvc = Components.classes["@activestate.com/koInterpolationService;1"]
               .getService(Components.interfaces.koIInterpolationService);
    iSvc.Interpolate1(strings.length, strings,
                      bracketedStrings.length, bracketedStrings,
                      viewData.fileName, viewData.lineNum,
                      viewData.word, viewData.selection,
                      viewData.projectFile,
                      viewData.prefSet,
                      queriesCountObj, queriesObj,
                      i1countObj, i1stringsObj);
    var queries = queriesObj.value;
    var istrings = i1stringsObj.value;

    // Ask the user for required data. (If there are no queries then we are
    // done interpolating.)
    if (queries.length != 0) {
        var obj = new Object();
        obj.queries = queries;
        obj.title = queryTitle;
		// PhG: this is added to allow access to sv... functions
		obj.sv = sv;
        
		// PhG: replaced this by my own dialog box with extra features
		//window.openDialog("chrome://komodo/content/run/interpolationquery.xul",
        window.openDialog("chrome://sciviewsk/content/Rinterpolationquery.xul",
		                  "Komodo:InterpolationQuery",
                          "chrome,modal,titlebar",
                          obj);
        if (obj.retval == "Cancel") {
            var errmsg = "Interpolation query cancelled.";
            lastErrorSvc.setLastError(Components.results.NS_ERROR_ABORT, errmsg);
            throw errmsg;
        }

        // Interpolation step 2: interpolated with answered queries.
        var i2countObj = new Object();
        var i2stringsObj = new Array();
        iSvc.Interpolate2(istrings.length, istrings,
                          queries.length, queries,
                          i2countObj, i2stringsObj);
        istrings = i2stringsObj.value;
    }

	// PhG: If there is a end indicator in the snippet (______ at the start
	// of a line), then cut the string there
	for (var i = 0; i < istrings.length; i++) {
		//istrings[i] = istrings[i].replace(/[\n\r]{1,2}.*$/, "");
		// Do we need to eliminate a part of the snippet?
		var isplit = istrings[i].split(/[\n\r]{1,2}______/);
		if (isplit.length > 1) {
			// Keep only first part
			istrings[i] = isplit[0];
			// The string must contain both !@#_currentPos and !@#_anchor
			if (istrings[i].indexOf("!@#_currentPos") == -1) {
				// If !@#_anchor is there, add !@#_currentPos at the end
				if (istrings[i].indexOf("!@#_anchor") > -1) {
					istrings[i] = istrings[i] + "!@#_currentPos";
				}
			} else { // !@#_currentPos is there, make sure !@#_anchor is also there
				if (istrings[i].indexOf("!@#_anchor") == -1) {
					istrings[i] = istrings[i] + "!@#_anchor";
				}
			}
		}
	}

    log.info("interpolate.interpolate: istrings=["+istrings+"]");
    return istrings;
    } catch(e) {
        log.exception(e);
        throw e;
    }
}

// SciViews-K R preferences panel functions
// Copyright (c) 2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// svPrefR_OnPreferencePageOK(prefset);         // User click OK
// svPrefR_OnLoad();                            // R preference widow loaded
// svPrefR_loadRExecutable();                   // Select R executable
// svPrefR_finishSpecifyingExecutable(path);    // Set R executable
////////////////////////////////////////////////////////////////////////////////
//
// TODO: use 'R' simply as default R (terminal on Win/Mac, or ? on Linux)

function svPrefR_OnPreferencePageOK (prefset) {
    var ok = true;

    // Ensure that the interpreter is valid
    var defaultInterp = prefset.getStringPref("RDefaultInterpreter");
    if (defaultInterp != "") {
        var koSysUtils = Components.classes["@activestate.com/koSysUtils;1"].
            getService(Components.interfaces.koISysUtils);
        // If the interpreter's name ends with '.app', it is a Mac application
        // meaning it is a directory instead of a file!
        if (!koSysUtils.IsFile(defaultInterp) &
            !koSysUtils.IsDir(defaultInterp)) {
            dialog_alert("No R interpreter could be found at '" + defaultInterp +
                  "'. You must make another selection for the default " +
                  "R interpreter.\n");
            ok = false;
            document.getElementById("R_interpreterPath").focus();
        }
    }
    return ok;
}

function svPrefR_OnLoad () {
    var prefExecutable;
    var prefName = 'RDefaultInterpreter';
    // If there is no pref, create it, otherwise trying to save a new pref
    // will fail, because it tries to get an existing one to see if the
    // pref needs updating.
    if (!parent.hPrefWindow.prefset.hasStringPref(prefName)) {
        parent.hPrefWindow.prefset.setStringPref(prefName, "");
        prefExecutable = '';
    } else {
        prefExecutable = parent.hPrefWindow.prefset.getStringPref(prefName);
        if (prefExecutable == null) {
            prefExecutable = '';
        }
    }
    svPrefR_finishSpecifyingExecutable(prefExecutable);
}

function svPrefR_loadRExecutable () {
    svPrefR_finishSpecifyingExecutable(filepicker_openExeFile());
}

function svPrefR_finishSpecifyingExecutable (path) {
    if (path != null) {
        document.getElementById("R_interpreterPath").value = path;
    }
}

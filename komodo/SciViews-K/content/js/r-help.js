// this is replacement for language specific help on selection function
// (cmd_helpLanguage command)
// to handle R help (without using system command)

// this should be kept updated with new versions of the original function
ko.help.language = function () {
    var language = null;
    var view = ko.window.focusedView();
    if (!view) {
        view = ko.views.manager.currentView;
    }
    if (view != null) {
        if (view.document) {
            language = view.document.subLanguage;
            if (language == "XML") {
                language = view.document.language;
            }
        } else {
            language = view.language;
        }
    }

    var command = null, name = null;
    if (language) {
		//////////////////////// R help mod:
		if (language == "R") {
			var topic;
			try {
				topic = ko.interpolate.interpolateStrings("%w").trim();
				sv.r.help(topic);
				return;
			} catch (e) {}

		} //////////////// end: R help mod

        if (gPrefs.hasStringPref(language + "HelpCommand")) {
            command = gPrefs.getStringPref(language + "HelpCommand");
        } else {
            var langRegistrySvc = Components.classes['@activestate.com/koLanguageRegistryService;1'].getService(Components.interfaces.koILanguageRegistryService);
            var languageObj = langRegistrySvc.getLanguage(language);
            if (languageObj.searchURL) {
                command = "%(browser) " + languageObj.searchURL;
            }
        }
        if (command) {
            name = language + " Help";
        }
    }
    if (!command) {
        command = gPrefs.getStringPref("DefaultHelpCommand");
        name = "Help";
    }
    ko.run.runCommand(window, command, null, null, false, false, true, "no-console", 0, "", 0, name);
}

/*

Controllers for R related commands.

*/


if (typeof(sv.command) == 'undefined') {
    sv.command = {};
}


// sv.cmd object constructor:
(function() {

// private methods:
function _RControl_supported() {
	var currentView = ko.views.manager.currentView;
	if (!currentView || !currentView.document)
		return false;

	return(currentView.document.language == "R");
}

function _RControlSelection_supported() {
	var currentView = ko.views.manager.currentView;
	if (!currentView || !currentView.scimoz)
		return false;

	var anythingSelected = (currentView.scimoz.selectionEnd - currentView.scimoz.selectionStart) != 0;
	return(currentView.document.language == "R" && anythingSelected);
}

this.openPkgManager = function() {
	window.openDialog(
	  "chrome://sciviewsk/content/pkgManager.xul",
	  "RPackageManager",
	  "chrome=yes,dependent,centerscreen,resizable=yes,scrollbars=yes,status=no",
	  sv);
}


this.setControllers = function() {
	// make these commands active only when current document language is R
	var cmdNames = ["RunAll", "SourceAll", "RunBlock", "RunFunction", "RunLine", "RunPara",
	 "SourceBlock", "SourceFunction", "SourcePara"];

	var viewManager = ko.views.viewManager;
	for (i in cmdNames) {
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_supported"] = _RControl_supported;
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_enabled"] = _RControl_supported;
	}

	// make these commands active only when current document language is R
	// ... and if some text is selected
	cmdNames = [ "RunSelection", "SourceSelection"];
	for (i in cmdNames) {
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_supported"] = _RControlSelection_supported;
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_enabled"] = _RControlSelection_supported;
	}

	viewManager.prototype.do_cmd_sv_RRunLine = function() 	{ sv.r.send("line"); };

	viewManager.prototype.do_cmd_sv_RRunAll = function()		{ sv.r.send("all"); };
	viewManager.prototype.do_cmd_sv_RSourceAll = function() 	{ sv.r.source("all"); };

	viewManager.prototype.do_cmd_sv_RSourcePara = function() 	{ sv.r.source("para"); };
	viewManager.prototype.do_cmd_sv_RRunPara = function()		{ sv.r.send("para"); };

	viewManager.prototype.do_cmd_sv_RRunSelection = function()		{ sv.r.send("sel"); };
	viewManager.prototype.do_cmd_sv_RSourceSelection = function()	{ sv.r.source("sel"); };

	viewManager.prototype.do_cmd_sv_RRunBlock = function()		{ sv.r.send("block"); };
	viewManager.prototype.do_cmd_sv_RSourceBlock = function()	{ sv.r.source("block"); };

	viewManager.prototype.do_cmd_sv_RRunFunction = function()		{ sv.r.send("function"); };
	viewManager.prototype.do_cmd_sv_RSourceFunction = function()	{ sv.r.source("function"); };


	// TODO: submenu with checkboxes to select preferred way to start R
	viewManager.prototype.do_cmd_svStartR = function()	{
		// runIn = "command-output-window", "new-console", "no-console"
		//env strings: "ENV1=fooJ\nENV2=bar"
		//gPrefSvc.prefs.getStringPref("runEnv");

		var env = ["koPort=%(pref:sciviews.server.socket)", "koId=%(pref:sciviews.client.id)", "koHost=localhost",
			 "koActivate=FALSE", "Rinitdir=~", "koServe=%(pref:sciviews.client.socket)", "Rid=Rgui"];

		var cwd = "%(path:hostUserDataDir)/XRE/extensions/sciviewsk@sciviews.org/templates";

		cwd = ko.interpolate.interpolateStrings(cwd);

		for (i in env) {
			try {
				env[i] = ko.interpolate.interpolateStrings(env[i]);
			} catch (e) {
				alert(e + "\n" + env[i]);
				return;
			}
		}
		ko.run.runCommand(window, "Rgui --sdi", cwd, env.join("\n"), false, false, false, "no-console", false, false, false)
	};
}

}).apply(sv.command);




//sv.cmdsSetControllers();
addEventListener("load", sv.command.setControllers, false);

/*

//Useful garbage. delete it later.

// command controllers template:
vm.prototype.is_cmd_Test_supported
vm.prototype.do_cmd_Test = function() { alert("do_cmd_Test!"); }
vm.prototype.is_cmd_Test_supported = function() {
	alert("is_cmd_Test_supported?:" + ko.views.manager.currentView.document.language);
	return(ko.views.manager.currentView.document.language == "R");
}
vm.prototype.is_cmd_Test_enabled = function() { alert("is_cmd_Test_enabled?"); return false; }

//commands sohuld be put in a commandset, so they can be enabled only if lang = R
document.getElementById("cmdset_view_or_language_changed")

select,current_view_changed,language_changed
var x = document.getElementById("cmdset_r_control")
x.oncommandupdate = function oncommandupdate(event) { ko.commands.updateCommandset(this); sv.cmdout.append(ko.views.manager.currentView.document.language) }

id="cmdset_r_control"
current_view_language_changed

*/

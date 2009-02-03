/*

Controllers for R related commands.

*/


sv.cmdsRControl_supported = function() {
	var currentView = ko.views.manager.currentView;
	if (!currentView)
		return false;

	return(currentView.document.language == "R");
}

sv.cmdsRControlSelection_supported = function() {
	var currentView = ko.views.manager.currentView;
	if (!currentView)
		return false;

	var anythingSelected = (currentView.scimoz.selectionEnd - currentView.scimoz.selectionStart) != 0;
	return(currentView.document.language == "R" && anythingSelected);
}


sv.cmdsSetControllers = function() {
	//alert("cmdsSetControllers!");

	// make commands active only when current document language is R
	var cmdNames = ["RunAll", "SourceAll", "RunBlock", "RunFunction", "RunLine", "RunPara",
	 "SourceBlock", "SourceFunction", "SourcePara"];

	var viewManager = ko.views.viewManager;
	for (i in cmdNames) {
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_supported"] = sv.cmdsRControl_supported;
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_enabled"] = sv.cmdsRControl_supported;
	}

	// make these commands active only when current document language is R
	// ... and if some text is selected
	cmdNames = [ "RunSelection", "SourceSelection"];
	for (i in cmdNames) {
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_supported"] = sv.cmdsRControlSelection_supported;
		viewManager.prototype["is_cmd_sv_R" + cmdNames[i] + "_enabled"] = sv.cmdsRControlSelection_supported;
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



	viewManager.prototype.do_cmd_svStartR = function()	{
		// runIn = "command-output-window", "new-console", "no-console"
		//env strings: "ENV1=fooJ\nENV2=bar"
		//gPrefSvc.prefs.getStringPref("runEnv");

		var env = ["koPort=[[%pref:sciviews.server.socket]]", "koId=[[%pref:sciviews.client.id]]", "koHost=localhost",
			 "koActivate=FALSE", "Rinitdir=~", "koServe=[[%pref:sciviews.client.socket]]", "Rid=Rgui"];

		var cwd = "%(path:hostUserDataDir)/XRE/extensions/sciviewsk@sciviews.org/templates";

		cwd = ko.interpolate.interpolateStrings(cwd);

		for (i in env) {
			try {
				env[i] = ko.interpolate.interpolateStrings(env[i]);
			} catch (e) {
				alert(e);
				return;
			}
		}
		ko.run.runCommand(window, "Rgui --sdi", cwd, env.join("\n"), false, false, false, "new-console", false, false, false)

	};

}

addEventListener("load", sv.cmdsSetControllers, false);

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

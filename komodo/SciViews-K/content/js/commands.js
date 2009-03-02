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


// selects the checkbox on selected element, while deselecting others
this.getRApp = function(event) {
	  var el = event.originalTarget;
	  var siblings = el.parentNode.childNodes;
	  for (var i = 0; i < siblings.length; i++) {
			try {
				  siblings[i].setAttribute("checked", siblings[i] == el);
			} catch(e) {}
	  }
	  // this will preserve the selection:
	  el.parentNode.setAttribute('selected',  el.id);
	  // set the preference string:
	  sv.prefs.setString("sciviews.preferredRApp", el.id, true);

	  document.getElementById("cmd_svStartR").setAttribute("label",
			sv.translate("StartR") + " (" + el.getAttribute('label') + ")");

}


// Selects checkbox on the 'preferred R application' menu on its first display
// and hides unsupported commands
// It is triggered on popupshowing event, onload would be better,
// but it is for compatibility with komodo 4 which doesn't seem to support onload
this.setMenuRApp = function (el) {
	  var selected = el.getAttribute('selected');
	  var siblings =  el.childNodes;

	  var validPlatforms, showItem;
	  var platform = navigator.platform;
	  for (var i = 0; i < siblings.length; i++) {
			try {
				  validPlatforms = siblings[i].getAttribute("platform").split(/\s*[,\s]\s*/);
				  showItem = false;
				  for (var j in validPlatforms) {
						if (platform.indexOf(validPlatforms[j]) == 0) {
							  showItem = true;
							  break;
				  }}

				  if  (!showItem) {
						siblings[i].style.display = "none";
				  } else {
						siblings[i].setAttribute("checked",  siblings[i].id == selected);
				  }

			} catch(e) {}
	  }

	  // set the preference string:
	  sv.prefs.setString("sciviews.preferredRApp", selected, false);

	  document.getElementById("cmd_svStartR").setAttribute("label",
			sv.translate("StartR") + " (" + document.getElementById(selected).getAttribute('label') + ")"
			);

	  // we do not need to run it anymore:
	  el.removeAttribute("onpopupshowing");
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
		// runIn = "command-output-window", "new-console",
		//env strings: "ENV1=fooJ\nENV2=bar"
		//gPrefSvc.prefs.getStringPref("runEnv");

		var preferredRApp = sv.prefs.getString("sciviews.preferredRApp", "r-terminal");


		var env = ["koPort=%(pref:sciviews.server.socket)", "koId=%(pref:sciviews.client.id)", "koHost=localhost",
			 "koActivate=FALSE", "Rinitdir=~", "koServe=%(pref:sciviews.client.socket)"];

		var cwd = "%(path:hostUserDataDir)/XRE/extensions/sciviewsk@sciviews.org/templates";
		cwd = ko.interpolate.interpolateStrings(cwd);


		var command, mode = "no-console";

		switch (preferredRApp) {
			case "r-gui":
				  env.push("Rid=Rgui");
				  command = "Rgui --sdi";
				  break;
			case "r-xfce4-term":
				  env.push("Rid=R-xfce4-term");
				  command = "xfce4-terminal --title \"R\" -x R --quiet";
				  break;
			case "r-gnome-term":
				  env.push("Rid=R-gnome-term");
				  command = "gnome-terminal --hide-menubar --title=SciViews-R -x R --quiet";
				  break;
			case "r-kde-term":
				  env.push("Rid=R-kde-term");
				  command = "konsole --nomenubar --notabbar --noframe -T SciViews-R -e R --quiet";
				  break;
			case "r-tk":
				  env.push("Rid=R-tk");
				  env.push("DISPLAY=:0");
				  command = "R --quiet --gui=Tk";
				  mode = "new-console";
				  break;
			case "r-app":
				  env.push("Rid=R.app");
				  command = "open -a /Applications/R.app \"" + cwd + "\"";
				  break;
			default:
				  env.push("Rid=R");
				  command = "R --quiet";
				  mode = "new-console";

		}
		for (i in env) {
			try {
				env[i] = ko.interpolate.interpolateStrings(env[i]);
			} catch (e) {
				alert(e + "\n" + env[i]);
				return;
			}
		}
		ko.run.runCommand(window, command, cwd, env.join("\n"), false,
						  false, false, mode, false, false, false);
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

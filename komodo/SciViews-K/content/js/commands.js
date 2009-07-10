/*

Controllers for R related commands.

*/


if (typeof(sv.command) == 'undefined') {
    sv.command = {};
}


// sv.command object constructor:
(function() {

var isRRunning = false;

// private methods:
function _RControl_supported() {
	var currentView = ko.views.manager.currentView;
	if (!currentView || !currentView.document)
		return false;

	return(currentView.document.language == "R");
}


function _isRRunning() {
	//sv.cmdout.append("is R Running? " + isRRunning);
	return isRRunning;
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

	  var isLinux = navigator.platform.toLowerCase().indexOf("linux") > -1;

		// this will tell whether an app is present on the *nix system
	  if (isLinux) {
	    function whereis(app) {
			var runSvc = Components.classes["@activestate.com/koRunService;1"]
				.getService(Components.interfaces.koIRunService);
			var err = {}, out = {};
			var res = runSvc.RunAndCaptureOutput("whereis -b " + app, null, null, null, out, err);
			var path = out.value.substr(app.length + 2);
			if (!path) return false;
			return out.value.substr(app.length + 2).split(" ");
	    }
	  }

	  var validPlatforms, showItem;
	  var platform = navigator.platform;
	  for (var i = 0; i < siblings.length; i++) {
			try {
			    validPlatforms = siblings[i].getAttribute("platform").split(/\s*[,\s]\s*/);
			    showItem = false;
			    for (var j in validPlatforms) {
				if (platform.indexOf(validPlatforms[j]) == 0) {
					// on linux, try to determine which terminals are not available
					// and remove these items from menu
				    if (!isLinux || whereis(siblings[i].getAttribute("app"))) {
						showItem = true;
						break;
				    }
				}
			    }

				  if  (!showItem) {
						siblings[i].style.display = "none";
				  } else {
						siblings[i].setAttribute("checked", siblings[i].id == selected);
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

// this will observe status message notification. This is to get informed about
// application being terminated. A more straightforward way would be to use runService.RunAndNotify
// but, this wouldn't allow to start app in a console window. So we have to do this trick here.


function AppTerminateObserver(command) {
	this.register(command);
}


AppTerminateObserver.prototype = {
	command: "",
	// this is launched when status message is set, we then check if it was about
	// terminated application :
	observe: function(subject, topic, data) {
		var matches;

		if ((subject.category == "run_command") &&
			(matches = subject.msg.match(/^(['`"])(.+)\1 returned ([0-9]+).$/)) != null &&
			matches[2] == this.command
			) {
			// seems like this is a 'R quit' msg
			this.unregister();
			// do something here... activate/deactivate commands, stuff like that...
		}
	},
	register: function(command) {
	  var observerSvc = Components.classes["@mozilla.org/observer-service;1"]
		 .getService(Components.interfaces.nsIObserverService);
	  this.command = command;
	  observerSvc.addObserver(this, 'status_message', false);
	  sv.debugMsg("R has been started with command: " + command);
	  isRRunning = true;

	  xtk.domutils.fireEvent(window, 'r_app_started_closed');
	  window.updateCommands('r_app_started_closed');
	},
	unregister: function() {
	  var observerSvc = Components.classes["@mozilla.org/observer-service;1"]
		 .getService(Components.interfaces.nsIObserverService);
	  observerSvc.removeObserver(this, 'status_message');

	  //sv.cmdout.append("debug: R process observer successfully unregistered.");
	  sv.debugMsg("R has been closed. Command was: " + this.command);

	  isRRunning = false;
	  xtk.domutils.fireEvent(window, 'r_app_started_closed');
	  window.updateCommands('r_app_started_closed');
	}
}



this.setControllers = function() {
	//alert("this.setControllers");
	// allow some commands only whan R is running...
	// using this needs solving an issue of running R in some terminals on linux (mac?)
    // that send terminate signal right after start.
	//viewManager.prototype.is_cmd_svOpenPkgManager_enabled = _isRRunning;
	//viewManager.prototype.is_cmd_svOpenPkgManager_supported = _isRRunning;
	//viewManager.prototype.is_cmd_svBrowseWD_enabled = _isRRunning;
	//viewManager.prototype.is_cmd_svBrowseWD_supported = _isRRunning;

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


	viewManager.prototype.do_cmd_svStartR = function()	{
		// runIn = "command-output-window", "new-console",
		//env strings: "ENV1=fooJ\nENV2=bar"
		//gPrefSvc.prefs.getStringPref("runEnv");

		var isWin = navigator.platform == "Win32";
		var preferredRApp = sv.prefs.getString("sciviews.preferredRApp", "r-terminal");

		var env = ["koId=" + sv.prefs.getString("sciviews.client.id", "SciViewsK"),
				   "koHost=localhost",
				   "koActivate=FALSE",
				   "Rinitdir=" + sv.io.makePath(isWin? "Pers" : "Home"),
				   "koServe=" + sv.prefs.getString("sciviews.client.socket", "8888"),
				   "koPort=" + sv.prefs.getString("sciviews.server.socket", "7052"),
				   "koAppFile=" + sv.io.makePath("CurProcD", ["komodo" + (isWin? ".exe" : "")])
		   ];

		var cwd = sv.io.makePath("ProfD",
					["extensions", "sciviewsk@sciviews.org", "templates"]);

		var command, runIn = "no-console";

		switch (preferredRApp) {
			case "r-gui":
				  env.push("Rid=Rgui");
				  command = "Rgui --sdi";
				  break;
			case "r-xfce4-term":
				  env.push("Rid=R-xfce4-term");
				  command = "xfce4-terminal --title \"SciViews-R\" -x R --quiet";
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
				  // set DISPLAY only when not set:
				  var XEnv = Components.classes["@activestate.com/koEnviron;1"]
				    .createInstance(Components.interfaces.koIEnviron);
				  if (!XEnv.has("DISPLAY"))
				    env.push("DISPLAY=:0");
				  delete XEnv;
				  command = "R --quiet --save --gui=Tk";
				  //runIn = "no-console";
				  break;
			case "r-app":
				  env.push("Rid=R.app");
				  command = "open -a /Applications/R.app \"" + cwd + "\"";
				  break;
			default:
				  env.push("Rid=R");
				  command = "R --quiet";
				  runIn = "new-console";

		}

		// debugging garbage...
		//var command = "CMD /C \"SET\" > c:\\env.txt & notepad c:\\env.txt";

		//ko.run.runCommand(window,  "CMD /C \"SET\" > c:\\env.txt & notepad c:\\env.txt", cwd, {});
		//var runSvc = Components.classes["@activestate.com/koRunService;1"]
			//.getService(Components.interfaces.koIRunService);
		//var Rapp = runSvc.RunAndNotify(command, cwd, env.join("\n"), null);
		//ko.run.runCommand(window, command, cwd, env.join("\n"), false,

		ko.run.runCommand(window, command, cwd, env.join("\n"), false,
						  false, false, runIn, false, false, false);

		// register observer of application termination.
		this.rObserver = new AppTerminateObserver(command);
	};
}

}).apply(sv.command);


//sv.command.setControllers();
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

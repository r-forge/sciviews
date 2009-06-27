// SciViews-K R functions
// Define functions to command R from Komodo Edit
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

////////////////////////////////////////////////////////////////////////////////
// To cope with versions incompatibilities, we define this:
// alert(sv.r.RMinVersion); // Display minimum R version required
//
// These functions are available if you trigger this macro on startup
// Then, you can use them in other macros, menus, toolbars, ...
// sv.r.eval(cmd); // Evaluate 'cmd' in R
// sv.r.evalHidden(cmd, earlyExit); // Evaluate 'cmd' in R in a hidden way
// sv.r.evalCallback(cmd, procfun); // Evaluate 'cmd' in R and call 'procfun'
// sv.r.escape(); // Escape R calculation or multiline mode
// sv.r.setwd(); // Set the working dir (choose or set to current buffer)
// sv.r.run(); // Run current selection or line in R and goto next line
// sv.r.runEnter(breakLine = false); // Run current line to pos in R and add a line feed
// sv.r.source(what); // Source various part of current buffer to R
// sv.r.send(what); // Send various part of current buffer to R
// sv.r.addHistory(data, cmd); // Add current command to R's history, used as a procfun in sv.socket.rCommand call
// sv.r.display(topic, what); // Display 'topic' according to 'what' type
// sv.r.helpStart(); // Start R help in the default browser
// sv.r.help(topic, package); // Get help in R for 'topic', 'topic' is facultative
// sv.r.example(topic); // Run example in R for 'topic' (facultative)
// sv.r.search(topic); // Search R help for 'topic'
// sv.r.search_select(topics); // Callback function: display a list of
                               // choices to select help page from
// sv.r.siteSearch(topic); // Search R web sites for 'topic'
// sv.r.dataList(loaded); // List R datasets in "loaded" or "all" packages
// sv.r.data(); // Select one dataset to load
// sv.r.data_select(data); // Callback function for sv.r.data()
// sv.r.browseVignettes(); // Open a web page listing all installed vignettes
// sv.r.saveWorkspace(file, title); // Save data in a .Rdata file
// sv.r.loadWorkspace(file, attach); //  Load the content of a .RData file into the workspace, or attach it
// sv.r.saveHistory(file, title); // Save the history in a file
// sv.r.loadHistory(file, title); // Load the history from a file
// sv.r.saveGraph(type, file, title, height, width, method);
//                         // Save the current R graph in different formats
// sv.r.quit(save);        // Quit R (ask to save in save in not defined)
//
// sv.r.pkg namespace: /////////////////////////////////////////////////////////
// sv.r.pkg.repositories(); // Select repositories for installing R packages
// sv.r.pkg.CRANmirror(); // Select preferred CRAN mirror
// sv.r.pkg.available(); // List available R packages on selected repositories
// sv.r.pkg.installed(); // List installed R packages
// sv.r.pkg.install(); // Install R package(s) from the repositories
//sv.r.pkg.chooseCRANMirror(andInstall); // replacement for .CRANmirror, optionally calls .install after execution

// sv.r.pkg.installLocal(); // Install one or more R packages from local files
// sv.r.pkg.installSV(); // Install the Sciviews bundle from CRAN
// sv.r.pkg.installSVrforge(); // Install development versions of SciViews
                               // from R-Forge
// sv.r.pkg.new(); // List new R packages available on CRAN
// sv.r.pkg.old(); // List older installed R packages than distributed versions
// sv.r.pkg.update(); // Update installed R packages from the repositories
// sv.r.pkg.status(); // Show status of installed R packages
// sv.r.pkg.loaded(); // Show which R packages are loaded
// sv.r.pkg.load(); // Load one R package
// sv.r.pkg.load_select(pkgs); // Callback function for sv.r.pkg.load()
// sv.r.pkg.unload(); // Unload one r package
// sv.r.pkg.unload_select(pkgs); // Callback function for sv.r.pkg.unload()
// sv.r.pkg.remove(); // Remove one R package
// sv.r.pkg.remove_select(pkgs); // Callback function for sv.r.pkg.remove()
////////////////////////////////////////////////////////////////////////////////

// TODO: in overlay: add "source file" context menu item in the project tab



// Define the 'sv.r' namespace
if (typeof(sv.r) == 'undefined')
	sv.r = {
		RMinVersion: "2.7.0",
		sep: ";;"
	};

// TODO: get R encoding after server starts:
//sv.r.init = function(cmd) {
//}

// Evaluate code in R
sv.r.eval = function(cmd) {

	cmd = cmd.trim();
	// Store the current R command
	if (sv.socket.prompt == ":> ") {
		// Special case for q() and quit() => use sv.r.quit() instead
		if (cmd.search(/^q(?:uit)?\s*\(\s*\)$/) > -1) return(sv.r.quit());
		// This is a new command
		sv.socket.cmd = cmd;
	} else {
		// We continue previous multiline command
		//sv.socket.cmd += '\n' + cmd;
		sv.socket.cmd += '' + cmd;
	}
	if (sv.socket.cmdout) {
		if (sv.socket.prompt == ":> ") {
			sv.cmdout.clear();
			sv.cmdout.append(":> " + cmd);
		} else {
			sv.cmdout.append(cmd);
		}
	}
	var res = sv.socket.rCommand('<<<e>>>' + cmd, sv.socket.cmdout, null, sv.r.addHistory, sv.socket.cmd);

	return(res);
}

// Evaluate code in R in a hidden way
sv.r.evalHidden = function(cmd, earlyExit) {
	var preCode = "<<<h>>>";
	if (earlyExit) preCode = "<<<H>>>";
	// Evaluate a command in hidden mode (contextual help, calltip, etc.)
	var res = sv.socket.rCommand(preCode + cmd, false);
	return(res);
}


// Tests:
//sv.r.evalHidden("Sys.sleep(5); cat('done\n')");
//sv.r.evalHidden("Sys.sleep(5); cat('done\n')", earlyExit = true);
//sv.r.evalHidden("Sys.sleep(3); cat('done\n');" +
//   " koCmd('alert(\"koCmd is back\");')", earlyExit = true);

// Evaluate R expression and call procfun in Komodo with the result as argument
// context might be used to pass additional data as the second argument of procfun
sv.r.evalCallback = function(cmd, procfun, context) {
	// Evaluate a command in hidden mode (contextual help, calltip, etc.)
	// and call 'procfun' at the end of the evaluation
	var res = sv.socket.rCommand("<<<h>>>" + cmd, false, null, procfun, context);
	return(res);
}

// Escape R calculation
sv.r.escape = function() {
	// Send an <<<esc>>> sequence that breaks multiline mode
	sv.socket.cmd = "";
	sv.socket.prompt == ":> ";
	if (sv.socket.cmdout) { sv.cmdout.clear(); }
	var listener = { finished: function(data) {} }
	var res = sv.socket.rCommand('<<<esc>>>', false);
	return(res);
}

// Set the current working directory (to current buffer dir, or ask for it)
sv.r.setwd = function (dir, ask, type) {
	// TODO: simplify this:
	// for compatibility with previous versions
	switch (arguments.length) {
		case  1:
			type = dir;
			dir = null;
			ask = false;
		break;
		case 2:
			type = dir;
			dir = null;
		break;
		default:
	}

	var getDirFromR = "";

	if (!dir || (sv.io.fileExists(dir) == 2)) { // if dir doesn't exist or unspecified
		//alert(dir + ":" + type)
		checkType:
		switch (type) {
			case "this":
				break;
			case "session":
				getDirFromR = "getOption(\"R.initdir\")";
				//sv.r.eval(".odir <- setwd(getOption(\"R.initdir\"))");
				break;
			case "previous":
				//sv.r.eval("if (exists(\".odir\")) .odir <- setwd(.odir); getwd()");
				getDirFromR = "if (exists(\".odir\")) .odir else getwd()";
				break;
			case "init":
				//sv.r.eval(".odir <- setwd(getOption(\"R.initdir\"))");
				getDirFromR = "getOption(\"R.initdir\")";
				break;
			case "current":
				getDirFromR = "getwd()";
				ask = true;	// assume  ask is always true in shis case
				break;
			case "file":
				var kv = ko.views.manager.currentView;
				if (kv) {
					kv.setFocus();
					if (!kv.document.isUntitled) {
						// if not, look for current file directory
						dir = kv.document.file.dirName;
					}
					break;
				}
			case "project":
			default:
				dir = "";
				// try to set current project dir ar default directory
				var ap = ko.projects.manager.getCurrentProject();
				var kv = ko.views.manager.currentView;
				if (ap != null) {
					dir = ko.projects.getDefaultDirectory(ap);
				} else {
					type = "file";
					break checkType;
				}
		}
	}

	if (getDirFromR) {
		var cmd = "cat(path.expand(" + getDirFromR + "))";

		sv.r.evalCallback(cmd, function(curDir) {
			if (navigator.platform.search(/^Win/) == 0) {
				curDir = curDir.replace(/\//g, '\\');
			}
			//sv.debugMsg("curDir:"+curDir);
			sv.r.setwd(curDir, ask, "this");
		});
		return;
	}

	if (ask || !dir) {
		dir = ko.filepicker.getFolder(dir, sv.translate("ChooseWorkingDir"));
	}

	if (dir != null) {
		sv.r.evalHidden(".odir <- setwd(\"" + dir.addslashes() + "\")");
		sv.cmdout.message(sv.translate("WorkingDirSetTo", dir), 10000);
	}
    return;
}

// Run current selection or line buffer in R
sv.r.run = function() {
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return false; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		var currentLine = ke.lineFromPosition(ke.currentPos);
		if (ke.selText == "") {
			ke.home();
			ke.lineEndExtend();
			// while ke.selText contains no code, look for next line
			while (ke.selText.replace(/^\s*$/, "") == "") {
				//Are we at the last line?
				currentLine = ke.lineFromPosition(ke.currentPos);
				if( currentLine == ( ke.lineCount - 1 ) )
					return false;
				// Select next line
				ke.lineDown();
				ke.home();
				ke.lineEndExtend();
			}
		}
		var res = sv.r.eval(ke.selText);
		ke.lineDown();
		ke.homeDisplay();
	} catch(e) {
		return e;
	}
	return res;
}

// Run current line up to position and optionally add line feed
sv.r.runEnter = function(breakLine) {
	try {
		var res = false;
		var kv = ko.views.manager.currentView;
		if (!kv)
			return false; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		if (ke.selText == "") {	// Only proceed if selection is empty
			// get text from a line and move caret to the eol
			// do we want to break line here or execute it to the end?
			var text = sv.getTextRange(breakLine? "linetobegin" : "line", true);

			ko.commands.doCommand('cmd_newlineExtra');
			if (text != "") res = sv.r.eval(text);
		}
	} catch(e) {
		return e;
	}
	return res;
}

// Source the current buffer or some part of it
sv.r.source = function(what) {
	var res = false;
	try {
		var kv = ko.views.manager.currentView;
		if (!kv)
			return false; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		var doc = kv.document;

		var file;
		if (!doc.isUntitled) {
			file = doc.file.path.addslashes();
		} else {
			file = doc.baseName;
		}

		if (!what)
			what = "all"; // Default value

		// Special case: if "all" and document is saved, source the original file
		if (what == "all" && !(doc.isUntitled || doc.isDirty)) {
			res = sv.r.eval('source("' + file +  '", encoding = "' + kv.encoding + '")');
		} else {

			// else, save all or part in the temporary file and source that file.
			// After executing, tell R to delete it.
			var code = (what == "all")? ke.text : sv.getTextRange(what);
			sv.cmdout.clear();
			sv.cmdout.append(':> #source("' + file + '*") # unsaved buffer (' + what + ')');

			var tempFile = sv.io.tempFile();
			sv.io.writefile(tempFile, code, 'utf-8', false);
			tempFile = tempFile.addslashes();

			var cmd = 'tryCatch(source("' + tempFile + '", encoding = "utf-8"), finally = {unlink("' + tempFile + '")});';

			sv.r.evalCallback(cmd, function(data) {
				sv.cmdout.append(sv.tools.strings.removeLastCRLF(data));
				sv.cmdout.append(":>");
			});
		}
	} catch(e) {
		alert(e);
	}
	return res;
}

// Send whole or a part of the current buffer to R
// place cursor at next line
sv.r.send = function(what) {
	//sv.cmdout.message("sv.r.send "+what, 3000);
	//alert("sv.r.send "+what);
	var res = false;
	var kv = ko.views.manager.currentView;
	if (!kv)
		return false; // No current view, do nothing!
	kv.setFocus();
	var ke = kv.scimoz;

	try {
		if (!what)
			what = "all"; // Default value

		var code = sv.getTextRange(what, true);
		if (code) {
			// indent multiline commands
			code = code.replace(/\r?\n/g, "\n   ")
			res = sv.r.eval(code);
		}
		if (what == "line" || what == "linetoend") // || what == "para"
			ke.charRight();

	} catch(e) {
		return e;
	}
	return res;
}

// Add current command to R's history,
// used as a procfun in sv.socket.rCommand call
sv.r.addHistory = function(data, cmd) {
	if (sv.socket.prompt == ":> ") {
		var quotedCmd = cmd.trim();
		quotedCmd = quotedCmd.replace(/([\\"'])/g, "\\$1").replace(/[\r\n]+/, "\\n").replace("\t", " ");

		sv.socket.rCommand("<<<H>>>" + ".sv.tmp <- strsplit(\"" + quotedCmd + "\", \"\\\\s*([\\r\\n]|<<<n>>>)+\\\\s*\", perl = T)[[1]]; .sv.tmp <- .sv.tmp[.sv.tmp != \"\"]; lapply(.sv.tmp, function(x) {.Internal(addhistory((x))) }); rm(.sv.tmp);", false);
	}
}

// Display R objects in different ways
// TODO: allow custom methods + arguments + forcevisible + affect to var
sv.r.display = function(topic, what) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		//alert("Nothing is selected!");
	} else {
		// Display data in different ways, depending on what
		switch(what) {
		 case "names":
			res = sv.r.eval("names(" + topic + ")");
			break;
		 case "structure":
			res = sv.r.eval("str(" + topic + ")");
			break;
		 case "summary":
			res = sv.r.eval("summary(" + topic + ")");
			break;
		 case "plot":
			res = sv.r.eval("plot(" + topic + ")");
			break;
		 case "content":
		 case "print":
		 case "show":
		 default:
			res = sv.r.eval(topic);
		}
	}
	return(res);
}

// Start R help in the default browser
sv.r.helpStart = function() {
	var res = sv.r.eval("help.start()");
	ko.statusBar.AddMessage(sv.translate("RHelpStarted"), "R", 5000, true);
	return(res);
}

// Get help in R (HTML format)
sv.r.help = function(topic, pkg) {
	var res = false;
	if (!topic && !pkg) {
		if (typeof(topic) == "undefined" || topic == "")
			topic = sv.getText();

		if (topic == "") {
			// let's not cry so much about an empty selection
			ko.statusBar.AddMessage(sv.translate("SelectionEmpty"), "R", 1000, false);
			//alert("Nothing is selected!");
		}

	} else {
		var cmd = '';

		cmd += pkg? ' package = "' + pkg + '", ' : "";
		cmd += topic? ' topic = "' + topic + '", ' : "";

		cmd = 'cat(unclass(help(' + cmd + ' htmlhelp = TRUE)))';

		// TODO: error handling when package does not exists
		res = sv.r.evalCallback(cmd, sv.browseURI);

		ko.statusBar.AddMessage(sv.translate("RHelpAskedFor", topic),
			"R", 5000, true);

	}
	return(res);
}

// Run the example for selected item
sv.r.example = function(topic) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		//alert("Nothing is selected!");
	} else {
		res = sv.r.eval("example(" + topic + ")");
		ko.statusBar.AddMessage(sv.translate("RExampleFor", topic),
			"R", 5000, true);
	}
	return(res);
}

// Search R help for topic
sv.r.search = function(topic, internal) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	// Ask for the search string
	topic = ko.dialogs.prompt(sv.translate("Search_R_objects_using_a_regular_expression"),
							  sv.translate("Pattern"), topic,
							  sv.translate("Search_R_help"), "okRsearchPattern");
	if (topic != null & topic != "") {
		// Get list of matching items and evaluate it with sv.r.search_select()
		res = sv.r.evalCallback('cat(apropos("' + topic + '"), sep = "' + sv.r.sep + '")',
			sv.r.search_select);
		ko.statusBar.AddMessage(sv.translate("Searching_R_help_for", topic),
			"R", 5000, true);
	}
	return(res);
}

// The callback for sv.r.search
sv.r.search_select = function(topics) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(topics) == "") {
		sv.cmdout.message(sv.translate("No_item_found_in_R_help"));
	} else {	// Something is returned
		var items = topics.split(sv.r.sep);
		if (items.length == 1) {
			// Only one item, show help for it
			res = sv.r.help(sv.tools.strings.removeLastCRLF(topics));
		} else {
			// Select the item you want in the list
			var topic = ko.dialogs.selectFromList("R help",
				"Select a topic:", items, "one");
			if (topic != null)
				res = sv.r.help(sv.tools.strings.removeLastCRLF(topic.join("")));
		}
	}
	return(res);
}


// Search R web sites for topic
sv.r.siteSearch = function(topic) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		//alert("Nothing is selected!");
	} else {
		res = sv.r.evalHidden('RSiteSearch("' + topic + '")', earlyExit = true);
		ko.statusBar.AddMessage("R site search asked for '" + topic + "'",
			"R", 5000, true);
	}
	return(res);
}

// List available datasets ("loaded" or not defined = loaded packages, or "all")
sv.r.dataList = function(which) {
	var res = false;
	if (typeof(which) == "undefined" | which == "" | which == "loaded") {
		var res = sv.r.eval('data()');
	} else {	// which == "all"
		var res = sv.r.eval('data(package = .packages(all.available = TRUE))');
	}
	return(res);
}

// Load one R dataset
sv.r.data = function() {
	var res = false;
	// Get list of all datasets
	res = sv.r.evalCallback('.tmp <- data();' +
		'cat(paste(.tmp$results[, "Item"], .tmp$results[, "Title"], sep = "\t  -  "), sep = "\n");' +
		'rm(.tmp)', sv.r.data_select);
	ko.statusBar.AddMessage("Listing available R datasets... please wait",
		"R", 20000, true);
	return(res);
}

// The callback for sv.r.data
sv.r.data_select = function(data) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(data) == "") {
		alert("Problem retrieving the list of R datasets!");
	} else {	// Something is returned
		var items = data.split("\n");
		// Select the item you want in the list
		var item = ko.dialogs.selectFromList("R Datasets",
			"Select one R dataset:", items, "one");
		if (item != null) {
			// We need to eliminate the definition
			var dat = item[0].split("\t");
			var datname = dat[0];
			// Sometimes, we got 'item (data)' => retrieve 'data' in this case
			datname = datname.replace(/^[a-zA-Z0-9._ ]*[(]/, "");
			datname = datname.replace(/[)]$/, "");
			res = sv.r.eval('data(' + datname + ')');
		}
	}
	return(res);
}

// Open a menu with all installed vignettes in the default web browser
sv.r.browseVignettes = function() {
	var res = sv.r.eval('browseVignettes()');
	return(res);
}

// Save the content of the workspace in a file
sv.r.saveWorkspace = function(file, title) {
  // Ask for the filename if not provided
  if (typeof(file) == "undefined") {
	if (typeof(title) == "undefined") { title = 'Save the R workspace in a file'; }
	file = ko.filepicker.saveFile("", ".RData", title);
	if (file == null) return;	// User clicked cancel
  }
  sv.r.eval('save.image("' + file + '")');
}


// Load the content of a .RData file into the workspace, or attach it
sv.r.loadWorkspace = function(file, attach) {
  // Ask for the filename if not provided
	if (!file) {
		file = sv.fileOpen("", ".RData", sv.translate("Browse_for_workspace"),
		      [sv.translate("R_workspace") + " (*.RData)|*.RData"], true);
	} else if (typeof files == "string") {
		file = file.split(/[;,]/);
	}
	if (!file || !file.length)
	      return;

	var load = attach?  "attach" : "load";

	var cmd = [];
	for (var i in file)
		cmd[i] = load + "(\"" + file[i].addslashes() + "\")";
	sv.r.eval(cmd.join("\n"));
}

// Save the history in a file
sv.r.saveHistory = function(file, title) {
  // Ask for the filename if not provided
  if (typeof(file) == "undefined") {
	if (typeof(title) == "undefined") { title = 'Save the command history in a file'; }
	file = ko.filepicker.saveFile("", ".Rhistory", title);
	if (file == null) return;	// User clicked cancel
  }
  sv.r.eval('savehistory("' + file.addslashes() + '")');
}

// Load the history from a file
sv.r.loadHistory = function(file, title) {
  // Ask for the filename if not provided
  if (typeof(file) == "undefined") {
	if (typeof(title) == "undefined") { title = 'Load the history from a file'; }
	file = ko.filepicker.openFile("", ".Rhistory", title);
	if (file == null) return;	// User clicked cancel
  }
  sv.r.eval('loadhistory("' + file.addslashes() + '")');
}

// There is also dev.copy2pdf() copy2eps() + savePlot windows and X11(type = "Cairo")
sv.r.saveGraph = function(type, file, title, height, width, method) {
  if (typeof(type) == "undefined") { type = "png256"; }
  // Get the file extension according to type
  var ext = type.substring(0, 4);
  if (ext != "pgnm" & ext != "tiff" & ext != "jpeg") { ext = ext.substring(0, 3); }
  if (ext.substring(0, 2) == "ps") { ext = "ps"; }
  if (ext == "jpeg") { ext = "jpg" }
  if (typeof(height) == "undefined") { height = 'dev.size()[2]'; }
  if (typeof(width) == "undefined") { width = 'dev.size()[1]'; }
  if (typeof(method) == "undefined") { method = "pdf"; }
  // Ask for the filename if not provided
  if (typeof(file) == "undefined") {
	if (typeof(title) == "undefined") { title = 'Save the graph as "' + type + '"'; }
	file = ko.filepicker.saveFile("", "Rplot." + ext, title);
	if (file == null) return;	// User clicked cancel
  }
  // Save the current device in R using dev2bitmap()... needs gostscript!
  sv.r.eval('dev2bitmap("' + file.addslashes() + '", type = "' + type + '", height = ' + height +
	', width = ' + width + ', method = "' + method + '")');
}

sv.r.quit = function(save) {
  if (typeof(save) == "undefined") {
	// Ask for saving or not
	var response = ko.dialogs.customButtons("Do you want to save the workspace (.RData) " +
	  "and the command history (.Rhistory) in the session directory first?",
	  ["Yes", "No", "Cancel"], // buttons
	  "No", // default response
	  null, // text
	  "Exiting R"); // title
	  if (response == "Cancel") { return; }
  }
  sv.r.eval('q("' + response.toLowerCase() + '")');
}

// Define the 'sv.r.pkg' namespace /////////////////////////////////////////////
if (typeof(sv.r.pkg) == 'undefined') sv.r.pkg = new Object();

// List available packages on the selected repositories
sv.r.pkg.available = function() {
	var res = sv.r.eval('.pkgAvailable <- available.packages()\n' +
		'as.character(.pkgAvailable[, "Package"])');
	ko.statusBar.AddMessage("Looking for available R packages... please wait",
		"R", 5000, true);
	return(res);
}

// List installed packages
sv.r.pkg.installed = function() {
	var res = sv.r.eval('.pkgInstalled <- installed.packages()\n' +
		'as.character(.pkgInstalled[, "Package"])');
	ko.statusBar.AddMessage("Looking for installed R packages... please wait",
		"R", 5000, true);
	return(res);
}

// List new packages in the repositories
sv.r.pkg.new = function() {
	var res = sv.r.eval('(.pkgNew <- new.packages())');
	ko.statusBar.AddMessage("Looking for new R packages... please wait",
		"R", 5000, true);
	return(res);
}

// List installed packages which are older than those in repositories (+ versions)
sv.r.pkg.old = function() {
	var res = sv.r.eval('.pkgOld <- old.packages()\n' +
		'noquote(.pkgOld[, c("Installed", "ReposVer")])');
	ko.statusBar.AddMessage("Looking for old R packages... please wait",
		"R", 5000, true);
	return(res);
}

// Update installed packages
sv.r.pkg.update = function() {
	var res = sv.r.eval('update.packages(ask = "graphics")');
	ko.statusBar.AddMessage("Updating R packages... please wait",
		"R", 5000, true);
	return(res);
}

// Some statistics about R packages
sv.r.pkg.status = function() {
	var res = sv.r.eval('(.pkgStatus <- packageStatus())');
	ko.statusBar.AddMessage("Compiling R packages status... please wait",
		"R", 5000, true);
	return(res);
}

// Which R packages are currently loaded?
sv.r.pkg.loaded = function() {
	var res = sv.r.eval('(.packages())');
	return(res);
}

// Load one R package
sv.r.pkg.load = function() {
	var res = false;
	ko.statusBar.AddMessage(sv.translate("ListingPackages"),
		"R", 20000, true);

	// Get list of installed R packages that are not loaded yet
	res = sv.r.evalCallback('.tmp <- .packages(all.available = TRUE);' +
		'cat(.tmp[!.tmp %in% .packages()], sep = "' + sv.r.sep + '"); rm(.tmp)',
		function(pkgs) {
			ko.statusBar.AddMessage("", "R");
			var res = false;
			if (pkgs.trim() == "") {
				alert("All installed R packages seem to be already loaded!");
			} else {	// Something is returned
				var items = pkgs.split(sv.r.sep);
				// Select the item you want in the list
				var topic = ko.dialogs.selectFromList(sv.translate("titleLoadPackage"),
					sv.translate("SelectPkgToLoad") + ":", items);
				if (topic != null) {
					res = sv.r.evalCallback('cat(paste(lapply(c("' + topic.join('", "') + '"), function(pkg) {	res <- try(library(package = pkg, character.only = TRUE)); 	paste ("Package", sQuote(pkg), if (inherits(res, "try-error")) "could not be loaded"  else "loaded")	}), collapse = "\\n"), "\\n")',
									sv.cmdout.append);

				}
			}
			return(res);
		});

	return(res);
}

// Unload one R package
sv.r.pkg.unload = function() {
	var res = false;
	// Get list of loaded packages, minus required ones we cannot unload

	res = sv.r.evalCallback('.tmp <- .packages();' +
		'cat(.tmp[!.tmp %in% c(if (exists(".required")) .required else NULL, "base")], sep = "' + sv.r.sep + '"); rm(.tmp)',
		sv.r.pkg.unload_select);
	ko.statusBar.AddMessage("Listing loaded R packages... please wait",
		"R", 20000, true);
	return(res);
}

// The callback for sv.r.pkg.unload
sv.r.pkg.unload_select = function(pkgs) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		alert("None of the loaded packages are safe to unload!");
	} else {	// Something is returned
		var items = pkgs.split(sv.r.sep);
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Unload R package",
			"Select one R package to unload:", items, "one");
		if (topic != null) {
            res = sv.r.eval("detach(\"package:" + topic[0].trim()+ "\")");
		}
	}
	return(res);
}

// Remove one R package
sv.r.pkg.remove = function() {
	var res = false;
	// Get list of all packages, minus required and recommended ones we cannot remove
	res = sv.r.evalCallback('.tmp <- installed.packages(); ' +
		'.tmp <- rownames(.tmp)[is.na(.tmp[, "Priority"])]; ' +
		'cat(.tmp[!.tmp %in% c(if (exists(".required")) .required else NULL, "svMisc", "svIDE", "svGUI", "svSocket", "svIO", "svViews", "svWidgets", "svDialogs")], sep = "' + sv.r.sep + '"); rm(.tmp)',
		sv.r.pkg.remove_select);
	ko.statusBar.AddMessage("Listing removable R packages... please wait",
		"R", 20000, true);
	return(res);
}

// The callback for sv.r.pkg.remove
sv.r.pkg.remove_select = function(pkgs) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		alert("None of the installed R packages are safe to remove!");
	} else {	// Something is returned
		var items = pkgs.split(sv.r.sep);
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Remove R package",
			"Select one R package to remove:", items, "one");
		if (topic != null) {
			var pkg = (sv.tools.strings.removeLastCRLF(topic.join('')));
			var response = ko.dialogs.customButtons("You are about to remove the '" +
				pkg + "' R package from disk! Are you sure?",
				["&Continue...", "Cancel"], // buttons
				"Continue...", // default response
				null, // text
				"Removing an R package"); // title
			if (response == "Cancel") { return res; }

			res = sv.r.eval('remove.packages("' + pkg +
				'", lib = installed.packages()["' + pkg + '", "LibPath"])');
		}
	}
	return(res);
}

// Select repositories
// TODO: a Komodo version of this that returns pure R code
sv.r.pkg.repositories = function() {
	var res = sv.r.eval('setRepositories(TRUE)');
	return(res);
}

// Select CRAN mirror
sv.r.pkg.CRANmirror = function() {
	sv.r.pkg.chooseCRANMirror(false);
}

sv.r.pkg.install = function(isCRANMirrorSet) {
	var res = false;
	if (!isCRANMirrorSet) {
		res = sv.r.evalCallback("cat(getOption(\"repos\")[\"CRAN\"])",
			function(cran) {
					var res = false;
					if (cran.trim() == "@CRAN@") {
						res = sv.r.pkg.chooseCRANMirror("install");
					} else {
						res = sv.r.pkg.install(true);
					}
					return (res);
			}
		);

	} else {
		ko.statusBar.AddMessage(sv.translate("ListingPackages"),
				"R", 20000, true);
		res = sv.r.evalCallback('cat(available.packages()[,1], sep="' + sv.r.sep + '")',
				function(pkgs) {
					ko.statusBar.AddMessage("", "R");
					var res = false;
					if (pkgs.trim() == "") {
						alert("Error?"); // TODO: remove this later
					} else {
						var items = pkgs.split(sv.r.sep);
						items = ko.dialogs.selectFromList(sv.translate("titleInstallPackage"),
							sv.translate("SelectPkgsToInstall") + ":", items);

						if (items != null) {
							items = '"' + items.join('", "') + '"';
							ko.statusBar.AddMessage(sv.translate("InstallingPkgs"), "R");
							sv.socket.rCommand("install.packages(c(" + items + "))",
								true, null, function(data) {
									ko.statusBar.AddMessage("", "R");
								}
							);
						}
					}
					return(res);
				}
		);
	}
	return(res);
}


// replacement for .CRANmirror, optionally calls .install after execution
sv.r.pkg.chooseCRANMirror = function(andInstall) {
	var res = false;
	res = sv.r.evalCallback(
		'.sv.tmp <- getCRANmirrors(all = FALSE, local.only = FALSE);cat(.sv.tmp$Name[.sv.tmp$OK == 1], sep="' + sv.r.sep + '"); rm(.sv.tmp)',
		function(repos) {
			ko.statusBar.AddMessage("", "R");
			var res = false;

			if (repos.trim() == "") {
				alert("Error getting CRAN Mirrors list.");
			} else {
				var items = repos.split(sv.r.sep);
				items = ko.dialogs.selectFromList(sv.translate("CRANMirrors"),
					sv.translate("SelectCRANMirror"), items, "one");

				if (items != null) {
					res = sv.r.evalCallback(".sv.tmp <- getCRANmirrors(all = FALSE, local.only = FALSE); .sv.repos <- getOption(\"repos\"); .sv.repos[\"CRAN\"] <- gsub(\"/$\", \"\", .sv.tmp$URL[.sv.tmp$Name == \"" + items[0] + "\"]); options(repos =.sv.repos); rm(.sv.repos, .sv.tmp); cat(getOption(\"repos\")['CRAN']);",
						function(url) {
							ko.statusBar.AddMessage(sv.translate("CRANMirrorSetTo", url), "R", 5000, false);
							if (andInstall)
								sv.r.pkg.install(true);
						},
						andInstall);
				}
			}
			return(res);
		}
	);
	ko.statusBar.AddMessage(sv.translate("RetrievingCRANMirrors"),
		"R", 20000, true);
	return(res);
}

// Install R packages from local zip files
// TODO: set filter for R package files!
// TODO: use R CMD INSTALL instead + R CMD BUILD (--binary) + R CMD REMOVE
sv.r.pkg.installLocal = function() {
	var res = false;
	// Get list of files to install
	//var files = ko.filepicker.openFiles(null, null,
	//	"Select R package(s) to install (.tar.gz, .zip or .tgz)");

	var files = sv.fileOpen(null, null, sv.translate("SelectPkgsToInstall"),
		['Zip archive (*.zip)|*.zip', 'Gzip archive (*.tgz;*.tar.gz)|*.tgz;*.tar.gz'], true);


	if (files != null) {
		var cmd = "install.packages("

		if (typeof(files) == "object") {
			cmd += 'c("' + files.join('", "').addslashes() + '")';
		} else {
			cmd += '"' + files.addslashes() + '"';
		}
		cmd += ', repos = NULL)';

		res = sv.r.eval(cmd);
		ko.statusBar.AddMessage(sv.translate("InstallingPackages"),
			"R", 5000, true);
	}
	return(res);
}

// Install the SciViews bundle from CRAN
sv.r.pkg.installSV = function() {
	var res = false;
	var response = ko.dialogs.customButtons("Currently, CRAN hosts an old, incompatible\n" +
		"version of the SciViews-R bundle.\nInstall it anyway?",
		["&Continue...", "Cancel"], // buttons
		"Continue...", // default response
		null, // text
		"Install the SciViews-R bundle from CRAN"); // title
	if (response == "Cancel") { return res; }
	res = sv.r.eval('install.packages("SciViews")');
	ko.statusBar.AddMessage("Installing SciViews R bundle... please wait",
		"R", 5000, true);
	return(res);
}

// Install the latest development version of Sciviews packages from R-Forge
sv.r.pkg.installSVrforge = function() {
	var res = false;
	var response = ko.dialogs.customButtons("R-Forge distributes latest development\n" +
		"version of the SciViews-R bundle.\nThis is NOT the lastest stable one!\nInstall it anyway?",
		["&Continue...", "Cancel"], // buttons
		"Continue...", // default response
		null, // text
		"Install the SciViews-R bundle from R-Forge"); // title
	if (response == "Cancel") { return res; }
	res = sv.r.eval('install.packages(c("svMisc", "svSocket", "svGUI", "svIDE"), repos = "http://R-Forge.R-project.org")');
	ko.statusBar.AddMessage("Installing SciViews R packages from R-Forge... please wait",
		"R", 5000, true);
	return(res);
}

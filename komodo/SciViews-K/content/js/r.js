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
// sv.r.runEnter(); // Run current line to pos in R and add a line feed
// sv.r.source(what); // Source various part of current buffer to R
// sv.r.send(what); // Send various part of current buffer to R
// sv.r.display(topic, what); // Display 'topic' according to 'what' type
// sv.r.helpStart(); // Start R help in the default browser
// sv.r.help(topic); // Get help in R for 'topic', 'topic' is facultative
// sv.r.example(topic); // Run example in R for 'topic' (facultative)
// sv.r.search(topic); // Search R help for 'topic'
// sv.r.search_select(topics); // Callback function: display a list of
                               // choices to select help page from
// sv.r.siteSearch(topic); // Search R web sites for 'topic'
// sv.r.dataList(loaded); // List R datasets in "loaded" or "all" packages
// sv.r.data(); // Select one dataset to load
// sv.r.data_select(data); // Callback function for sv.r.data()
// sv.r.saveGraph(type, file, title, height, width, method);
//                         // Save the current R graph in different formats
// sv.r.quit(save);        // Quit R (ask to save in save in not defined)
//
// sv.r.pck namespace: /////////////////////////////////////////////////////////
// sv.r.pkg.repositories(); // Select repositories for installing R packages
// sv.r.pkg.CRANmirror(); // Select preferred CRAN mirror
// sv.r.pkg.available(); // List available R packages on selected repositories
// sv.r.pkg.installed(); // List installed R packages
// sv.r.pkg.install(); // Install one R package from the repositories
// sv.r.pkg.install_select(pkgs); // Callback function for sv.r.pkg.install()
// sv.r.pkg.installDef(); // Call the default package installation routine of R
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

// Define the 'sv.r' namespace
if (typeof(sv.r) == 'undefined') sv.r = { RMinVersion: "2.7.0" };

// Evaluate code in R
sv.r.eval = function(cmd) {
	// Store the current R command
	if (sv.socket.prompt == ":> ") {
		// Special case for q() and quit() => use sv.r.quit() instead
		if (cmd == "q()" | cmd == "quit()") return(sv.r.quit());
		// This is a new command
		sv.socket.cmd = cmd;
	} else {
		// We continue previous multiline command
		sv.socket.cmd += '\n' + cmd;
	}
	if (sv.socket.cmdout) {
		if (sv.socket.prompt == ":> ") {
			sv.cmdout.clear();
			sv.cmdout.append(":> " + cmd);
		} else {
			sv.cmdout.append(cmd);
		}
	}
	var res = sv.socket.rCommand('<<<e>>>' + cmd, sv.socket.cmdout);
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
sv.r.setwd = function(ask) {
	var res = false;
	if (ask == null) {
		// Set R working directory to current buffer path
		var kv = ko.views.manager.currentView;
		if (!kv) return; // No current view, do nothing!
		kv.setFocus();
		if(kv.document.isUntitled) {
			alert("File is not saved yet. Unable to get its directory!");
		} else {
			// Make sure path name is in Unix convention under Windows
			res = sv.r.eval('.odir <- setwd("' +
				kv.document.file.dirName.replace(/\\/g, "//") + '")');
		}
	} else if (ask == "previous") {
		// Produce an error in R if .odir is not defined, but it is fine!
		res = sv.r.eval('if (exists(".odir")) .odir <- setwd(.odir); getwd()');
	} else {
		// TODO: a graphical setwd()
		alert("Graphical selection of R working dir... not implemented yet!");
	}
	return(res);
}

// Run current selection or line buffer in R
sv.r.run = function() {
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return; // No current view, do nothing!
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
				if( currentLine == ( ke.lineCount - 1 ) ) { return; }
				// Select next line
				ke.lineDown();
				ke.home();
				ke.lineEndExtend();
			}
		}
		var res = sv.r.eval(ke.selText);
		ke.lineDown();
		ke.homeDisplay();
	} catch(e) { return(e); }
	return(res);
}

// Run current line up to position and add line feed
sv.r.runEnter = function() {
	try {
		var res = false;
		var kv = ko.views.manager.currentView;
		if (!kv) return; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		if (ke.selText == "") {	// Only proceed if selection is empty
			var pos = ke.currentPos;
			ke.homeExtend();
			if (ke.selText != "") res = sv.r.eval(ke.selText);
			// Add a line feed at pos
			ke.gotoPos(pos);
			ke.newLine();
		}
	} catch(e) { return(e); }
	return(res);
}

// Source the whole content of the current buffer
sv.r.source = function(what) {
	var res = false;
	try {
		var kv = ko.views.manager.currentView;
		if (!kv) return; // No current view, do nothing!
		kv.setFocus();
		var ke = kv.scimoz;
		if (what == null) what = "all"; // Default value
		// Special case: if "all", then, try sourcing the original file directly
		// (if saved, or ask to save it)
		if (what == "all") {
			// Is this file saved?
			if (kv.document.isUntitled) {
				var answer = ko.dialogs.okCancel("File has not been saved" +
					" yet. Would you like to save it now?", "OK");
				if (answer == "OK") {
					ko.commands.doCommand('cmd_save');
					// Check if it saved now
					if (!kv.document.isDirty) {
						// Source it (make sure its name is in Unix convention
						// under Windows)
						res = sv.r.eval('source("' +
							kv.document.file.path.replace(/\\/g, "//") + '")');
						ko.statusBar.AddMessage("Document sourced in R...",
							"R", 5000, true);
					}
				}
			} else if (kv.document.isDirty) { // Are last changes saved?
				var answer = ko.dialogs.okCancel("Changes have not been saved" +
					" yet. Would you like to save now?", "OK");
				if (answer == "OK") {
					ko.commands.doCommand('cmd_save');
					// Check if it saved now
					if (!kv.document.isDirty) {
						// Source it (make sure its name is in Unix convention
						// under Windows)
						res = sv.r.eval('source("' +
							kv.document.file.path.replace(/\\/g, "//") + '")');
						ko.statusBar.AddMessage("Document sourced in R...",
							"R", 5000, true);
					}
				}
			} else {
				// The document is saved => proceed with sourcing it
				// (make sure its name is in Unix convention under Windows)
				res = sv.r.eval('source("' +
					kv.document.file.path.replace(/\\/g, "//") + '")');
				ko.statusBar.AddMessage("Document sourced in R...",
					"R", 5000, true);
			}
		}
		// We will make a copy of the selected code in a temp file
		// and source it in R
		var code = sv.getPart(what, what != "all", true); // Copy to clipboard
		res = sv.r.eval('clipsource()');
		// If not selected all, para or block, then, change position
		if (what != "all" & what != "para" & what != "block") {
			var kv = ko.views.manager.currentView;
			kv.setFocus();
			var ke = kv.scimoz;
			ke.lineDown();
			ke.homeDisplay();
		}
	} catch(e) { return(e); }
	return(res);
}

// Send whole or a part of the current buffer to R, place cursor at next line
sv.r.send = function(what) {
	try {
		if (what == null) what = "all"; // Default value
		var code = sv.getPart(what, what != "all"); // Change sel if not 'all'
		var res = sv.r.eval(code);
		// If not selected all, para or block, then, change position
		if (what != "all" & what != "para" & what != "block") {
			var kv = ko.views.manager.currentView;
			kv.setFocus();
			var ke = kv.scimoz;
			ke.lineDown();
			ke.homeDisplay();
		}
	} catch(e) { return(e); }
	return(res);
}

// Display R objects in different ways
// TODO: allow custom methods + arguments + forcevisible + affect to var
sv.r.display = function(topic, what) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		alert("Nothing is selected!");
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
	ko.statusBar.AddMessage("R help started... should display in browser soon",
		"R", 5000, true);
	return(res);
}

// Get help in R (HTML format)
sv.r.help = function(topic) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		alert("Nothing is selected!");
	} else {
		res = sv.r.evalCallback('cat(unclass(help("' + topic +
			'", htmlhelp = TRUE)))', sv.browseURI);
		ko.statusBar.AddMessage("R help asked for '" + topic + "'",
			"R", 5000, true);
	}
	return(res);
}

// Run the example for selected item
sv.r.example = function(topic) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	if (topic == "") {
		alert("Nothing is selected!");
	} else {
		res = sv.r.eval("example(" + topic + ")");
		ko.statusBar.AddMessage("R example run for '" + topic + "'",
			"R", 5000, true);
	}
	return(res);
}

// Search R help for topic
sv.r.search = function(topic, internal) {
	var res = false;
	if (typeof(topic) == "undefined" | topic == "") topic = sv.getText();
	// Ask for the search string
	topic = ko.dialogs.prompt("Search R objects using a regular expression" +
		" (e.g., '^log' for objects starting with 'log')",
		"Pattern", topic, "Search R help", "okRsearchPattern");
	if (topic != null & topic != "") {
		// Get list of matching items and evaluate it with sv.r.search_select()
		res = sv.r.evalCallback('cat(apropos("' + topic + '"), sep = "\n")',
			sv.r.search_select);
		ko.statusBar.AddMessage("Searching R help for '" + topic + "'",
			"R", 5000, true);
	}
	return(res);
}

// The callback for sv.r.search
sv.r.search_select = function(topics) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(topics) == "") {
		alert("No item found in R help!");
	} else {	// Something is returned
		var items = topics.split("\n");
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
		alert("Nothing is selected!");
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
  sv.r.eval('dev2bitmap("' + file + '", type = "' + type + '", height = ' + height +
	', width = ' + width + ', method = "' + method + '")');
}

sv.r.quit = function(save) {
  if (typeof(save) == "undefined") {
	// Ask for saving or not
	var response = ko.dialogs.customButtons("Do you want to save the workspace (.RData) " +
	  "and the command history (.Rhistory) in the current directory first?",
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
	// Get list of installed R packages that are not loaded yet
	res = sv.r.evalCallback('.tmp <- .packages(all.available = TRUE);' +
		'cat(.tmp[!.tmp %in% .packages()], sep = "\n"); rm(.tmp)',
		sv.r.pkg.load_select);
	ko.statusBar.AddMessage("Listing available R packages... please wait",
		"R", 20000, true);
	return(res);
}

// The callback for sv.r.pkg.load
sv.r.pkg.load_select = function(pkgs) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		alert("All installed R packages seem to be already loaded!");
	} else {	// Something is returned
		var items = pkgs.split("\n");
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Load R package",
			"Select one R package to load:", items, "one");
		if (topic != null) {
			res = sv.r.eval('library(' +
				(sv.tools.strings.removeLastCRLF(topic.join(''))) + ')');
		}
	}
	return(res);
}

// Unload one R package
sv.r.pkg.unload = function() {
	var res = false;
	// Get list of loaded packages, minus required ones we cannot unload
	res = sv.r.evalCallback('.tmp <- .packages();' +
		'cat(.tmp[!.tmp %in% c(.required, "base")], sep = "\n"); rm(.tmp)',
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
		var items = pkgs.split("\n");
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Unload R package",
			"Select one R package to unload:", items, "one");
		if (topic != null) {
			res = sv.r.eval('detach("package:' +
				(sv.tools.strings.removeLastCRLF(topic.join(''))) + '")');
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
		'cat(.tmp[!.tmp %in% c(.required, "svMisc", "svIDE", "svGUI", "svSocket", "svIO", "svViews", "svWidgets", "svDialogs")], sep = "\n"); rm(.tmp)',
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
		var items = pkgs.split("\n");
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

// Install one R package
// TODO: allow installing more than one package at a time
sv.r.pkg.install = function() {
	var res = false;
	// Get list of all packages, minus required and recommended ones we cannot remove
	res = sv.r.evalCallback('cat(rownames(available.packages()), sep = "\n")',
		sv.r.pkg.install_select);
	ko.statusBar.AddMessage("Listing available R packages... please wait",
		"R", 60000, true);
	return(res);
}

// The callback for sv.r.pkg.install
sv.r.pkg.install_select = function(pkgs) {
	ko.statusBar.AddMessage("", "R");
	var res = false;
	if (sv.tools.strings.removeLastCRLF(pkgs) == "") {
		alert("Don't find available R packages!");
	} else {	// Something is returned
		var items = pkgs.split("\n");
		// Select the item you want in the list
		var topic = ko.dialogs.selectFromList("Install R package",
			"Select one R package to install:", items, "one");
		if (topic != null) {
			var pkg = (sv.tools.strings.removeLastCRLF(topic.join('')));
			res = sv.r.eval('install.packages("' + pkg + '")');
			ko.statusBar.AddMessage("Install package and dependencies... please wait",
				"R", 60000, true);
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
// TODO: a Komodo version of this that returns pure R code
sv.r.pkg.CRANmirror = function() {
	var res = sv.r.eval('chooseCRANmirror(TRUE)');
	return(res);
}

// Install packages (the default R version)
// TODO: merge this with sv.r.pkg.install, but allow more than one package
sv.r.pkg.installDef = function() {
	var res = false;
	res = sv.r.eval('install.packages()');
	ko.statusBar.AddMessage("Listing available R packages... please wait",
		"R", 5000, true);
	return(res);
}

// Install R packages from local zip files
// TODO: set filter for R package files!
// TODO: use R CMD INSTALL instead + R CMD BUILD (--binary) + R CMD REMOVE
sv.r.pkg.installLocal = function() {
	var res = false;
	// Get list of files to install
	var files = ko.filepicker.openFiles(null, null,
		"Select R package(s) to install (.tar.gz, .zip or .tgz)");
	if (files != null) {
		var cmd = "install.packages("
		if (files.length == 1) {
			cmd += '"' + files.join("") + '", repos = NULL)';
		} else {
			cmd += 'c("' + files.join('", "') + '", repos = NULL))';
		}
		res = sv.r.eval(cmd);
		ko.statusBar.AddMessage("Installing R package(s)... please wait",
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

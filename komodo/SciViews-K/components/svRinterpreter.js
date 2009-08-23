// SciViews-K R interpreter XPCOM
// Define functions to pilot R from Komodo Edit
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org) et al.
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// In Javascript:
// var R = Components.classes["@sciviews.org/svRinterpreter;1"]
//			.getService(Components.interfaces.svIRinterpreter);
// In Python:
// from xpcom import components
// R = components.classes["@sciviews.org/svRinterpreter;1"].\
//    		getService(components.interfaces.svIRinterpreter)
////////////////////////////////////////////////////////////////////////////////
// Not yet! R.eval(cmd); 		// Evaluate a command in the R interpreter
// Not yet! R.evalHidden(cmd); 	// Evaluate a command in hidden mode in R
// R.escape(); 			// Escape from multiline mode in R
// R.calltip(code); 	// Get a calltip for this code
// R.complete(code); 	// Get completion list for this code
////////////////////////////////////////////////////////////////////////////////
// TODO: implement rCharset(), rClient() and rCommand() here only. Rework the
//       version in sv.socket to use this one.
// TODO: rework calltip() and complete() in sv.r to use this one.

Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");


//// Class constructor & definition ////////////////////////////////////////////
function svRinterpreter() {}

svRinterpreter.prototype = {
    
    // Properties required for XPCOM registration
    classDescription: "The SciViews-K R interpreter",
    classID:          Components.ID("{57dbf673-ce91-4858-93f9-2e47fea3495d}"),
    contractID:       "@sciviews.org/svRinterpreter;1",
    
    // Category: An array of categories to register this component in.
    _xpcom_categories: [{
  
      // Each object in the array specifies the parameters to pass to
      // nsICategoryManager.addCategoryEntry(). 'true' is passed for both
      // aPersist and aReplace params.
      category: "r",
  
      // Optional, defaults to the object's classDescription
      //entry: "",
  
      // Optional, defaults to object's contractID (unless 'service' specified)
      //value: "...",
  
      // Optional, defaults to false. When set to true, and only if 'value' is
      // not specified, the concatenation of the string "service," and the
      // object's contractID is passed as aValue parameter of addCategoryEntry.
       service: false
    }],

    // QueryInterface implementation, e.g. using the generateQI helper
	// (remove argument if skipped steps above)
    QueryInterface: XPCOMUtils.generateQI([Components.interfaces.svIRinterpreter]),

    //chromeURL: "chrome://komodo/content/colorpicker/colorpicker.html",

    /**
    * Execute code in the R interpreter and return result.
    * @param code - The code to evaluate in R.
    */
    //eval: function(cmd) {
    //    // Does not work yet (return NULL)
    //    return sv.r.eval(cmd);  
    //},
    
    /**
    * Execute code in the R interpreter in hidden way and return result.
    * @param cmd - The command to evaluate in R.
    */
    //evalHidden: function(cmd, earlyExit) {
    //    // Does not work yet (return NULL)
    //    return sv.r.evalHidden(cmd, earlyExit);    
    //},

    /**
    * Escape from multiline mode in the R interpreter.
    */
    escape: function() {
        // Send an <<<esc>>> sequence that breaks multiline mode
		cmd = "";
		prompt == ":> ";
	// TODO: change this!	if (cmdout) { sv.cmdout.clear(); }
		var listener = { finished: function(data) {} }
		var res = rCommand('<<<esc>>>', false);
		return(res);
    },
    
    /**
    * Query the R interpreter to get a calltip.
    * @param code - The piece of code currently edited requiring calltip.
    */
    calltip: function(code) {
		if (typeof(code) == "undefined" | code == "") {
			return "";
		}
		var cmd = 'cat(CallTip("' + code.replace(/(")/g, "\\$1") +
			'", location = TRUE))';
		var res = rCommand("<<<h>>>" + cmd, false, null,
			function (tip) {
				if (tip != "") {
					koLogger.debug(tip);
					var kvSvc = Components.
						classes["@activestate.com/koViewService;1"].
						getService(Components.interfaces.koIViewService);
					var ke = kvSvc.currentView.document.getView().scimoz;					
					ke.callTipCancel();
					ke.callTipShow(ke.anchor, tip.replace(/[\r\n]+/g, "\n"));
				}
			}
		);
		return(res);
    },
    
    /**
    * Query the R interpreter to get a completion list.
    * @param code - The piece of code currently edited requiring completion.
    */
    complete: function(code) {
		if (typeof(code) == "undefined" | code == "") {
			return "";
		}
		code = code.replace(/(")/g, "\\$1");
		var kvSvc = Components.
			classes["@activestate.com/koViewService;1"].
			getService(Components.interfaces.koIViewService);
		var ke = kvSvc.currentView.document.getView().scimoz;
		var cmd = 'Complete("' + code + '", print = TRUE, types = "scintilla")';
		koLogger.debug("R> " + cmd);
		var res = rCommand("<<<h>>>" + cmd, false, null,
			function (autoCstring) {
				// these should be set only once?:
				ke.autoCSeparator = 9;
				//ke.autoCSetFillUps(" []{}<>/():;%+-*@!\t\n\r=$`");
				var autoCSeparatorChar = String.fromCharCode(ke.autoCSeparator);
				autoCstring = autoCstring.replace(/^(.*)[\r\n]+/, "");

				var trigPos = RegExp.$1;
				//var trigPos = RegExp.$1.split(/;/g)[1];

				autoCstring = autoCstring.replace(/\r?\n/g, autoCSeparatorChar);

				// code below taken from "CodeIntelCompletionUIHandler"
			//	var iface = Components.interfaces.koICodeIntelCompletionUIHandler;
			//	ke.registerImage(iface.ACIID_FUNCTION, ko.markers.
			//		getPixmap("chrome://komodo/skin/images/ac_function.xpm"));
			//	ke.registerImage(iface.ACIID_VARIABLE, ko.markers.
			//		getPixmap("chrome://komodo/skin/images/ac_variable.xpm"));
			//	ke.registerImage(iface.ACIID_XML_ATTRIBUTE, ko.markers.
			//		getPixmap("chrome://komodo/skin/images/ac_xml_attribute.xpm"));
			//	ke.registerImage(iface.ACIID_NAMESPACE, ko.markers.
			//		getPixmap("chrome://komodo/skin/images/ac_namespace.xpm"));
			//	ke.registerImage(iface.ACIID_KEYWORD, ko.markers.
			//		getPixmap("chrome://komodo/skin/images/ac_interface.xpm"));
				ke.autoCChooseSingle = true;
				ke.autoCShow(trigPos, autoCstring);
			}
		);
		return res;
    }
};


//// XPCOM registration of the class ///////////////////////////////////////////
var components = [svRinterpreter];
function NSGetModule(compMgr, fileSpec) {
    return XPCOMUtils.generateModule(components);
}


//// Komodo logging service ////////////////////////////////////////////////////
var koLogging = Components
	.classes["@activestate.com/koLoggingService;1"]
	.getService(Components.interfaces.koILoggingService);
var koLogger = koLogging.getLogger("svRinterpreter");

koLogger.setLevel(koLogging.DEBUG);


//// Komodo preferences access /////////////////////////////////////////////////
var prefsSvc = Components.classes["@activestate.com/koPrefService;1"].
	getService(Components.interfaces.koIPrefService);
var prefs = prefsSvc.prefs;

// Get a string preference, or default value
function getPrefString(pref, def) {
	if (prefs.hasStringPref(pref)) {
		return(prefs.getStringPref(pref));
	} else return(def);
}

// Set a string preference
function setPrefString(pref, value, overwrite) {
	if (overwrite == false & prefs.hasStringPref(pref)) return;
	prefs.setStringPref(pref, value);
}


//// R socket server configuration /////////////////////////////////////////////
var svSocketMinVersion = "0.9-44";	// Will be used later for compatibility
							// checking between R and Komodo tools
var host = "127.0.0.1";		// Host to connect to (local host only, currently)
var cmdout = false;			// Do we write to 'Command Output'?
var prompt = ":> ";			// The prompt, could be changed to continue prompt
var cmd = "";				// The command to send to R

var millis = 500; 			// ms to wait for input, with synchroneous com only
var charsetUpdated = false;	// Character set used by R is updated?
var converter = Components
	.classes["@mozilla.org/intl/scriptableunicodeconverter"]
	.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);

// Function to set up the charset used by R
// TODO: should we have to reset this, i.e., can R change this during a session?
function rCharset(force) {
	if (!force && charsetUpdated) return;
	koLogger.debug("charsetUpdate");
	charsetUpdated = true;
	
	this.rCommand("<<<h>>>cat(localeToCharset()[1])", false, null,
		function (s) {
			this.converter.charset = s;
			koLogger.debug("R character set is " + s);
		}
	);
}
				
// The main socket client function to connect to R socket server
function rClient(host, port, outputData, listener, echo, echofun) {
	try {
		var transportService = Components.
			classes["@mozilla.org/network/socket-transport-service;1"]
			.getService(Components.interfaces.nsISocketTransportService);
		var transport = transportService.createTransport(null, 0,
			host, port, null);

		if (converter.charset) try {
			// Convert output string from unicode to R's charset (Bug #240)
			outputData = converter.ConvertFromUnicode(outputData);
		} catch(e) {
			koLogger.error("rClient() is unable to convert from Unicode: " + e);
		}
		
		var outstream = transport.openOutputStream(0, 0, 0);
		outstream.write(outputData, outputData.length);
	
		var stream = transport.openInputStream(0, 0, 0);
		var instream = Components.
			classes["@mozilla.org/scriptableinputstream;1"]
			.createInstance(Components.interfaces.nsIScriptableInputStream);
		instream.init(stream);
	
		var dataListener = {
			data: "",
			onStartRequest: function(request, context) { this.data = ""; },
			onStopRequest: function(request, context, status) {
				instream.close();
				outstream.close();
				// Remove last CRLF
				this.data = this.data.replace(/[\n\r]{1,2}$/, "");
				listener.finished(this.data);
			},
			onDataAvailable: function(request, context,
				inputStream, offset, count) {
				// TODO: limit the amount of data send through the socket!
				var chunk = instream.read(count);

				if (converter.charset)
					try { // Convert read string to unicode (Bug #240)
						chunk = converter.ConvertToUnicode(chunk);
					} catch(e) {
						koLogger.error("rClient() is unable to convert " +
							"to Unicode: " + e);
					}

				// Determine if we have a prompt at the end
				if (chunk.search(/\+\s+$/) > -1) {
					this.prompt = ":+ ";
					// Remove endline from prompt if it is a continuation
					chunk = chunk.rtrim() + " ";
				} else if (chunk.search(/>\s+$/) > -1) {
					this.prompt = ":> ";
				}
	
				// Do we need to close the connection
				// (\f received, followed by \n, \r, or both)?
				if (chunk.match("\n\f") == "\n\f") {
					instream.close();
					outstream.close();
					// Eliminate trailing (\r)\n\f chars before the prompt
					// Eliminate the last carriage return after the prompt
					chunk = chunk.replace(/(\r?\n\f|\s+$)/, "");
				}
				this.data += chunk;
				// Do we "echo" these results somewhere?
				if (echo) {
					if (echofun == null) {
						// Use default echo function (to the Command Output)
//// TODO: eliminate this from here!		sv.cmdout.append(chunk, newline = false);
					} else echofun(chunk);
				}
			}
		}
	
		var pump = Components.
		classes["@mozilla.org/network/input-stream-pump;1"].
			createInstance(Components.interfaces.nsIInputStreamPump);
		pump.init(stream, -1, -1, 0, 0, false);
		pump.asyncRead(dataListener, null);
	} catch (e) {
		koLogger.error("rClient() raises an unknown error: " + e);
		return(e);
	}
	return(null);
}
	
// Send an R command through the socket
function rCommand(cmd, echo, echofun, procfun, context) {
	// Get R's charset before first request and set converter.charset (Bug #240)
	this.rCharset();
	// Replace CRLF
	cmd = cmd.replace(/(\r?\n|\r)/g, "<<<n>>>");

	var listener;
	if (procfun == null) {	// Do nothing at the end
		listener = { finished: function(data) {} }
	} else {	// Call procfun at the end
		listener = { finished: function(data) { procfun(data, context); } }
	}
	// TODO: deal with error checking for this command
	var port = getPrefString("sciviews.client.socket", "8888");
	var id = "<<<id=" +
		getPrefString("sciviews.client.id", "SciViewsK") + ">>>";
	var res = this.rClient(this.host, port, id + cmd + "\n",
		listener, echo, echofun);

	// if exception was returned:
	if (res && res.name && res.name == "NS_ERROR_OFFLINE") {
		koLogger.error("R is unreacheable: " + res);
	}
	return(res);
}
//Test: rCommand("<<<q>>>cat('library = '); str(library)");


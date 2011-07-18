// SciViews-K socket client/server functions
// Socket client and server functions to connect to R kernels
// Copyright (c) 2008-2010, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
//
/////// Socket client //////
// sv.clientType				// A global variable with 'http' or 'socket'
// sv.socket.svSocketMinVersion // Minimum version of svSocket R package required
// sv.socket.svGUIMinVersion    // Minimum version of svGUI package required
// sv.socket.partial	// In case of multiline mode, current command is partial
// sv.socket.rClientSocket(host, port, cmd, listener, echo, procname);
// sv.socket.rClientHttp(host, port, cmd, listener, echo, procname);
// 		Main client fonction, SciViews socket server and SciViews HTTP server versions)

// sv.socket.rCommand(cmd, echo, procfun, ...); 	 	// Send cmd to R
// sv.socket.rProcess(rjson);	// Default RJSONp function called back
// sv.socket.rUpdate();								  	// Update R options
//
/////// Socket server //////
// sv.socket.debug              // Debugging mode (in Command Output)
// sv.socket.serverIsLocal      // Is the socket servicing only localhost?
//
// sv.socket.serverStart();     // Start the SciViews-K socket server
// sv.socket.serverStop();      // Stop the SciViews-K socket server
// sv.socket.serverIsStarted;   // (read-only) Is the socket server started?
// sv.socket.serverConfig();    // Get a short description of server config
// sv.socket.serverWrite(data); // Write a string through the socket server
////////////////////////////////////////////////////////////////////////////////
//
// TODO:
// * A method to check svSocketMinVersion, and include this in rUpdate()
// * Correct the crash problem when Komodo exits on Windows (connections not closed?)
// * The interface must be made 100% compatible with the HTTP server
// * Severe! On Windows the socket server is not reachable from R after Komodo is restarted
//   while R is running already. Executing sv.socket.serverStart() does not help at all.


// Make sure sv.clientType is defined according to current prefs
sv.clientType = sv.prefs.getString("sciviews.client.type", "socket");
// KB: until http transport is fixed, changed default to 'socket'

// Define the 'sv.socket' namespace
if (typeof(sv.socket) == 'undefined') sv.socket = {};

(function () {

var _this = this;

/////// Socket client //////////////////////////////////////////////////////
// svSocketMinVersion, svPartial and svConverter are global variables
// defined in svRinterpreter.js
this.svSocketMinVersion = "0.9-50";	// Min version of svSocket package required
this.svGUIMinVersion = "0.9-49";	// Minimum version of svGUI package required
this.partial = false;				// Is the last command send to R partial?

// String converter used between Komodo and R (localeToCharset()[1] in R)
var _converter = Components
	.classes["@mozilla.org/intl/scriptableunicodeconverter"]
	.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);

// Accessors to set/get charset
this.__defineGetter__ ('charset', function () _converter.charset);
this.__defineSetter__ ('charset', function (charset) {
	if (charset != _converter.charset)
		try { _converter.charset = charset; } catch (e) { }
	return(_converter.charset);
});
this.charset = "ASCII";
//TODO: charcode is not updated when Komodo starts and R is already running.
// rUpdate should be run at Komodo startup, but how to figure out if R is running
// then???
// Perhaps save 'charcode' as a preference

// The conversion functions
function _fromUnicode (str, charset) {
	if (charset !== undefined && _this.charset != charset) 	_this.charset = charset;
	try {
		if (_converter.charset)
			str = _converter.ConvertFromUnicode(str) + _converter.Finish();
	} catch(e) {
		sv.log.exception(e, "sv.socket is unable to convert from Unicode to " +
			_converter.charset + ". The message was " + str);
	}
	return(str);
}

function _toUnicode (str, charset) {
	if (charset !== undefined && _this.charset != charset) _this.charset = charset;
	try {
		if (_converter.charset)
			str = _converter.ConvertToUnicode(str);
	} catch(e) {
		sv.log.exception(e, "sv.socket is unable to convert to Unicode from " +
			_converter.charset + ". The message was " + str);
	}
	return(str);
}

// The main socket client function to connect to R socket server
this.rClientSocket = function (host, port, cmd, listener, echo, procname) {
	// Workaround for NS_ERROR_OFFLINE returned by 'createTransport' when
	// there is no network connection (when network goes down). Based on
	// toggleOfflineStatus() in chrome://browser/content/browser.js.
	if (!navigator.onLine) Components
		.classes["@mozilla.org/network/io-service;1"]
		.getService(Components.interfaces.nsIIOService2).offline = false;

	try {
		var transport = Components
			.classes["@mozilla.org/network/socket-transport-service;1"]
			.getService(Components.interfaces.nsISocketTransportService)
			.createTransport(null, 0, host, port, null);

		var outstream = transport.openOutputStream(0, 0, 0);
		cmd = _fromUnicode(cmd);
		// TODO: if procname != null, instruct to return a RJsonP result!
		outstream.write(cmd, cmd.length);

		var stream = transport.openInputStream(0, 0, 0);
		var instream = Components
			.classes["@mozilla.org/scriptableinputstream;1"]
			.createInstance(Components.interfaces.nsIScriptableInputStream);
		instream.init(stream);

		var dataListener = {
			data: "",
			onStartRequest: function(request, context) { _this.data = ""; },
			onStopRequest: function(request, context, status) {
				instream.close();
				stream.close()
				outstream.close();
				_this.data = sv.tools.strings.removeLastCRLF(_this.data);
				listener.finished(_this.data);
			},
			onDataAvailable: function (request, context, inputStream,
				offset, count) {
				var chunk = _toUnicode(instream.read(count));

				// Do we need to close the connection
				// (\f received, followed by \n, \r, or both)?
				if (chunk.match("\n\f") == "\n\f") {
					instream.close();
					stream.close();
					outstream.close();
					// Eliminate trailing (\r)\n\f chars before the prompt
					// Eliminate the last carriage return after the prompt
					chunk = chunk.replace(/(\r?\n\f|\s+$)/, "");
				}

				// Determine if we have a prompt at the end
				if (chunk.search(/\+\s+$/) > -1) {
					_this.partial = true;
					chunk = chunk.rtrim() + " ";
					if (echo) sv.r.print(chunk, false, true, true);
				} else if (chunk.search(/>\s+$/) > -1) {
					_this.partial = false;
					if (echo) sv.r.print(chunk, false, false, false);
				} else if (echo) sv.r.print(chunk, false, false, true);
				_this.data += chunk;
			}
		}

		var pump = Components
			.classes["@mozilla.org/network/input-stream-pump;1"]
			.createInstance(Components.interfaces.nsIInputStreamPump);
		pump.init(stream, -1, -1, 0, 0, false);
		pump.asyncRead(dataListener, null);
	} catch (e) {
		sv.log.exception(e, "sv.socket.rClientSocket() raises an unknown error");
		return(e);
	}
	return(null);
}

// The main http client function to connect to R socket server
this.rClientHttp = function (host, port, cmd, listener, echo, procname) {
	// Workaround for NS_ERROR_OFFLINE returned by 'createTransport' when
	// there is no network connection (when network goes down). Based on
	// toggleOfflineStatus() in chrome://browser/content/browser.js.
	if (!navigator.onLine) Components
		.classes["@mozilla.org/network/io-service;1"]
		.getService(Components.interfaces.nsIIOService2).offline = false;

	try {
		var httpRequest, url;
		httpRequest = new XMLHttpRequest();
		httpRequest.onreadystatechange = function () {
			try {
				if (httpRequest.readyState == 4) {
					// For reasons I don't know, R HTTP server version 2.11.1
					// returns 500 instead of 200 upon correct completion of
					// the command...
					if (httpRequest.status == 200 | httpRequest.status == 500) {
						var res = _toUnicode(httpRequest.responseText);
						if (res.match("\n\f") == "\n\f") {
							// Eliminate trailing (\r)\n\f chars before the prompt
							// Eliminate the last carriage return after the prompt
							res = res.replace(/(\r?\n\f|\s+$)/, "");
						}

						// Determine if we have a prompt at the end
						if (res.search(/\+\s+$/) > -1) {
							_this.partial = true;
							res = res.rtrim() + " ";
							if (echo) sv.r.print(res, false, true, true);
						} else if (res.search(/>\s+$/) > -1) {
							_this.partial = false;
							if (echo) sv.r.print(res, false, false, false);
						} else if (echo) sv.r.print(res, false, false, true);
						// Finish command in case there is a callback
						listener.finished(sv.tools.strings.removeLastCRLF(res));
					} else if (httpRequest.status > 0) {
						sv.log.error(
							"sv.http.rCallback() got a communication error. " +
							"Status: " + httpRequest.status);
						return(httpRequest.status);
					}
				}
			} catch(e) {
				sv.log.exception(e, "sv.http.rCallback() raises an unknown error");
				return(e);
			}
			return(null);
		};

		//url is http://<host>:<port>/custom/SciViews?<cmd>&<callback>
		url = "http://" + host + ":" + port + "/custom/SciViews?" +
			encodeURIComponent(_fromUnicode(cmd))
		if (procname != null) url = url + "&" + procname;
		httpRequest.open('GET', url, true);
		httpRequest.send('');

	} catch (e) {
		sv.log.exception(e, "sv.socket.rClientHttp() raises an unknown error");
		return(e);
	}
	return(null);
}

this.rClient = function (host, port, cmd, listener, echo, procname) {
	if (sv.clientType == "socket") {
		res = this.rClientSocket(host, port, cmd, listener, echo, procname);
	} else {
		res = this.rClientHttp(host, port, cmd, listener, echo, procname)
	}
	return(res);
}

// TODO: use this on preference change "sciviews.client.type"
this.setSocketType = function (type) {
	switch(type) {
		case "http":
			_this.rClient = this.rClientHttp;
			break;

		case "socket":
		default:
			_this.rClient = this.rClientSocket;
			break;
	}
}

this.setSocketType(sv.prefs.getString("sciviews.client.type", "socket"));

// Send an R command through the socket
// any additional arguments will be passed to procfun
// procfun can be also an object, then the result will be stored in procfun.value
this.rCommand = function (cmd, echo, procfun) {
	//sv.cmdout.append("rCommand:: " + cmd);

	if (echo === undefined) echo = true;
	//if (procfun === undefined) procfun = "sv.socket.rProcess";

	var host = sv.prefs.getString("sciviews.server.host", "127.0.0.1");
	var port = sv.prefs.getString("sciviews.client.socket", "8888");
	var id = "<<<id=" +
		sv.prefs.getString("sciviews.client.id", "SciViewsK") + ">>>";
	cmd = sv.tools.strings.replaceCRLF(cmd, "<<<n>>>");
	var listener;
	var procname = null;
	if (procfun == null) {	// Do nothing at the end
		listener = { finished: function(data) {} }
	} else if (typeof(procfun) == "string") { // This is a RjsonP call
		listener = { finished: function(data) {
				// The call is constructed as a RjsonP object => evaluate it
				return(sv.rjson.eval(_toUnicode(data)));
			}
		}
		procname = procfun;
	} else { 				// Call procfun at the end
		// Convert all arguments to an Array
		var args = Array.apply(null, arguments);
		listener = { finished: function (data) {
				// Keep only arguments after procfun, and add "data"
				args.splice(0, 3, data);
				if (typeof(procfun) == "function") {
					procfun.apply(null, args);
				} else { // We can add a property even to a function
					procfun.value = data;
				}
			}
		}
	}

	var res = _this.rClient(host, port, id + cmd + "\n", listener,
			echo, procname);
	// Socket server in svSocket
	//if (sv.prefs.getString("sciviews.client.type", "socket") == "socket") {
	//if (sv.clientType == "socket") {
	//	res = _this.rClientSocket(host, port, id + cmd + "\n", listener,
	//		echo, procname);
	//} else {						// Http server in svGUI
	//	res = _this.rClientHttp(host, port, id + cmd + "\n", listener,
	//		echo, procname);
	//}
	if (res && res.name && res.name == "NS_ERROR_OFFLINE")
		ko.statusBar.AddMessage("Error: Komodo went offline!",
			"SciViews-K client", 5000, true);
	return(res);
}
// Test: sv.socket.rCommand("<<<q>>>cat('library = '); str(library)");

// This is the default callback function used when sending RjsonP command
// It just outputs results where it should be
this.rProcess = function (rjson) {
	// If an encoding is returned by R, reset it
	if (rjson.encoding != null)
		_this.charset = rjson.encoding;
	// Are we in partial code mode?
	if (rjson.options.partial != null)
		_this.partial = (rjson.options.partial == true);
	// Results of the calculation are in the 'result' component
	var res = rjson.result;
	if (res == null) return;

	// Do we echo these results?
	if (rjson.options.echo == true) {
		// Are we inside a multiline command?
		var command = false;
		if (res.search(/\+\s+$/) > -1) command = true;
		res = res.rtrim() + " ";
		sv.r.print(res, false, command, _this.partial);
	}
}

// Update a couple of key settings between Komodo and R
// TODO: add the current working directory and report WD changes from R automagically
this.rUpdate = function () {
	// Make sure that dec and sep are correctly set in R
	this.rCommand('<<<H>>>options(' +
		'OutDec = "' + sv.prefs.getString("r.csv.dec", ".") +
		'", OutSep = "' + sv.prefs.getString("r.csv.sep", ",") +
		'"); invisible(guiRefresh(force = TRUE)); ' +
		'cat("", localeToCharset()[1], sep="");',
		// ??? The following does not work.
		//'cat("<<<charset=", localeToCharset()[1], ">>>", sep = "")',
		false, function (s) { // this is a callback receiving the character set
			_this.charset = sv.tools.strings.trim(s);
			if (_this.debug) sv.log.debug("R charset: " + _this.charset);
	});
}


/////// Socket server //////////////////////////////////////////////////////
this.debug = sv.log.isAll();	// Set to true for debugging mode
this.serverIsLocal = true;		// Is the socket servicing only localhost?
const nsITransport = Components.interfaces.nsITransport;

var _serverSocket;				// The SciViews-K socket server object
var _inputString;				// The string with command send by R
var _outputString;				// The string with the result to send to R
var _output = [];				// An array with outputs
var _timeout = 250;				// Maximal ms to wait for input

// Debug only
this.serverSocket = _serverSocket;

// The following two methods implement nsIServerSocketListener
this.onSocketAccepted = function (socket, transport) {
	try {
		if (_this.debug)
			sv.log.debug("Socket server: onSocketAccepted!");

		// Make sure to clean input and output strings before use
		_inputString = "";
		_outputString = "";
		_output = [];
		if (_this.debug)
			sv.log.debug("Socket server: " + transport.host +
				" on port " + transport.port + "\n");

		// Then, read data from the client
		var inputStream = transport.openInputStream(nsITransport
			.OPEN_BLOCKING, 0, 0);
		var sin = Components
			.classes["@mozilla.org/scriptableinputstream;1"]
			.createInstance(Components.interfaces
			.nsIScriptableInputStream);
		sin.init(inputStream);

		var date = new Date();
		var timeout = _timeout;
		var inlength = 0;
		do {
			_inputString = sin.read(512);
			// TODO: do we get <<<timeout=XXX>>>? => change _timeout
		} while (_inputString == "" && ((new Date()) - date < _timeout))

		// Read the complete data
		while (sin.available() > 0) _inputString += sin.read(512);
		// Is there data send?
		if (_inputString == "") {
			//_outputString += "Error: no command send!\n"
			_output.push("Error: no command send!");
		} else {
			// Convert to unicode
			_inputString = _toUnicode(_inputString);
			// Process the command
			if (this.debug)
				sv.log.debug("Command send by the client:\n" + _inputString);
			try {
				if (_inputString.match(/^<<<js>>>/)) {
					eval(_inputString.substring(8));
				} else if (_inputString.match(/^<<<rjsonp>>>/)) {
					sv.rjson.eval(_inputString.substring(12));
				} else {
					// TODO: this is some output data... wait that R finishes
					// Sending the output and echo it into the local R console
					sv.r.print(_inputString, false, false, false);
					// TODO: change this (just to test if it is the cause of the problems)!
					//eval(_inputString);
				}
			} catch(e) {
				_output.push(e.toString());
			}
		}
		if (_this.debug) sv.log.debug(_output.length ?
			("Result:\n" + _output.join("\n")) :
			("Nothing to return to the socket client"));

		// And finally, return the result to the socket client
		// (append \n at the end)
		_outputString = _fromUnicode(_output.join("\n") + "\n");
		var outputStream = transport.openOutputStream(nsITransport
			.OPEN_BLOCKING, 0, 0);
		outputStream.write(_outputString, _outputString.length);
	} catch(e) {
		sv.log.exception(e, "Socket server: onSocketAccepted()," +
			" unmanaged error");
	} finally {
		// Make sure that streams are closed
		outputStream.close();
		inputStream.close();
		if (_this.debug) sv.log.debug("SocketAccepted: end");
	}
};

this.onStopListening = function (socket, status) {
	// The connection is closed by the client
	if (_this.debug) sv.log.debug("(onStopListening) Socket server closed");
};
// End of 'nsIServerSocketListener' methods

// Core function for the SciViews-K socket server
// Create the _serverSocket object
this.serverStart = function (port) {
	if (_this.debug) sv.log.debug("Socket server: serverStart");

	if (_this.serverIsStarted) try {
		_serverSocket.close();
	} catch(e) {
		sv.log.exception(e, "sv.socket.serverStart() failed to close the" +
			" socket before reopening it");
	}
	try {
		_serverSocket = Components
			.classes["@mozilla.org/network/server-socket;1"]
			.createInstance(Components.interfaces.nsIServerSocket);
		if (port) {
			sv.prefs.setString("sciviews.server.socket", port);
		} else {
			port = sv.prefs.getString("sciviews.server.socket", "7052");
		}

		_serverSocket.init(port, _this.serverIsLocal, -1);
		_serverSocket.asyncListen(_this);
		this.serverSocket = _serverSocket;
	} catch(e) {
		//TODO: add exception type checking here (see below)
		port = parseInt(port);
		if (ko.dialogs.okCancel(
			sv.translate("Cannot open a server socket to allow communication "
				+ " from R to Komodo on port %S.\n" +
				"Click OK to change port to %S and try again.", port, port + 1),
				"OK", null, "SciViews-K") == "OK") {
			sv.prefs.setString("sciviews.server.socket", port + 1);
			_this.serverStart();
		}
		return;

		/*sv.log.exception(e, "SciViews-K cannot open a server socket on port " +
			port + ".\nMake sure the port is not already used by another" +
			" Komodo instance" + "\nor choose another port in the" +
			" preferences and restart Komodo", false);*/
		// If the port is already used, I got:
		// "0x80004005 (NS_ERROR_FAILURE)"  location: "JS frame ::
		// chrome://sciviewsk/content/js/socket.js :: anonymous :: line 285
	}
	if (_this.debug)
		sv.log.debug("serverStart: Socket server started");
	ko.statusBar.AddMessage(
		"SciViews-K socket server started", "SciViews-K server", 2000, true);
}

// Stop the SciViews-K socket server
this.serverStop = function () {
	if (_this.serverIsStarted) {
		try {
			_serverSocket.close();
		} catch(e) {
			sv.log.exception(e, "Socket server: serverStop() cannot" +
				" close the socket", true);
		}
		if (_this.debug) sv.log.debug("Socket server stopped");
		ko.statusBar.AddMessage(
			"SciViews-K socket server stopped", "SciViews-K server", 2000, true);
	} else {
		ko.statusBar.AddMessage(
			"SciViews-K socket server is not started", "SciViews-K server", 2000, true);
	}
}

// Is the SciViews-K socket server started?
this.__defineGetter__ ('serverIsStarted', function () {
	// Use brute force to find out whether socketServer is initiated and listening
	if (typeof(sv.socket.serverSocket) == "undefined") return(false);
	try {
		_this.serverSocket.asyncListen(_this);
	} catch(e) {
		if (e.name == "NS_ERROR_IN_PROGRESS") return(true);
		else if (e.name == "NS_ERROR_NOT_INITIALIZED") return(false);
		else sv.log.exception(e);
	}
	return(true);
});

// What is the current SciViews-K socket server config?
this.serverConfig = function () {
	var serverStatus = " (stopped)"
	if (_this.serverIsStarted) serverStatus = " (started)"
	var port = sv.prefs.getString("sciviews.server.socket", "7052");
	if (_this.serverIsLocal) {
		return("Local socket server on port " + port + serverStatus);
	} else {
		return("Global socket server on port " + port + serverStatus);
	}
}

// Write to the socket server, use this to return something to the client
this.serverWrite = function (data) {
	if (_this.serverIsStarted) {
		_output.push(data);
	} else {
		sv.alert("The socket server in unavailable",
			"Trying to write data though the SciViews-K socket server" +
			" that is not started!");
	}
}

}).apply(sv.socket);

// Launch the SciViews socket server on Komodo startup
addEventListener("load", function()
	window.setTimeout("sv.socket.serverStart();", 500), false);

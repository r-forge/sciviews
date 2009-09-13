// SciViews-K socket client/server functions
// Socket client and server functions to connect to R kernels
// Copyright (c) 2008-2009, Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// To cope with versions incompatibilities, we define this:
// sv.socket.svSocketMinVersion  // minimal svSocket R package version required
//
/////// Socket client //////
// Parameters:
// sv.socket.host;  // The address of the R server host (local only for now)
// sv.socket.cmdout // Do we echo exchange to the Output Command pane?
// sv.socket.prompt // Look at this to know if we are in multiline mode
// sv.socket.cmd    // In case of multiline mode, the partial command so far
//
// sv.socket.rClient(host, port, outputData, listener, echo); // Main client fct
// sv.socket.rCommand(cmd);  // Send cmd to the R socket server for evaluation
//
/////// Socket server //////
// Parameters:
// sv.socket.debug              // Debugging mode (in Command Output)
// sv.socket.serverIsLocal      // Is the socket servicing only localhost?
//
// sv.socket.serverStart();     // Start the SciViews-K socket server
// sv.socket.serverStop();      // Stop the SciViews-K socket server
// sv.socket.serverIsStarted(); // Is the socket server currently started?
// sv.socket.serverConfig();    // Get a short description of server config
// sv.socket.serverWrite(data); // Write a string through the socket server
// sv.socket.updateCharset(force); // Update R character set
////////////////////////////////////////////////////////////////////////////////
//
// TODO: use svSocketMinVersion to check svSocket R package is not too old!
// TODO: start the socket server automatically when Komodo is launched


// Define the 'sv.socket' namespace
if (typeof(sv.socket) == 'undefined')
	sv.socket = {};

(function () {
	
	/////// Socket client //////////////////////////////////////////////////////
	this.svSocketMinVersion = "0.9-44";	// Will be used later for compatibility
										// checking between R and Komodo tools
	this.host = "127.0.0.1";	// Host to connect to (local host only, currently)
	this.cmdout = true;			// Do we write to 'Command Output'?
	this.prompt = ":> ";		// The prompt, could be changed to continue prompt
	this.cmd = "";				// The command to send to R

	var millis = 500; // ms to wait for input, with synchroneous com only
	var _charsetUpdated = false;
	var _this = this;
	var converter = Components
		.classes["@mozilla.org/intl/scriptableunicodeconverter"]
		.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
				
	// The main socket client function to connect to R socket server
	this.rClient = function (host, port, outputData, listener, echo, echofun) {
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
				sv.log.exception(e, "sv.socket.rClient() is unable to convert" +
					" from Unicode");
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
					this.data = sv.tools.strings.removeLastCRLF(this.data);
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
							sv.log.exception(e, "sv.socket.rClient() is" +
								" unable to convert to Unicode");
						}
	
					// Determine if we have a prompt at the end
					if (chunk.search(/\+\s+$/) > -1) {
						this.prompt = ":+ ";
						// remove endline from prompt if it is a continuation
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
							sv.cmdout.append(chunk, newline = false);
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
			sv.log.error("sv.socket.rClient() raises an unknown error\n");
			//sv.log.exception(e, "sv.socket.rClient() raises an unknown error");
			return(e);
		}
		return(null);
	}
	
	// Send an R command through the socket
	this.rCommand = function(cmd, echo, echofun, procfun, context) {
		// Get R's character set before first request and set converter.charset
		// (Bug #240)
		// TODO: charset does not change until next R command, update charset
		// at server init
		//this.updateCharset();
	
		cmd = sv.tools.strings.replaceCRLF(cmd, "<<<n>>>");
	
		var listener;
		if (procfun == null) {	// Do nothing at the end
			listener = { finished: function(data) {} }
		} else {	// Call procfun at the end
			listener = { finished: function(data) { procfun(data, context); } }
		}
		// TODO: deal with error checking for this command
		var port = sv.prefs.getString("sciviews.client.socket", "8888");
		var id = "<<<id=" +
			sv.prefs.getString("sciviews.client.id", "SciViewsK") + ">>>";
		var res = this.rClient(this.host, port, id + cmd + "\n",
			listener, echo, echofun);
	
		// if exception was returned:
		if (res && res.name && res.name == "NS_ERROR_OFFLINE") {
			ko.statusBar.AddMessage("Error: R is unreachable (see log)", "R",
				5000, true);
		}
		return(res);
	}
	//Test: sv.socket.rCommand("<<<q>>>cat('library = '); str(library)");


	/////// Socket server //////////////////////////////////////////////////////
	this.debug = sv.log.isAll();	// Set to true for debugging mode
	this.serverIsLocal = true;		// Is the socket servicing only localhost?

	const nsITransport = Components.interfaces.nsITransport;

	var _serverSocket;				// The SviViews-K socket server object
	var _serverStarted = false;		// Is the socket server started?
	var _inputString;				// The string with command send by R
	var _outputString;				// The string with the result to send to R
	var _output = [];
	//debug only:
	this.serverSocket = _serverSocket;

	// Core function for the SciViews-K socket server:
	// create the _serverSocket object
	this.serverStart = function () {
		if (this.debug) sv.log.debug("Socket server: serverStart");
	
		if (_serverStarted) try {
			_serverSocket.close();
			_serverStarted = false;
		} catch(e) {
			sv.log.exception(e, "sv.socket.serverStart() failed to close the" +
				" socket before reopening it");
		}
	
		var listener = {
			onSocketAccepted : function (socket, transport) {
				try {
					if (this.debug)
						sv.log.debug("Socket server: onSocketAccepted!");
	
					// Make sure to clean input and output strings before use
					_inputString = "";
					_outputString = "";
					_output = [];
					if (this.debug)
						sv.log.debug("Socket server: " + transport.host +
							" on port " + transport.port + "\n");
	
					// Then, read data from the client
					var inputStream = transport.openInputStream(nsITransport.
						OPEN_BLOCKING, 0, 0);
					var sin = Components.
						classes["@mozilla.org/scriptableinputstream;1"]
						.createInstance(Components.interfaces.
						nsIScriptableInputStream);
					sin.init(inputStream);
	
					var date = new Date();
					do {
						_inputString = sin.read(512);
					} while(_inputString == "" && ((new Date()) - date < millis))
	
					// Read the complete data
					while (sin.available() > 0)
						_inputString += sin.read(512);
	
					if (converter.charset) try {
						_inputString = converter.ConvertToUnicode(_inputString);
					} catch (e) {
						sv.log.exception(e, "Socket server: onSocketAccepted()" +
							" is unable to convert to Unicode");
					}
	
					// Is there data send?
					if (_inputString == "") {
						//_outputString += "Error: no command send!\n"
						_output.push("Error: no command send!");
					} else {
						// Process the command
						if (this.debug)
							sv.log.debug("Command send by the client:\n" +
								_inputString);
						try {
							eval(_inputString);
						} catch(e) {
							_output.push(e.toString());
						}
					}
					if (this.debug) sv.log.debug(_output.length?
						("Result:\n" + _output.join("\n")) :
						("Nothing to return to the socket client")
					);
	
					// And finally, return the result to the socket client
					// (append \n at the end)
					_outputString = _output.join("\n") + "\n";
	
					if (converter.charset) try {
						_outputString = converter.
							ConvertFromUnicode(_outputString);
					} catch(e) {
						sv.log.exception(e, "Socket server: onSocketAccepted()" +
							" is unable to convert from Unicode");
					}
	
					var outputStream = transport.openOutputStream(nsITransport.
						OPEN_BLOCKING, 0, 0);
					outputStream.write(_outputString, _outputString.length);
				} catch(e) {
					sv.log.exception(e, "Socket server: onSocketAccepted()," +
						" unmanaged error");
				} finally {
					// Make sure that streams are closed
					outputStream.close();
					inputStream.close();
					if (this.debug) sv.log.debug("SocketAccepted: end");
				}
			},
	
			onStopListening : function (socket, status) {
				// The connection is closed by the client
				if (this.debug) sv.log.debug("Socket server closed");
			}
		};
	
		try {
			_serverSocket = Components.
				classes["@mozilla.org/network/server-socket;1"]
				.createInstance(Components.interfaces.nsIServerSocket);
			var port = sv.prefs.getString("sciviews.server.socket", "7052");
			_serverSocket.init(port, sv.socket.serverIsLocal, -1);
			_serverSocket.asyncListen(listener);
			_serverStarted = true;
		} catch(e) {
			sv.log.exception(e, "SciViews-K cannot open a server socket on port" +
				port + ".\nMake sure the port is not already used by another" +
					" Komodo instance" + "\nor choose another port in the" +
					" preferences and restart Komdo", true);
			// If the port is already used, I got:
			// "0x80004005 (NS_ERROR_FAILURE)"  location: "JS frame ::
			// chrome://sciviewsk/content/js/socket.js :: anonymous :: line 285
		}
		if (this.debug) sv.log.debug("Socket server started");
		ko.statusBar.AddMessage("SciViews-K socket server started", "svSock",
			2000, true);
	}
	
	// Stop the SciViews-K socket server
	this.serverStop = function () {
		if (_serverStarted) {
			try {
				_serverSocket.close();
			} catch(e) {
				sv.log.exception(e, "Socket server: serverStop() cannot" +
					" close the socket", true);
			}
	
			_serverStarted = false;
			if (this.debug) sv.log.debug("Socket server stopped");
			ko.statusBar.AddMessage("SciViews-K socket server stopped",
				"svSock", 2000, true);
		} else {
			ko.statusBar.AddMessage("SciViews-K socket server is not started",
				"svSock", 2000, true);
		}
	}
	
	// Is the SciViews-K socket server started?
	this.serverIsStarted = function () {
		return(_serverStarted);
	}
	
	// What is the current SciViews-K socket server config?
	this.serverConfig = function () {
		var serverStatus = " (stopped)"
		if (_serverStarted) serverStatus = " (started)"
		var port = sv.prefs.getString("sciviews.server.socket", "7052");
		if (this.serverIsLocal) {
			return("Local socket server on port " + port + serverStatus);
		} else {
			return("Global socket server on port " + port + serverStatus);
		}
	}
	
	// Write to the socket server, use this to return something to the client
	this.serverWrite = function (data) {
		if (_serverStarted) {
			_output.push(data);
		} else {
			sv.alert("The socket server in unavailable",
				"Trying to write data though the SciViews-K socket server" +
				" that is not started!");
		}
	}

	this.__defineGetter__ ('charset', function () {
		return converter.charset;
	});
	this.__defineSetter__ ('charset', function (x) {
		try {
			converter.charset = x;
		} catch (e) {
			_charsetUpdated = false;
		}
		return converter.charset;
	});

	this.updateCharset = function (force) {
		if (!force && _charsetUpdated) return;
		//if (this.debug) sv.log.debug("charsetUpdate");
		_charsetUpdated = true;
		// We also make sure that dec and sep are synched in R
		_this.rCommand('<<<h>>>options(OutDec = ' +
			sv.prefs.getString("r.csv.dec.arg", ".") +
			'); options(OutSep = ' +
			sv.prefs.getString("r.csv.sep.arg", ",") +
			'); cat(localeToCharset()[1])', false, null,
			function (s) {
				_this.charset = s;
				if (this.debug) sv.log.debug(s);
			});
		// Update also the R Object browser
		sv.r.objects.getPackageList(true);
	}
	
	// [PhG] The following command raises an error on my Mac
	//window.setTimeout(this.serverStart, 500);
	//window.setTimeout(this.updateCharset, 100);
	//this.charset = 'cp1250';
}).apply(sv.socket);

// [PhG] This raises an error on Komodo 5.1 on Mac OS X
//addEventListener("load", sv.socket.serverStart, false);
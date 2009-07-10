// SciViews-K socket client/server functions
// Socket client and server functions to connect to R kernels
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

////////////////////////////////////////////////////////////////////////////////
// To cope with versions incompatibilities, we define this:
// sv.socket.svSocketMinVersion  // minimal svSocket version required
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
// sv.socket.serverStart();     // Start the OpenKore socket server
// sv.socket.serverStop();      // Stop the OpenKore socket server
// sv.socket.serverIsStarted(); // Is the socket server currently started?
// sv.socket.serverConfig();    // Get a short description of server config
// sv.socket.serverWrite(data); // Write a string through the socket server
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.socket' namespace
/////// Socket client //////////////////////////////////////////////////////////
sv.socket = {
	svSocketMinVersion: "0.9-40", // Will be used later for compatibility checking between R and Komodo tools
	host: "127.0.0.1", // Host to connect to (local host only, currently)
	cmdout: true,     // Do we write to 'Command Output'?
	prompt: ":> ",     // The prompt, could be changed to continue prompt
	cmd: "",           // The command to send to R
	charsetUpdated: false,
	charset: "latin1"
};

// The main socket client function to connect to R socket server
sv.socket.rClient = function(host, port, outputData, listener, echo, echofun) {

	try {
		var transportService = Components.
			classes["@mozilla.org/network/socket-transport-service;1"]
			.getService(Components.interfaces.nsISocketTransportService);
		var transport = transportService.createTransport(null, 0,
			host, port, null);

		// Convert output string from unicode to R's charset (Bug #240)
//		var converter = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"]
//			.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
//		converter.charset = sv.socket.charset;
//		outputData = converter.ConvertFromUnicode(outputData);

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
				// TODO: limit the total amount of data send through the socket!
				var chunk = instream.read(count);

				// Convert read string to unicode (Bug #240)
//				chunk = converter.ConvertToUnicode(chunk);

				// Determine if we have a prompt at the end
				if (chunk.search(/\+\s+$/) > -1) {
					sv.socket.prompt = ":+ ";
					// remove endline from prompt if it is a continuation
					chunk = chunk.rtrim() + " ";
				} else if (chunk.search(/>\s+$/) > -1) {
					sv.socket.prompt = ":> ";
				}

				// Do we need to close the connection
				// (\f received, followed by \n, \r, or both)?
				if (chunk.match("\n\f") == "\n\f") {
					instream.close();
					outstream.close();
					// Eliminate the trailing (\r)\n\f chars before the prompt
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
		return(e);
	}
	return(null);
}


// Send an R command through the socket
sv.socket.rCommand = function(cmd, echo, echofun, procfun, context) {

	// Get R's character set before first request and store in sv.socket.charset (Bug #240)
	// TODO: 	sv.socket.charset does not change until next R command, update charset at server init
	//		will return wrong charset with non-windows encodings other than utf-8 and latin1
	if (!sv.socket.charsetUpdated) {
		sv.socket.charsetUpdated = true;
		sv.r.evalCallback(".tmp <- l10n_info(); cat(if (.tmp$`UTF-8`) \"UTF-8\" else if (.tmp$`Latin-1`) \"LATIN1\" else paste(\"CP\", .tmp$codepage, sep=\"\")); rm(.tmp);", function(s) {
			sv.socket.charset = s;
		});
	}

	cmd = sv.tools.strings.replaceCRLF(cmd, "<<<n>>>");
	if (procfun == null) {	// Do nothing at the end
		var listener = { finished: function(data) {} }
	} else {	// Call procfun at the end
		var listener = { finished: function(data) { procfun(data, context); } }
	}
	// TODO: deal with error checking for this command
	var port = sv.prefs.getString("sciviews.client.socket", "8888");
	var id = "<<<id=" + sv.prefs.getString("sciviews.client.id", "SciViewsK") +
		">>>";
	var res = sv.socket.rClient(sv.socket.host, port, id + cmd + "\n",
		listener, echo, echofun);
	return(res);
}
//sv.socket.rCommand("<<<q>>>cat('library = '); str(library)");


/////// Socket server //////////////////////////////////////////////////////////
sv.socket.debug = false; // Set to true for debugging mode
sv.socket.serverIsLocal = true; // Is the socket servicing only localhost?

const nsITransport = Components.interfaces.nsITransport;

var serverSocket;			// The SviViews-K socket server object
var serverStarted = false;	// Is the socket server started?
var inputString;			// The string with the command send by the client
var outputString;			// The string with the result to send to the client

// Core function for the SciViews-K socket server: create the serverSocket object
sv.socket.serverStart = function() {
	var listener = {
		onSocketAccepted : function(socket, transport) {
			try {
				// Make sure to clean input and output strings before use
				inputString = "";
				outputString = "";
				if (sv.socket.debug) {
					sv.cmdout.clear();
					sv.cmdout.append("#--# SciViews-K socket client: " +
						transport.host + " on port " + transport.port + "\n");
				}

				// Then, read data from the client
				var inputStream = transport.openInputStream(nsITransport.
					OPEN_BLOCKING, 0, 0);
				var sin = Components.
					classes["@mozilla.org/scriptableinputstream;1"]
					.createInstance(Components.interfaces.
					nsIScriptableInputStream);
				sin.init(inputStream);

				// Wait for input up to 10 sec max, with synchroneous com only)
				var millis = 10000;
				var date = new Date();
				var curDate = null;
				do {
					curDate = new Date();
					inputString = sin.read(512);
				} while(inputString == "" & curDate - date < millis)

				// Read the complete data
				while (sin.available() > 0)
					inputString += sin.read(512);

				// INTL
//				inputString = converter.ConvertToUnicode(inputString);

				// Is there data send?
				if (inputString == "") {
					if (sv.socket.debug) {
						sv.cmdout.append("#--# SciViews-K socket client: nothing send!\n");
					}
					outputString += "Error: no command send!\n"
				} else {
					// Process the command
					if (sv.socket.debug) sv.cmdout.append("#--# Command send" +
						" by the client:\n" + inputString);
					try {
						ko.commands.doCode(1, inputString);
					} catch(cmderr) {
						if (cmderr) outputString += "\nError: " + cmderr;
					}
				}
				if (sv.socket.debug) {
					if (outputString == "") {
						sv.cmdout.append("#--# Nothing to return" +
							" to the socket client");
					} else {
						sv.cmdout.append("#--# Result:\n" + outputString);
					}
				}

				// And finally, return the result to the socket client
				// (append \n at the end)
				outputString += "\n";
				var outputStream = transport.openOutputStream(nsITransport.
					OPEN_BLOCKING, 0, 0);
				outputStream.write(outputString, outputString.length);
			} catch(e) {
				dump(e);
			} finally {
				// Make sure that streams are closed
				outputStream.close();
				inputStream.close();
			}
		},

		onStopListening : function(socket, status) {
			// The connection is closed by the client
			if (sv.socket.debug)
				sv.cmdout.append("#--# SciViews-K socket closed");
		}
	};

	try {
		serverSocket = Components.
			classes["@mozilla.org/network/server-socket;1"]
			.createInstance(Components.interfaces.nsIServerSocket);
		var port = sv.prefs.getString("sciviews.server.socket", "7052");
		serverSocket.init(port, sv.socket.serverIsLocal, -1);
		serverSocket.asyncListen(listener);
	} catch(ex) { dump(ex); }
	serverStarted = true;
	if (sv.socket.debug)
		ko.statusBar.AddMessage("SciViews-K socket server started", "svSock",
			2000, true);
}

// Stop the SciViews-K socket server
sv.socket.serverStop = function() {
	if (serverStarted) {
		serverSocket.close();
		serverStarted = false;
		ko.statusBar.AddMessage("SciViews-K socket server stopped",
			"svSock", 2000, true);
	} else {
		ko.statusBar.AddMessage("SciViews-K socket server is not started",
			"svSock", 2000, true);
	}
}

// Is the SciViews-K socket server started?
sv.socket.serverIsStarted = function() {
	return(serverStarted);
}

// What is the current SciViews-K socket server config?
sv.socket.serverConfig = function() {
	var serverStatus = " (stopped)"
	if (serverStarted) serverStatus = " (started)"
	var port = sv.prefs.getString("sciviews.server.socket", "7052");
	if (sv.socket.serverIsLocal) {
		return("Local socket server on port " + port + serverStatus);
	} else {
		return("Global socket server on port " + port + serverStatus);
	}
}

// Write to the socket server, use this to return something to the client
sv.socket.serverWrite = function(data) {
	if (serverStarted) {
		outputString += data;
	} else {
		alert("Trying to write data though the SciViews-K socket server" +
			" that is not started!")
	}
}

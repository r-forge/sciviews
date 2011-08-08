//{
//}

// 's.rconn' object is an interface to R implemented mostly in python
// 		The workhorse is 'svUtils' XPCOM interface

//.command (Read only) last command evaluated
//.result (Read only) last result returned
//.listRProcesses(property) get information on currently running R processes
//		(property is one of 'Handle','ProcessId' or 'CommandLine'
//.rEval(command, callback) evaluate in R, optional callback (if not provided,
//		the most recent one is used)
//.rEvalQuick(command) - do 'quick' evaluation in R, and
//		return the result
//.startSocketServer(requestHandler) - optional 'requestHandler' is a function that
//		handles the received data and returns a string
//.stopSocketServer()
//.testRAvailability(checkProc) - test whether R is available, check connection and
//		optionally look up running processes
//Debugging functions:
//.testRCommand(command)
//.testRCommandNotify(chunk)
//.enumObservers()
//Functions below should not be called directy by the user.
//	they will become private later
//*.setObserver(callback, topic) set callback function for R command
//*.removeObserver


//==============================================================================

sv.rconn = {};

try { // DEBUG
	sv.rconn.cleanUp();
} catch(e) {}

//var gSvuSvc = Components.classes["@sciviews.org/svUtils;1"]
	//.getService(Components.interfaces.svIUtils);


(function() {
var _this = this;

// get string from nsISupportsString
function _str(sString) sString.QueryInterface(Components
	.interfaces.nsISupportsString).data;

var _svuSvc = Components.classes["@sciviews.org/svUtils;1"]
	.getService(Components.interfaces.svIUtils);
var _obsSvc = Components.classes["@mozilla.org/observer-service;1"]
    .getService(Components.interfaces.nsIObserverService);

//var observers = {};
//var obsCallback = function() { sv.cmdout.append("test")};

this.__defineGetter__ ('command', function () _svuSvc.lastCommand);
this.__defineGetter__ ('result', function () _svuSvc.lastResult);


// this ID is used to identify commands from the user
this.userCommandId = _svuSvc.uid();


// get list of running R processes
this.listRProcesses = function(property) {
	if (!property) property = "CommandLine";
	var procList = _svuSvc.getproc(property);
	var proc = [];
	while(procList.hasMoreElements()) proc.push(_str(procList.getNext()));
	return proc;
}

// TODO: IMPORTANT! background calls (e.g. object browser) need to have unique id.
// but ID for user commands should be fixed (to allow for multiline)
// sv.rconn.eval("1:100 ", null, false, "sv12345")

// Evaluate in R //
// arguments are handled in a non standard way:
//sv.rconn.eval(command, callback, hidden, null, null, ...) - single use handler
//sv.rconn.eval(command, callback, hidden, id, false, ...) - keep handler
//sv.rconn.eval(command, callback, hidden, id, true, ...) - keep handler, but do not execute
//sv.rconn.eval(command, id, ...)  // reuse handler
this.eval = function(command, callback, hidden, id, prepareOnly) { //, ...
	var handlers = _this.handlers, keep = false;
	var args = Array.apply(null, arguments);
	if(typeof callback == "string" && callback in handlers) {
		id = callback;
		args.splice(0, 2);
		handlers[id].args = args;
	} else {
		if(!id)
			// If no callback, it is an user command
			id = callback? _svuSvc.uid() : this.userCommandId;
		else
			keep = true;

		args.splice(0, 5);
		handlers[id] = new _REvalListener(callback, keep, args, id);

		if (prepareOnly) return id;
	}
	//if (mode == "e")	_this.printResults(result, command);
	// TODO: 'id' should be one and the same for user commands,
	// and unique for background calls

	var mode = ['json']; if (hidden) mode.push('h');

	_svuSvc.execInRBgr(command, mode.join(' '), id);
	//_svuSvc.execInRBgr(command, hidden? "h" : "e", id);
	return id;
}

// Evaluate in R quickly - and return result
this.evalAtOnce = function(command, timeout) {
	if(timeout == undefined) timeout = .5;
	//return _svuSvc.execInR(command, "h", timeout).replace(/[\x02\x03]/g, '');
	return _svuSvc.execInR(command, 'json h', timeout).replace(/[\x02\x03]/g, '');
}

this.escape = function(command) _svuSvc.escape(command);

//this.testRAvailability = function(checkProc) {
//	var result = _this.evalAtOnce("cat(1)").trim();
//	var connectionUp = result == "1";
//	var rProcess = checkProc? _this.getRProc() : undefined;
//	var rProcessCount = (rProcess == undefined)? -1 : rProcess.length;
//	ret = '';
//	if(!connectionUp) {
//		ret += "Cannot connect to R";
//		if (rProcessCount > 0) {
//			ret += ", but there " + ((rProcessCount > 1)? "are " + rProcessCount
//				+ " R processes": "is one R process") + " running.";
//			result += "\n\nR processes currently running:\n" + rProcess.join("\n");
//		} else if (rProcessCount == 0) {
//			ret += ",  R is not running.";
//		}
//	} else {
//		result = null;
//		ret += "Connection with R successful.";
//	}
//	//ko.dialogs.alert(ret, result, "R connection test");
//	sv.cmdout.append("R connection test:\n" + ret);
//	return connectionUp;
//}

this.testRAvailability = function(checkProc) {
	var result = _this.evalAtOnce("cat(123)");
	var connectionUp = result.indexOf("123") != -1;
	var ret;
	if(!connectionUp) {
		ret = "Cannot connect to R";
	} else {
		ret = "Connection with R successful.";
	}
	sv.cmdout.append("R connection test:\n" + ret);
	return connectionUp;
}

//_this.setObserver(rCallbackChunk, "r-command-chunk");
//_this.setObserver(rCallback, "r-command-executed");

// handles koCmd requests:
var defaultRequestHandler = function(str) {
	str = str.trim();
	//sv.cmdout.append(str);
	try {
		if (str.indexOf("<<<js>>>") == 0)
			return eval(str.substring(8));
		 else if(str.indexOf("<<<rjsonp>>>") == 0)
			return sv.rjson.eval(str.substring(12));
	} catch(e) {
		return e.message;
	}
	sv.cmdout.append(">>> " + str); // DEBUG
	return "Received: [" + str + "]"; // echo
}

this.__defineGetter__ ('serverIsUp', function () _svuSvc.serverIsUp() );

this.startSocketServer = function(requestHandler) {
	if(!requestHandler) requestHandler = defaultRequestHandler;
	var port = _svuSvc.startSocketServer({onStuff: requestHandler});

	if (!port) {
		ko.statusBar.AddMessage('Server could not be started', null, 2000, true);
	} else if (port > 0) {
		ko.statusBar.AddMessage('Server started at port ' + port, null, 2000);
		sv.pref.setPref("sciviews.ko.port", port, true, true);
		setTimeout(function() _this.evalAtOnce("options(ko.port=" + port + ")"), 1000);
	}
	return port;
}

var sServerDoRestart = false;

this.stopSocketServer = function() _svuSvc.stopSocketServer();

this.restartSocketServer = function(requestHandler) {
	if (_this.serverIsUp) {
		_this._sServerDoRestart = true;
		_this.stopSocketServer();
	} else {
		_this.startSocketServer(requestHandler);
	}
}

this._sServerObserver = { observe: function(subject, topic, data) {
	if (topic == 'r-server-stopped') {
		if (_this._sServerDoRestart) {
			_this.startSocketServer(); // TODO: use requestHandler
			_this._sServerDoRestart = false;
		}
		ko.statusBar.AddMessage('Server stopped', null, 2000);
	}
}}

var _socketPrefs = {
    "sciviews.r.port": null,
	"sciviews.r.host": null,
    "sciviews.ko.port": null
};

function _updateSocketInfo() {
	_svuSvc.setSocketInfo(_socketPrefs["sciviews.r.host"],
		parseInt(_socketPrefs["sciviews.ko.port"]), false);
	_svuSvc.setSocketInfo(_socketPrefs["sciviews.r.host"],
		parseInt(_socketPrefs["sciviews.r.port"]), true);
}

var _prefObserver = { observe: function(subject, topic, data) {
    _socketPrefs[topic] = sv.pref.getPref(topic);
	_updateSocketInfo();
}}

this.handlers = {};

var _REvalListener = function(callback, keep, args) {
	if (typeof callback == "function") this.callback = callback;
	this.keep = keep;
	this.args = Array.apply(null, args);
}
_REvalListener.prototype = {
	callback: null,
	keep: false,
	args: null,
	onDone: function(result, command, mode) {
		if (this.callback) {
			args = this.args;
			//args.unshift(result, command);
			if(result) result = result.trim();
			args.unshift(result);
			try{
				this.callback.apply(this, args);
			} catch(e) {
				sv.log.exception(e);
			}
			//[Exception... "Illegal operation on WrappedNative prototype
			//object" nsresult: "0x8057000c (NS_ERROR_XPC_BAD_OP_ON_WN_PROTO)"]
		}
		//if (mode == "e" || mode == "json")	_this.printResults(result, command, true);
		return this.keep;
	}
}

var _curPrompt = ':>';
var _curCommand = "";

var _waitMessageTimeout;


this.printCommandinfo = function(cinfo) {
	cinfo.QueryInterface(Components.interfaces.svICommandInfo);
	var result, prompt, styledResult;
	switch (cinfo.message) {
		case 'Not ready':
			result = '...';
			prompt = ':+';
		break;
		case 'Want more':
		break;
		case 'Parse error':
		case 'Done':
		default:
			styledResult = cinfo.result? cinfo.styledResult() : '';
	}

	var scimoz = sv.cmdout.scimoz;
	var readOnly = scimoz.readOnly;
	scimoz.readOnly = false;
	 // scimoz.gotoPos(sm.textLength); where?

	// add command (style as code)

	if (styledResult) scimoz.addStyledText(styledResult.length, styledResult);

	// add final prompt (style as code)

	scimoz.readOnly = readOnly;
}



this.printResults = function(result, command, executed, wantMore) {
	//alert(result + "\n" + command +  "\n" + executed);
	var msg;
	command = _curCommand + _curPrompt + ' ' + command + sv.cmdout.eolChar;
	window.clearTimeout(_waitMessageTimeout);

	if (executed) {
		//var newPrompt = _curPrompt;
		var newPrompt = wantMore? ':+' : ':>';
		result = result + '\n' + newPrompt;
		_curCommand = wantMore? command : '';
		_curPrompt = newPrompt;

		//var ff = result.lastIndexOf("\x0c"); // ("\f") = 3
		//if(ff != -1) {
		//	newPrompt = result.substr(ff + 1, 2);
		//	result = result.substr(0, ff) + newPrompt;
		//}
		//_curCommand = (newPrompt == ':+')? command : '';
		//_curPrompt = newPrompt;
		sv.cmdout.message(null);
	} else {
		//alert(result == null)
		result = '...';
		msg = 'R is calculating...';
		// display 'wait message' only for longer operations
		_waitMessageTimeout = window.setTimeout(sv.cmdout.message, 700, msg, 0, false);
	}

	sv.cmdout.print2(command, result, executed);
}

var _REvalObserver = {
	observe: function(subject, topic, data) {

		// TODO: use 'subject.result' instead of 'data'
		data = subject.result;

		var wantMore = false;
		switch(topic) {
			case 'r-command-executed':
				var cid = subject.commandId;
				switch(subject.message) {
				case 'Want more':
					wantMore = true;
					break;
				case 'Parse error':
					break; // Exec handler on parse error? I guess not.
					if (cid in _this.handlers && !keep)
						delete _this.handlers[cid];
				case 'Done':
					if (cid in _this.handlers) {
						var keep = _this.handlers[cid]
							.onDone(data.replace(/[\x02\x03]/g, ''), // strip control characters
								subject.command, subject.mode);
						if(!keep) delete _this.handlers[cid];
					}
					break;
				default:
				}
			case 'r-command-sent':
				sv.lastCmdInfo = subject;
				if (subject.mode.split(' ').indexOf('h') == -1) {
				//alert(subject.mode + ": " + subject.mode.split(' ').indexOf('h'));
					_this.printResults(data, subject.command,
						topic == 'r-command-executed', wantMore);
					// TODO: use subject.styledResult()
				}
				break;
			case 'r-command-chunk':
				//if (subject.mode == "e")
				//sv.cmdout.append(data, false);
				break;
			default:
		}
	}
}

//_obsSvc.addObserver(_REvalObserver, "r-command-chunk", false);
_obsSvc.addObserver(_REvalObserver, "r-command-sent", false);
_obsSvc.addObserver(_REvalObserver, "r-command-executed", false);
_obsSvc.addObserver(_this._sServerObserver, 'r-server-stopped', false);

//_obsSvc.removeObserver(_REvalObserver, "r-command-executed", false);
for(var i in _socketPrefs) {
	_socketPrefs[i] = sv.pref.getPref(i);
	sv.pref.prefset.prefObserverService.addObserver(_prefObserver, i, true);
}

_updateSocketInfo();
this.cleanUp = function sv_conn_debugCleanup() {
	["r-command-sent", "r-command-executed", "r-command-chunk",
	 'r-server-stopped'].forEach(function(notification) {
		try {
			var obsEnum = _obsSvc.enumerateObservers(notification);
			while (obsEnum.hasMoreElements()) {
				var observer = obsEnum.getNext();
				observer.QueryInterface(Components.interfaces.nsIObserver);
				_obsSvc.removeObserver(observer, notification, false);
			}
		} catch(e) {}
	})

	var prefObsSvc = sv.pref.prefset.prefObserverService;
	for(var pref in _socketPrefs) {
		try {
			var obsEnum = prefObsSvc.enumerateObservers(pref);
			while (obsEnum.hasMoreElements()) {
				var observer = obsEnum.getNext();
				observer.QueryInterface(Components.interfaces.nsIObserver);
				prefObsSvc.removeObserver(observer, pref, true);
			}
		} catch(e) { 	alert(e); }
	}
}


}).apply(sv.rconn);


//sv.r.evalCallback = function(cmd, procfun, context) {
//	var args = Array.apply(null, arguments)
//	args.splice(2,  0, true, null, false)
//	sv.rconn.eval.apply(sv.rconn, args)
//}
//sv.r.eval = function(cmd) sv.rconn.eval.call(sv.rconn, cmd)
//sv.r.evalHidden = function(cmd, earlyExit) sv.rconn.eval.call(sv.rconn, cmd)
//


// seems to be no problem with encoding (!!?)
//sv.rconn.eval("cat('pchn¹æ w tê ³ódŸ je¿a i óœm skrzyñ fig')") // Note this is CP1250 encoding


//sv.rconn.rEval("cat(1:10)", ko.dialogs.alert);
//result = sv.rconn.rEvalQuick("cat(1:10)");

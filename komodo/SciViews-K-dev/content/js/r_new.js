//{  }

// 's.rnew' object is an interface to R implemented mostly in python
// 		The workhorse is 'svUtils' XPCOM interface
//.command (Read only) last command evaluated
//.result (Read only) last result returned
//.getRProc(property) get information on currently running R processes
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


try { // in case we inject the script more then one time
	sv.rnew.removeObserver();
} catch(e) {}


sv.rnew = {};

(function() {
	var _this = this;
	this.port = 8888;
	this.serverPort = 7052;
	this.host = 'localhost';

// get string from nsISupportsString
function _str(sString) sString.QueryInterface(Components
	.interfaces.nsISupportsString).data;

var _svuSvc = Components.classes["@sciviews.org/svUtils;1"]
	.getService(Components.interfaces.svIUtils);
var _obsSvc = Components.classes["@mozilla.org/observer-service;1"]
    .getService(Components.interfaces.nsIObserverService);

var observers = {};
var obsCallback = function() { sv.cmdout.append("test")};

this.__defineGetter__ ('command', function () _svuSvc.lastCommand);
this.__defineGetter__ ('result', function () _svuSvc.lastResult);

// get list of running R processes
this.getRProc = function(property) {
	if (!property) property = "CommandLine";
	var procList = _svuSvc.getproc(property);
	proc = [];
	while(procList.hasMoreElements())
		proc.push(_str(procList.getNext()));
	return proc;
}

// Observer of 'r-command-executed' notification
function rObserver(topic, callback) this.register(topic, callback);
rObserver.prototype = {
	observe: function(subject, topic, data) {
		//ko.dialogs.alert(topic + ":\r\n" + data);
		this.callback(_svuSvc.lastCommand, data);
	},
	register: function(topic, callback) {
		if(callback) this.callback = callback;
		this.topic = topic;
		_obsSvc.addObserver(this, topic, false);
	},
	unregister: function() {
		_obsSvc.removeObserver(this, this.topic);
	},

	topic: null,
	callback: function(cmd, data) ko.dialogs.alert(cmd, data)
}

this.removeObserver = function(topic) {
	if (!topic)	for (var i in observers) {
		observers[i].unregister();
		delete observers[i];
	}
	else {
		observers[topic].unregister();
		delete observers[topic];
	}
}

// Set callback for executing R command
this.setObserver = function(callback, topic) {
	if(!topic) topic = "r-command-executed";

	try {
		_this.removeObserver(topic);
	} catch(e) {}
	observers[topic] = new rObserver(topic, callback);
}

this.enumObservers = function() {
	var ret = [];
	for (var i in observers) ret.push(observers[i]);
	return ret;
}

// Evaluate in R
this.rEval = function(command, callback, hidden) {
	if(callback) _this.setObserver(callback, "r-command-executed");
	_svuSvc.execInRBgr(command, _this.host, _this.port, hidden? "h" : "e");
}

// TODO: this should use <<<h>>>
// Evaluate in R quickly - and return result
this.rEvalQuick = function(command)
	_svuSvc.execInR(command, _this.host, _this.port, "h");


// For debugging purposes only
this.testRCommand = function(command) {
	if(!command) command = "sample(LETTERS, 10)";
	_svuSvc.execInRBgr(command, _this.host, _this.port, "e");
}

this.testRCommandNotify = function(chunk) {
	topic = "r-command" + (chunk? "chunk" : "executed");
	_obsSvc.notifyObservers(null, topic, "You are notified. {" + topic + "}");
}

var rCallback = function(cmd, res) {
	//sv.cmdout.clear();
	sv.cmdout.append("::>"+ cmd + ": END")
}

var rCallbackChunk = function(cmd, res) {
	sv.cmdout.append("\n<++CHUNK++>\n"+ res, false)
}

this.testRAvailability = function(checkProc) {
	var result = _this.rEvalQuick("cat(1)").trim();
	var connectionUp = result == "1";
	var rProcess = checkProc? _this.getRProc() : undefined;
	var rProcessCount = (rProcess == undefined)? -1 : rProcess.length;
	ret = '';
	if(!connectionUp) {
		ret += "Cannot connect to R";
		if (rProcessCount > 0) {
			ret += ", but there " + ((rProcessCount > 1)? "are " + rProcessCount
				+ " R processes": "is one R process") + " running.";
			result += "\n\nR processes currently running:\n" + rProcess.join("\n");
		} else if (rProcessCount == 0) {
			ret += ",  R is not running.";
		}
	} else {
		result = null;
		ret += "Connection with R successful.";
	}
	//ko.dialogs.alert(ret, result, "R connection test");
	sv.cmdout.append("R connection test:\n" + ret + "\n"  + result);
	return connectionUp;
}

_this.setObserver(rCallbackChunk, "r-command-chunk");
_this.setObserver(rCallback, "r-command-executed");

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
	sv.cmdout.append(str);
	return "Received: [" + str + "]"; // echo
}


this.startSocketServer = function(requestHandler) {
	_this.host = sv.prefs.getString("sciviews.server.host");
	_this.serverPort = parseInt(sv.prefs.getString("sciviews.server.socket"));

	if(!requestHandler) requestHandler = defaultRequestHandler;
	return _svuSvc.startSocketServer(_this.host, _this.serverPort, {onStuff: requestHandler});
}

this.stopSocketServer = function() _svuSvc.stopSocketServer();

addEventListener("load", function() {
	sv.command.updateRStatus(_this.testRAvailability(false));
	_this.startSocketServer();
}, false);


}).apply(sv.rnew);


// seems to be no problem with encoding (!!?)
//sv.rnew.testRCommand("cat('pchn¹æ w tê ³ódŸ je¿a i óœm skrzyñ fig')") // Note this is CP1250 encoding


//sv.rnew.rEval("cat(1:10)", ko.dialogs.alert);
//result = sv.rnew.rEvalQuick("cat(1:10)");

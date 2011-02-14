//{  }

// 's.rnew' object is an interface to R implemented mostly in python
// 		The workhorse is 'svUtils' XPCOM interface
//.command (Read only) last command evaluated
//.result (Read only) last result returned
//.getRProc(property) get information on currently running R processes
//		(property is one of 'Handle','ProcessId' or 'CommandLine'
//.setObserver(callback) set callback function for R command
//.removeObserver
//.rEval(command, callback) evaluate in R, optional callback (if not provided,
//		the most recent one is used)
//.rEvalQuick(command) - do 'quick' evaluation in R, and
//return the result



sv.rnew = {};

(function() {
	var _this = this;

// get string from nsISupportsString
function _str(sString) sString.QueryInterface(Components
	.interfaces.nsISupportsString).data;

var _svuSvc = Components.classes["@sciviews.org/svUtils;1"]
	.getService(Components.interfaces.svIUtils);
var _obsSvc = Components.classes["@mozilla.org/observer-service;1"]
    .getService(Components.interfaces.nsIObserverService);

var observer;
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
function rObserver() this.register();
rObserver.prototype = {
	observe: function(subject, topic, data) {
		//ko.dialogs.alert(topic + ":\r\n" + data);
		obsCallback(_svuSvc.lastCommand, data);
	},
	register: function() {
		_obsSvc.addObserver(this, "r-command-executed", false);
	},
	unregister: function() {
		_obsSvc.removeObserver(this, "r-command-executed");
	}
}

this.removeObserver = function() {
	observer.unregister();
	callback = function() {};
}

// Set callback for executing R command
this.setObserver = function(callback) {
	try {
		_this.removeObserver();
	} catch(e) {}
	observer = new rObserver();
	if (callback) obsCallback = callback;
}


// Evaluate in R
this.rEval = function(command, callback) {
	if(callback) _this.setObserver(callback);
	_svuSvc.execInRBgr(command, 'localhost', 8888);
}

// TODO: this should use <<<h>>>
// Evaluate in R quickly - and return result
this.rEvalQuick = function(command)
	_svuSvc.execInR(command, 'localhost', 8888);


// For debugging purposes only
this.testRCommand = function(command) {
	if(!command) command = "sample(LETTERS, 10)";
	_svuSvc.execInRBgr(command, 'localhost', 8888);
}

this.testRCommandNotify = function() {
	_obsSvc.notifyObservers(null, "r-command-executed", "!!!");
}

}).apply(sv.rnew);


// seems to be no problem with encoding (!!?)
//sv.rnew.testRCommand("cat('pchn¹æ w tê ³ódŸ je¿a i óœm skrzyñ fig')")

var rCallback = function(cmd, res) {
	sv.cmdout.clear();
	sv.cmdout.append("::>"+ cmd + "\n" + res)
}

//sv.rnew.rEval("cat(1:10)", ko.dialogs.alert);
//result = sv.rnew.rEvalQuick("cat(1:10)");

// SciViews-K file related functions
// Various file related functions in 'sv.tools.file' namespace
// Copyright (c) 2008-2009, Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.tools.file.defaultEncoding;			// Default file encoding to use
// sv.tools.file.read(filename, encoding);	// Read a file with encoding
// sv.tools.file.write(filename, content, encoding, append);
								// Write in a file with encoding
// sv.tools.file.exists(file); 	// Checks for file existence, returns 2 for
								// directory, 1 for file, otherwise 0
// sv.tools.file.temp(prefix);	// Creates unique temporary file, accessible
								// by all users, and returns its name
// sv.tools.file.specDir(dirName)	// Translate special directory name
// sv.tools.file.path(...); 		// Create a file path from concatenated arguments:
								// - special directory names are translated,
								// - relative paths are expanded into real paths.
// sv.tools.file.getfile(baseDir, [pathComponents]);
								// Create nsILocalFile object from array and/or
								// special dir name
// sv.tools.file.readURI(uri);	// Read data from an URI
// sv.tools.file.list(dirname, pattern, noext); // List all files matching
								// pattern in dirname (with/without extension)
// sv.tools.file.whereIs(appName);
								// Tries to find full application path,
								// returns null if not found
////////////////////////////////////////////////////////////////////////////////

if (typeof(sv) == 'undefined')
	var sv = {};

// Define the 'sv.tools' namespace
if (typeof(sv.tools) == 'undefined')
	sv.tools = {};
// Define the 'sv.tools.file' namespace
if (typeof(sv.tools.file) == 'undefined')
	sv.tools.file = {};

(function () {
	// Default file encoding to use
	this.defaultEncoding = "latin1";
	this.TYPE_DIRECTORY = 2;
	this.TYPE_FILE = 1;
	this.TYPE_NONE = 0;

	// Read a file with encoding
	this.read = function (filename, encoding) {
		if (!encoding)
			encoding = this.defaultEncoding;

		var file = Components.classes["@mozilla.org/file/local;1"]
			.createInstance(Components.interfaces.nsILocalFile);
		var fis = Components.classes["@mozilla.org/network/file-input-stream;1"]
			.createInstance(Components.interfaces.nsIFileInputStream);
		var is = Components.classes["@mozilla.org/intl/converter-input-stream;1"]
			.createInstance(Components.interfaces.nsIConverterInputStream);

		try {
			file.initWithPath(filename);
			fis.init(file, -1, -1, 0);
			is.init(fis, encoding, 1024, 0xFFFD);

			var ret = "";
			if (is instanceof Components.interfaces.nsIUnicharLineInputStream) {
				var str = {};
				var cont;
				do {
					cont = is.readString(4096, str);
					ret += str.value;
				} while (cont);
			}
		} catch (e) {
			sv.log.exception(e, "Error while trying to read " + filename, true);
		}
		finally {
			is.close();
			fis.close();
		}
		return ret;
	}

	// Write in a file with encoding
	this.write = function (filename, content, encoding, append) {
		if (!encoding)
			encoding = this.defaultEncoding;

		append = append? 0x10 : 0x20;

		var file = Components.classes["@mozilla.org/file/local;1"]
			.createInstance(Components.interfaces.nsILocalFile);
		var fos = Components.classes["@mozilla.org/network/file-output-stream;1"]
			.createInstance(Components.interfaces.nsIFileOutputStream);
		var os = Components.classes["@mozilla.org/intl/converter-output-stream;1"]
			.createInstance(Components.interfaces.nsIConverterOutputStream);

		//PR_CREATE_FILE = 0x08	PR_WRONLY 	 = 0x02
		//PR_APPEND 	 = 0x10		PR_TRUNCATE 	 = 0x20

		try {
			file.initWithPath(filename);
			fos.init(file, 0x08 | 0x02 | append, -1, 0);
			os.init(fos, encoding, 0, 0x0000);
			os.writeString(content);
		} catch (e) {
			sv.log.exception(e, "Error while trying to write in " + filename +
				" (sv.tools.file.write)", true)
		} finally {
			os.close();
		}
	}

	// Checks for file existence, returns 2 for dir, 1 for file, otherwise 0
	this.exists = function (path) {
		var file = Components.classes["@mozilla.org/file/local;1"].
			createInstance(Components.interfaces.nsILocalFile);

		try {
			file.initWithPath(path);
		} catch(e) {
			return this.TYPE_NONE;
		}

		if (file.exists()) {
			if (file.isDirectory())
				return this.TYPE_DIRECTORY;
			else if (file.isFile())
				return this.TYPE_FILE;
		}
		return 0;
	}

	// Creates unique temporary file, accessible by all users; returns its name
	this.temp = function (prefix) {
		var nsIFile = Components.interfaces.nsIFile;
		var dirSvc = Components.classes["@mozilla.org/file/directory_service;1"].
			 getService(Components.interfaces.nsIProperties);
		var tempDir = dirSvc.get("TmpD", nsIFile).path;
		var tmpfile = Components.classes["@mozilla.org/file/local;1"].
			createInstance(Components.interfaces.nsILocalFile);

		if (!prefix)	prefix = "svtmp";

		tmpfile.initWithPath(tempDir);
		tmpfile.append(prefix)
		tmpfile.createUnique(nsIFile.NORMAL_FILE_TYPE, 0777);

		return tmpfile.path;
	}


	this.specDir = function(dirName) {
		var file;
		if (dirName == "~")
			dirName = (navigator.platform.indexOf("Win") == 0)? "Pers" : "Home";

		try {
			try {
				file = Components.classes["@mozilla.org/file/directory_service;1"]
					.getService(Components.interfaces.nsIProperties)
					.get(dirName, Components.interfaces.nsILocalFile)
					.path;
			} catch(e) {
				// if above fails, try Komodo directories too:
				var dirs = Components.classes['@activestate.com/koDirs;1']
					.getService(Components.interfaces.koIDirs);
				if (dirs.propertyIsEnumerable(dirName))
					file = dirs[dirName];
			}

		} catch(e) {}
		return file? file : dirName;
	}

	// Create nsILocalFile object from path
	// concatenates arguments if needed
	this.getfile = function (path) {
		path = this.path.apply(this, Array.apply(null, arguments));
		//return path;
		var file = Components.classes["@mozilla.org/file/local;1"].
			createInstance(Components.interfaces.nsILocalFile);
		file.initWithPath(path);
		return file;
	}

	// Concatenate the arguments into a file path.
	// First element of a path can be a name of a special directory:
	// 	eg. "ProfD", "TmpD", "Home", "Pers", "Desk", "Progs". For all possibilities,
	//	see reference at https://developer.mozilla.org/En/Code_snippets:File_I/O
	// Additionally, Komodo paths are translated:
	//  "userDataDir", "supportDir", "hostUserDataDir", "factoryCommonDataDir",
	//  "commonDataDir, "userCacheDir", "sdkDir", "docDir", "installDir", "mozBinDir",
	//  "binDir", "pythonExe", "binDBGPDir", "perlDBGPDir" and "pythonDBGPDir".
	// Leading "~" is expanded to a path of a home directory ("My documents" on windows).
	// Following arguments can be specified as single array or string
	// example: sv.tools.file.path("~/workspace/dir1", "dir2", "file1.tmp")
	// would produce something like that:
	// "c:\users\bob\MyDocuments\workspace\dir1\dir2\file1.tmp"
	// "/home/bob/workspace/dir1/dir2/file1.tmp"
	this.path = function (path) {
		var os = Components.classes['@activestate.com/koOs;1'].
			getService(Components.interfaces.koIOs);
		var sep = os.sep;
		if (typeof path.join == "undefined")
			path = Array.apply(null, arguments);
		// 'flatten' the array:
			var res = [];
			for(i in path) res = res.concat(path[i]);
			path = res;
		path = os.path.normpath(path.join(sep));
		var dir0 = path.split(sep, 1)[0];
		path = sv.tools.file.specDir(dir0) + path.substring(dir0.length);
		path = os.path.abspath(path);
		return path;
	}
	this.getURI = function(file) {
		if (typeof file == "string") {
			file = this.getfile(file);
		}
		if (!file)	return null;

		var ios = Components.classes["@mozilla.org/network/io-service;1"].
                    getService(Components.interfaces.nsIIOService);
		var URL = ios.newFileURI(file);
		return URL.spec;
	}

	// Read data from an URI
	this.readURI = function (uri) {
		var fileSvc = Components.classes["@activestate.com/koFileService;1"]
			.getService(Components.interfaces.koIFileService);
		var file = fileSvc.getFileFromURI(uri);
		file.open('r');
		var res = file.readfile();
		file.close();
		return res;
	}

	// List all files matching a given pattern in directory,
	// python interface - ~2x faster than with nsILocalFile
	this.list = function (dirname, pattern, noext) {
			var os = Components.classes['@activestate.com/koOs;1']
				.getService(Components.interfaces.koIOs);

			if (os.path.exists(dirname) && os.path.isdir(dirname)) {
				var files = os.listdir(dirname, {});
				var selfiles = [], file;
				for (i in files) {
					file = files[i];
					if (os.path.isfile(os.path.join(dirname, file))
						&& file.search(pattern) != -1) {

						file = noext? file.substring(0, file.lastIndexOf("."))
							: file;
						selfiles.push(file);
					}
				}
				return (selfiles);
			} else {
				return null;
			}

		return(null);
	}

// TODO: check registry keys for Windows versions other than XP
if (navigator.platform.indexOf("Win") == 0) {
	function _findFileInPath(file) {
		var os = Components.classes['@activestate.com/koOs;1'].
			getService(Components.interfaces.koIOs);
		var dirs = os.getenv("PATH").split(os.pathsep);
		var res = [];
		for (i in dirs)
			if (os.path.exists(os.path.join(dirs[i], file))) res.push(dirs[i]);
		return res.length? res : null;
	}

	this.whereIs = function(appName) {
		// add default extension for executable if none
		if (appName.search(/\.[^\.]{3}$/) == -1) 	appName += ".exe";

		var reg = Components.classes["@mozilla.org/windows-registry-key;1"]
			.createInstance(Components.interfaces.nsIWindowsRegKey);
		var key, path;

		//alert(appName);

		// Special treatment for R* apps:
		if (appName.match(/^R(?:gui|term|cmd)?\.exe$/i)) {
			try {
				key = "software\\R-core\\R";
				reg.open(reg.ROOT_KEY_LOCAL_MACHINE, key, reg.ACCESS_READ)
			} catch(e) {
				key = "software\\wow6432Node\\r-core\\r";
				reg.open(reg.ROOT_KEY_LOCAL_MACHINE, key, reg.ACCESS_READ);
			}
			if (!reg.hasValue("InstallPath") && reg.hasValue("Current Version")) {
				reg = reg.openChild(reg.readStringValue("Current Version"),
									reg.ACCESS_READ);
			}
			if (reg.hasValue("InstallPath"))
				return reg.readStringValue("InstallPath") + "\\bin\\" + appName;
		}

		var key = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\" + appName;
		try {
			reg.open(reg.ROOT_KEY_LOCAL_MACHINE, key, reg.ACCESS_READ);
			path = reg.readStringValue("");
			return path.replace(/(^"|"$)/g, "");
		} catch(e) {
			var key = "Applications\\" + appName + "\\shell\\Open\\Command";
			try {
				reg.open(reg.ROOT_KEY_CLASSES_ROOT, key, reg.ACCESS_READ);
				path = reg.readStringValue("");
				path = path.replace(/(^"+|"*\s*"%\d.*$)/g, "");
				return path;
			} catch(e) {
				// fallback: look for app in PATH:
				return _findFileInPath(appName);
			}
		}
		return null;
	}

} else {
	// Will it work on Mac too?
	this.whereIs = function(appName) {
		var runSvc = Components.
			classes["@activestate.com/koRunService;1"].
			getService(Components.interfaces.koIRunService);
		var err = {}, out = {};
		var res = runSvc.RunAndCaptureOutput("which " + appName,
			null, null, null, out, err);

		var path = sv.tools.strings.trim(out.value);

		if (!path) return null;
		return path.split(" ");
	}

}


}).apply(sv.tools.file);

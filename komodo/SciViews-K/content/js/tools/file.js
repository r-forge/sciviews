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
// sv.tools.file.path(baseDir, ...); 		// Create path from array, and/or
											// special directory name
// sv.tools.file.getfile(baseDir, [pathComponents]);
								// Create nsILocalFile object from array and/or
								// special dir name
// sv.tools.file.readURI(uri);	// Read data from an URI
// sv.tools.file.list(dirname, pattern, noext); // List all files matching
								// pattern in dirname (with/without extension)
////////////////////////////////////////////////////////////////////////////////

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

			ret = "";
			if (is instanceof Components.interfaces.nsIUnicharLineInputStream) {
				var str = {};
				var cont;
				do {
					cont = is.readString(4096, str);
					ret += str.value;
				} while (cont);
			}
		} catch (e) {
			sv.log.exception(e, "Error while trying to read in " + filename +
				" (sv.tools.file.read)", true);
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
		}
		finally {
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

		if (!prefix)
			prefix = "svtmp";

		tmpfile.initWithPath(tempDir);
		tmpfile.append(prefix)
		tmpfile.createUnique(nsIFile.NORMAL_FILE_TYPE, 0777);

		return tmpfile.path;
	}

	// Create nsILocalFile object from array and/or special dir name
	this.getfile = function (baseDir, pathComponents) {
		sv.cmdout.append(".getfile: " + baseDir + " + " + pathComponents);

		if (typeof pathComponents != "undefined"
			&& typeof pathComponents != "object") {
			throw TypeError ("Second argument must be an array");
		}

		var file, baseFile;
		if (baseDir) {
			try {
				try {
					file = Components.classes["@mozilla.org/file/directory_service;1"]
						.getService(Components.interfaces.nsIProperties).
						get(baseDir, Components.interfaces.nsILocalFile);
				} catch(e) {

					// if above fails, try Komodo directories too:
					var dirs = Components.classes['@activestate.com/koDirs;1']
						.getService(Components.interfaces.koIDirs);
					if (dirs.propertyIsEnumerable(baseDir)) {
						baseDir = dirs[baseDir];
					}
				}

				if (!file) {
					file = Components.classes["@mozilla.org/file/local;1"].
							createInstance(Components.interfaces.nsILocalFile);
					try {
							file.initWithPath(baseDir);
					} catch (e) {
						sv.log.exception(e,
							"sv.tools.file.getfile: file.initWithPath(" + baseDir + ")");
						return null;
					}
				}
			} catch(e) {	}
		}
		if (pathComponents && pathComponents.length) {
			for (i in pathComponents) {
				if (pathComponents[i] == "..")
					file.initWithFile(file.parent);
				else if (pathComponents[i] != ".")
					file.appendRelativePath(pathComponents[i]);
			}
		}
		return file;
	}

	// Concatenate the arguments into a file path.
	// baseDir - can be a name for special directory, see special directory
	// reference at https://developer.mozilla.org/En/Code_snippets:File_I/O
	// eg. "ProfD", "TmpD", "Home", "Pers", "Desk", "Progs"
	// or leading "~" is expanded to a real path.
	// Following arguments can be specified as single array or string
	// example: sv.tools.file.path("~/workspace/dir1", "dir2", "file1.tmp")
	// would produce something like that:
	// "c:\users\bob\MyDocuments\workspace\dir1\dir2\file1.tmp"
	// "/home/bob/workspace/dir1/dir2/file1.tmp"
	this.path = function (baseDir, pathComponents) {
		try {
			if (!baseDir)
				return null;
			if (!pathComponents)
				pathComponents = [];
			else if (typeof pathComponents == "string") {
				var pc = Array.apply(null, arguments);
				pc.shift(1);
				pathComponents = pc;
			}

			var os = Components.classes['@activestate.com/koOs;1'].
				getService(Components.interfaces.koIOs);

			var pathSep = os.sep;

			baseDir = baseDir.replace(/[\\/]+/g, pathSep);
			if (baseDir[0] == "~") {
				pathComponents.unshift(baseDir.replace(/^~[\\/]*/, ""));
				baseDir = (navigator.platform.
					indexOf("Win") == 0)? "Pers" : "Home";
			}
			return this.getfile(baseDir, pathComponents).path;
		} catch (e) { return null; }
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

	// List all files matching a given pattern in directory
	this.list = function (dirname, pattern, noext) {
		try {
			var dir = Components.classes["@mozilla.org/file/local;1"].
				createInstance(Components.interfaces.nsILocalFile);
			dir.initWithPath(dirname);
			if (dir.exists() && dir.isDirectory()) {
				var files = dir.directoryEntries;
				var selfiles = [];
				var files;
				while (files.hasMoreElements()) {
					file = files.getNext().
						QueryInterface(Components.interfaces.nsILocalFile);
					if (file.isFile() && file.leafName.search(pattern) > -1) {
						if (noext) {
							selfiles.push(file.leafName.replace(pattern, ""));
						} else {
							selfiles.push(file.leafName);
						}
					}
				}
				return(selfiles);
			}
		} catch (e) {
			sv.log.exception(e, "Error while listing files " + dirname +
				" (sv.tools.file.list)", true)
		}
		return(null);
	}

/*
	// List all files matching a given pattern in directory, python interface
	this.list = function (dirname, pattern, noext) {
			var os = Components.classes['@activestate.com/koOs;1']
				.getService(Components.interfaces.koIOs);


			if (os.path.exists(dirname) && os.path.isdir(dirname)) {
				var files = os.listdir(dirname, {});
				var selfiles = [], file;
				for (i in files) {
					file = files[i];
					if (os.path.isfile(os.path.join(dirname, file)) && file.search(pattern) != -1) {
						file = noext? os.path.withoutExtension(file) : file;
						selfiles.push(file);
					}
				}
				return (selfiles);
			} else {
				return null;
			}

		return(null);
	}
*/
}).apply(sv.tools.file);

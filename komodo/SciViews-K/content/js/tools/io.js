// SciViews-K IO functions
// Various file related functions in 'sv.io' namespace'
// Copyright (c) 2008-2009, Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.io.defaultEncoding				// Default file encoding to use
// sv.io.readfile(filename, encoding);	// Read a file with encoding
// sv.io.writefile(filename, content, encoding, append);
										// Write in a file with encoding
//sv.io.fileExists(file); 				// Checks for file existence
										// returns 2 for directory, 1 for file,
										// otherwise 0
//sv.io.tempFile(prefix);				// creates unique temporary file,
										// accessible by all users, and returns
										// its name
//sv.io.makePath(baseDir, ...); // create path from array,
										// and/or special directory name
//sv.io.file(baseDir, [pathComponents]); // create nsILocalFile object from array,
										// and/or special directory name
// sv.io.readURI(uri);					// Read data from an URI
////////////////////////////////////////////////////////////////////////////////

// TODO: this are not only i/o functions anymore, rename to something like
// sv.fileUtils ...


// Define the 'sv.io' namespace
if (typeof(sv.io) == 'undefined')
	sv.io = {};

(function() {
	this.defaultEncoding = "latin1";

	this.readfile = function (filename, encoding) {
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
				" (sv.io.readfile)", true);
		}
		finally {
			is.close();
			fis.close();
		}
		return ret;
	}

	this.writefile = function (filename, content, encoding, append) {
		if (!encoding)
			encoding = this.defaultEncoding;

		append = append? 0x10 : 0x20;

		var file = Components.classes["@mozilla.org/file/local;1"]
			.createInstance(Components.interfaces.nsILocalFile);
		var fos = Components.classes["@mozilla.org/network/file-output-stream;1"]
			.createInstance(Components.interfaces.nsIFileOutputStream);
		var os = Components.classes["@mozilla.org/intl/converter-output-stream;1"]
			.createInstance(Components.interfaces.nsIConverterOutputStream);

		//PR_CREATE_FILE = 0x08
		//PR_WRONLY 	 = 0x02
		//PR_APPEND 	 = 0x10
		//PR_TRUNCATE 	 = 0x20

		try {
			file.initWithPath(filename);
			fos.init(file, 0x08 | 0x02 | append, -1, 0);
			os.init(fos, encoding, 0, 0x0000);
			os.writeString(content);
		} catch (e) {
			sv.log.exception(e, "Error while trying to write in " + filename +
				" (sv.io.writefile)", true)
		}
		finally {
			os.close();
		}
	}

	this.fileExists = function (path) {
		var file = Components.classes["@mozilla.org/file/local;1"].
			createInstance(Components.interfaces.nsILocalFile);

		try {
			file.initWithPath(path);
		} catch(e) {
			return 0;
		}

		if (file.exists()) {
			if (file.isDirectory())
				return 2;
			else if (file.isFile())
				return 1;
		}
		return 0;
	}

	this.tempFile = function (prefix) {
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

	this.file = function (baseDir, pathComponents) {
		var file, baseFile;
		if (baseDir) {
			try {
				file = Components.classes["@mozilla.org/file/directory_service;1"].
					getService(Components.interfaces.nsIProperties).
					get(baseDir, Components.interfaces.nsILocalFile);
			} catch(e) {
				file = Components.classes["@mozilla.org/file/local;1"].
					createInstance(Components.interfaces.nsILocalFile);
				try {
					file.initWithPath(baseDir);
				} catch (e) {
					return null;
				}
			}
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

	// concatenates ist arguments into a file path.
	// baseDir - can be a name for special directory, see special directory
	// reference at https://developer.mozilla.org/En/Code_snippets:File_I/O
	// eg. "ProfD", "TmpD", "Home", "Pers", "Desk", "Progs"
	// or
	// leading "~" is expanded to a real path
	// following arguments can be specified as single array or string
	// example: sv.io.makePath("~/workspace/dir1", "dir2", "file1.tmp")
	// would produce something like that:
	// "c:\users\bob\MyDocuments\workspace\dir1\dir2\file1.tmp"
	// "/home/bob/workspace/dir1/dir2/file1.tmp"
	this.makePath = function (baseDir, pathComponents) {
		if (!baseDir)
			return null;
		if (!pathComponents)
			pathComponents = [];
		else if (typeof pathComponents == "string") {
			var pc = [];
			for (var i = 1; i < arguments.length; i++)
				if (typeof arguments[i] != "undefined")
					pc.push(arguments[i]);
			pathComponents = pc;
		}

		var pathSep = Components.classes['@activestate.com/koOs;1'].
			getService(Components.interfaces.koIOs).sep;

		baseDir = baseDir.replace(/[\\/]+/g, pathSep);
		if (baseDir[0] == "~") {
			pathComponents.unshift(baseDir.replace(/^~[\\/]*/, ""));
			baseDir = (navigator.platform.indexOf("Win") == 0)? "Pers" : "Home";
		}
		return this.file(baseDir, pathComponents).path;
	}

	this.readURI = function (uri) {
		var fileSvc = Components.classes["@activestate.com/koFileService;1"]
			.getService(Components.interfaces.koIFileService);
		var file = fileSvc.getFileFromURI(uri);
		file.open(0);
		var res = file.readfile();
		file.close();
		return res;
	}

}).apply(sv.io);

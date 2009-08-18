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
//sv.io.makePath([specialDir], [pathComponents]); // create path from array,
										// and/or special directory name
// sv.io.readURI(uri);					// Read data from an URI
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.io' namespace
if (typeof(sv.io) == 'undefined') sv.io = new Object();

sv.io.defaultEncoding = "latin1";

sv.io.readfile = function (filename, encoding) {
	if (!encoding)
		encoding = sv.io.defaultEncoding;

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

sv.io.writefile = function (filename, content, encoding, append) {
	if (!encoding)
		encoding = sv.io.defaultEncoding;

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

sv.io.fileExists = function (path) {
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

sv.io.tempFile = function (prefix) {
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

//specialDir - [optional] name for special directory, see special directory
// reference at https://developer.mozilla.org/En/Code_snippets:File_I/O
// eg. ProfD, TmpD, Home, Desk, Progs
// pathComponents - [optional] array of directiory/file names to append
sv.io.makePath = function (specialDir, pathComponents) {
	var file;
	if (specialDir) {
		file = Components.classes["@mozilla.org/file/directory_service;1"].
			getService(Components.interfaces.nsIProperties).
			get(specialDir, Components.interfaces.nsIFile);
	} else {
		file = Components.classes["@mozilla.org/file/local;1"].
			createInstance(Components.interfaces.nsILocalFile);
		try {
			if (pathComponents) {
				file.initWithPath(pathComponents[0]);
				pathComponents.shift();
			}
		} catch (e) {}
	}
	if (pathComponents && pathComponents.length) {
		for (i in pathComponents)
			file.append(pathComponents[i]);
	}
	return file.path;
}

sv.io.readURI = function (uri) {
	var fileSvc = Components.classes["@activestate.com/koFileService;1"]
		.getService(Components.interfaces.koIFileService);
	var file = fileSvc.getFileFromURI(uri);
	file.open(0);
	var res = file.readfile();
	file.close();
	return res;
}

/*
Stuff:

var nsIFile = Components.interfaces.nsIFile;
var dirSvc = Components.classes["@mozilla.org/file/directory_service;1"].
    getService(Components.interfaces.nsIProperties);

var file = Components.classes["@mozilla.org/file/local;1"].
	createInstance(Components.interfaces.nsILocalFile);

// profile directory:
var profileDir = dirSvc.get("ProfD", nsIFile );
//C:\Documents and Settings\kamil\Dane aplikacji\ActiveState\KomodoEdit\5.0\host-DeepThought\XRE
*/

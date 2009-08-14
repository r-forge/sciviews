// SciViews-K functions
// Various functions to manipulate strings
// by Philippe Grosjean, Romain Francois and Kamil Barton

////////////////////////////////////////////////////////////////////////////////
// sv.tools.strings.replaceCRLF(str, code);	// Replace LF and CR by 'code'
// sv.tools.strings.removeLastCRLF(str);    // Remove last CR and/or LF
// sv.tools.strings.toRegex(str);			// changes a string to a regex
//
// Additional methods to String objects ////////////////////////////////////////
// String.prototype.trim();					// Trim function for String
// String.prototype.rtrim();				// Right trim
// String.prototype.ltrim();				// Left trim
// String.prototype.addslashes();			// Add slashes
////////////////////////////////////////////////////////////////////////////////


// Define the 'sv.tools.strings' namespace
if (typeof(sv.tools.strings) == 'undefined') sv.tools.strings = new Object();

// Replace line feed and carriage return by 'code'
sv.tools.strings.replaceCRLF = function(str, code) {
	// Replace all \r\n by 'code' in cmd
	str = str.replace(/(\r?\n|\r)/g, code);
	return(str);
}

// Remove the last line feed and or carriage return in the text
sv.tools.strings.removeLastCRLF = function(str) {
	str = str.replace( /[\n\r]{1,2}$/, "");
    return(str);
}

// changes a string to a regular expression
sv.tools.strings.toRegex = function(str){
	// brackets
	str = str.replace( /([\(\)\[\]])/g, "\\$1" );

	// TODO: anything else
	return( str ) ;
}


// Additional methods to String objects ////////////////////////////////////////

// Trim function for String
String.prototype.trim = function() {
	return this.replace(/^\s+|\s+$/g, '');
}
// Right trim
String.prototype.rtrim = function() {
	return this.replace(/\s+$/, '');
}

// Left trim
String.prototype.ltrim = function() {
	return this.replace(/^\s+/, '');
}

// Add slashes
String.prototype.addslashes = function() {
	// original by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
	return this.replace(/([\\"'])/g, "\\$1").replace(/\x00/g, "\\0");
}

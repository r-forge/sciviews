// SciViews-K functions
// Various functions to manipulate strings
// by Philippe Grosjean and Romain Francois

////////////////////////////////////////////////////////////////////////////////
// sv.tools.strings.replaceCRLF(str, code); // Replace LF and CR by 'code'
// sv.tools.strings.removeLastCRLF(str);    // Remove last CR and or LF
// sv.tools.strings.toRegex;                // changes a string to a regular expression
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.tools.strings' namespace
if (typeof(sv.tools.strings) == 'undefined') sv.tools.strings = new Object();

// Replace line feed and carriage return by 'code'
sv.tools.strings.replaceCRLF = function(str, code) {
	// Replace all \r\n by 'code' in cmd
	while (str.indexOf("\r\n") > -1) {
		str = str.replace("\r\n", code);
	}
	// Replace all \n by 'code' in cmd
	while (str.indexOf("\n") > -1) {
		str = str.replace("\n", code);
	}
	// Replace all \r by 'code' in cmd
	while (str.indexOf("\r") > -1) {
		str = str.replace("\r", code);
	}
	return(str);
}

// Remove the last line feed and or carriage return in the text
sv.tools.strings.removeLastCRLF = function(str) {
	str = str.replace( /[\n\r]{1,2}$/, "");
    return(str);
}

// changes a string to a regular expression
sv.tools.strings.toRegex = function(str){
	// round brackets
	str = str.replace( /\(/g, "\\(" );
	str = str.replace( /\)/g, "\\)" );
	
	// square brackets
	str = str.replace( /\[/g, "\\[" );
	str = str.replace( /\]/g, "\\]" );
	
	// TODO: anything else
	return( str ) ;
}


// SciViews-K array functions
// Various functions to manipulate arrays, 'sv.tools.array' namespace'
// Copyright (c) 2008-2009, Romain Francois and Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.tools.array.remove(a, s);     // Eliminate 's' from 'a'
// sv.tools.array.contains(a, s);   // Does array 'a' contain 's'
// sv.tools.array.removeItem(a, s); // Return an array with 's' removed from 'a'
//
// Additional methods to Array objects /////////////////////////////////////////
// Note: not used yet and generates an error in loading Komodo! => disabled!
// Array.prototype.makeunique();	// New array with duplicate values removed
// Array.prototype.getintersect(); 	// Compute the intersection of n arrays
// Array.prototype.rassemble();		// Get the union of n arrays
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.tools.array' namespace
if (typeof(sv.tools.array) == 'undefined') sv.tools.array = {};

// Remove 's' from the array 'a'
sv.tools.array.remove = function (a, s) {
	for (i = 0; i < a.length; i++)
		if (s == a[i]) a.splice(i, 1);
}

// Does the array 'a' contain 's'?
sv.tools.array.contains = function (a, s) {
	return (a.indexOf(s) !== -1);
}

// Return an array from which 's' item is eliminated from the array 'a'
sv.tools.array.removeItem = function (a, s) {
	var b = [];
	for (i in a)
		if (i != s) b[i] = a[i]
	return(b);
}

sv.tools.array.unique = function(a) {
    var res = [];
    var l = a.length;
	for (var i in a) {
		if (res.indexOf(a[i]) != -1) continue;
		res.push(a[i]);
	}
	return res;
}



//// Additional methods to Array objects ///////////////////////////////////////
//// Return new array with duplicate values removed
//
//// Compute the intersection of n arrays
//Array.prototype.getintersect = function () {
//	if (!arguments.length)
//		return [];
//    var a1 = this;
//    var a = a2 = null;
//    var n = 0;
//    while(n < arguments.length) {
//		a = [];
//		a2 = arguments[n];
//		var l = a1.length;
//		var l2 = a2.length;
//		for (var i=0; i<l; i++) {
//			for (var j=0; j<l2; j++) {
//				if (a1[i] === a2[j])
//					a.push(a1[i]);
//			}
//		}
//		a1 = a;
//		n++;
//    }
//    return a.makeunique();
//};
//
//// Get the union of n arrays
//Array.prototype.rassemble =  function () {
//	var a = [].concat(this);
//	var l = arguments.length;
//	for (var i=0; i<l; i++) {
//		a = a.concat(arguments[i]);
//    }
//    return a.makeunique();
//};

// Test
// var a = [1, 3, 2, 4, 2, 4, 5];
// var b = [1, 5, 6, 7, 8];
// alert(a.makeunique().sort());
// alert(a.getintersect(b).sort());
// alert(a.rassemble(b).sort());

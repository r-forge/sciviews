// SciViews-K array functions
// Various functions to manipulate arrays, 'sv.tools.array' namespace'
// Copyright (c) 2008-2011, Romain Francois and Kamil Barton
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.tools.array.remove(a, s);     // Eliminate 's' from 'a'
// sv.tools.array.contains(a, s);   // Does array 'a' contain 's'
// sv.tools.array.removeItem(a, s); // this function is removed now - use splice
// 									// instead
//
// Additional methods to Array objects /////////////////////////////////////////
// Adding to Array.prototype has REALLY strange side effects. No idea why.

// Define the 'sv.tools.array' namespace
if (typeof(sv) == 'undefined') sv = {};
if (typeof(sv.tools) == 'undefined') sv.tools = {};
if (typeof(sv.tools.array) == 'undefined') sv.tools.arr = {};
//sv.tools.array.remove = function (a, item) Array.prototype.remove.call(a, item);

sv.tools.array.contains = function array_contains (arr, s) (arr.indexOf(s) !== -1);

sv.tools.arr.unique = function array_unique(arr)
	arr.reduce(function(a, j) {
		if(a.indexOf(j)==-1) a.push(j);
		return(a)}, []);

sv.tools.arr.remove = function array_remove(arr, item) arr.filter(function(x) x !== item);



//// Additional methods to Array objects ///////////////////////////////////////
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

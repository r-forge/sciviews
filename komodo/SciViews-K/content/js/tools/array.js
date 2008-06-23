// SciViews-K functions
// Various functions to manipulate arrays
// by Romain Francois

////////////////////////////////////////////////////////////////////////////////
// sv.tools.array.remove(a, s);     // Eliminate 's' from 'a'
// sv.tools.array.contains(a, s);   // Does array 'a' contain 's'
// sv.tools.array.removeItem(a, s); // Return an array with 's' removed from 'a'
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.tools.array' namespace
if (typeof(sv.tools.array) == 'undefined') sv.tools.array = new Object();

// Remove 's' from the array 'a'
sv.tools.array.remove = function(a, s) {
	for (i = 0; i < a.length; i++) {
		if (s == a[i]) a.splice(i, 1);
	}
}

// Does the array 'a' contain 's'?
sv.tools.array.contains = function(a, s) {
	for (i = 0; i< a.length; i++) {
		if (s == a[i]) return(true);
	}
	return(false);
}

// Return an array from which 's' item is eliminated fro the array 'a'
sv.tools.array.removeItem = function(a, s) {
	b = [];
	for (i in a) {
		if (i != s) {
			b[i] = a[i]
		}
	}
	return(b);
}

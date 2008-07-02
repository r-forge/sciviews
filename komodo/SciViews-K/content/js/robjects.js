// SciViews-K R objects functions
// Define the 'sv.r.objects' namespace
// Copyright (c) 2008, Romain Francois
// Contribution from Philippe Grosjean

////////////////////////////////////////////////////////////////////////////////
// data objects:
//
// objectList           // List of objects to display
// searchPaths          // List of search paths in R
//
//==============================================================================
// functions :
//
// sv.r.objects.searchpath(); // Show/hide the search path listbox
// sv.r.objects.getPackageList(); // Query R for the search path
// sv.r.objects._processPackageList(data); // Callback to process this list
// sv.r.objects.displayPackageList(goback); // Display the search path items
// sv.r.objects.addObjectList(pack); // Get list of objects from R
// sv.r.objects._processObjectList(data); // Callback to process list of objects
// sv.r.objects.displayObjectList(goback); // Display the objects in the tree
// sv.r.objects.packageSelectedEvent(event); // Process click event in the list
// sv.r.objects.packageSelected(pack, status); // Change package selection
// sv.r.objects.__isSelected(p); // Is a package selected?
// sv.r.objects.__addPackageToSelection(p); // Add a package to the list of sel
// sv.r.objects.__removePackageFromSelection(p); // Remove a package from sel
//
////////////////////////////////////////////////////////////////////////////////
//
// TODO:
// Autorefresh of R Objects from R + do not refresh if R Objects is not visible
// Remember the selection in the path list persitently
// Tooltips for objects
// Context menu calculated from R
// Drag&drop of objects to a buffer
////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.r.objects' namespace
if (typeof(sv.r.objects) == 'undefined')
	sv.r.objects = {
		objectList: [],
		searchPaths: []
	}

// Show/hide the search path listbox
sv.r.objects.searchpath = function() {
	var split = document.getElementById("sciviews_robjects_splitter");
	var state = split.getAttribute("state");
	if (state == "collapsed") {
		state = "open";
	} else {
		state = "collapsed";
	}
	split.setAttribute("state", state);
}

// Get the list of packages on the search path from R
sv.r.objects.getPackageList =  function() {
	var cmd = 'cat(objSearch(sep = ",", compare = FALSE))';
	sv.r.evalCallback(cmd, sv.r.objects._processPackageList);
};

// Callback to process the list of packages in the search path from R
sv.r.objects._processPackageList = function(data) {
	if (data == "") { return; }	// No changes
	sv.r.objects.searchPaths = data.replace(/[\n\r]/g, "").split(/,/);
  sv.r.objects.displayPackageList();
};

// Display the list of packages in the search path
sv.r.objects.displayPackageList = function(goback) {
	var pack;
	var node = document.getElementById("sciviews_robjects_searchpath_listbox");
	sv.tools.e4x2dom.clear(node);

	var item;
	var packs = sv.r.objects.searchPaths;
	var k = 0;
	var ischecked = "false";
  for(var i = 0; i < packs.length; i++) {
		pack = packs[i]
		if (sv.r.objects.__isSelected(pack)) {
			ischecked = "true";
		} else {
			ischecked = "false";
		}
		item =
			<listitem type="checkbox" label={pack} checked={ischecked}
			  onclick="sv.r.objects.packageSelectedEvent(event)"
              spid={packs[i]}
             />;
        sv.tools.e4x2dom.append(item, node, k);
        k++;
  }
	sv.r.objects.displayObjectList(false);
};

// Ask R for the list of objects in an environment
sv.r.objects.addObjectList = function(pack) {
	var id = sv.prefs.getString("sciviews.client.id", "SciViewsK");
	var cmd = 'cat(objList(id = "' + id + '_' + pack + '", envir = "' + pack +
		'", all.info = TRUE, sep = ",", compare = FALSE), sep = "\\n")';
	sv.r.evalCallback(cmd, sv.r.objects._processObjectList);
};

// Callback to process the list of objects in an environment
sv.r.objects._processObjectList = function(data) {
  if (data == "") { return; }	//no changes
	var lines = data.split("\n");
    var rx = /,/;
    var item, line;
    var pack;
    var idx;

    for (var i = 0; i < lines.length; i++) {
      if (rx.test(lines[i])) {
        line = lines[i].split(",");
        pack = line[0];  
        if (sv.r.objects.objectList[pack] == undefined) {
          sv.r.objects.objectList[pack] = [];
          idx = 0;
        } else {
          idx = sv.r.objects.objectList[pack].length;
        }
        sv.r.objects.objectList[pack][idx] =
          new Array(line[1], line[2], line[3], line[4], line[5]);
      }
    }
    sv.r.objects.displayObjectList();
};

// Display the list of objects in the tree
sv.r.objects.displayObjectList = function(goback) {
    var tb = document.getElementById("sciviews_robjects_filterbox");
    var obRx = new RegExp(tb.value);

    var node = document.getElementById("sciviews_robjects_objects_tree_main");
    sv.tools.e4x2dom.clear(node);
		// var k = 0;
    var currentPack;
    var currentFun;

    for (var pack in sv.r.objects.objectList) {
      currentPack = sv.r.objects.objectList[pack];
      item =
      	<treeitem container="true" open="true">
            <treerow>
              <treecell label={pack} properties="package" />
              <treecell label="" />
              <treecell label="" />
              <treecell label="" />
            </treerow>
            <treechildren />
        </treeitem>;
      item.treechildren.treeitem = new XMLList();
      for (var i = 0; i < currentPack.length; i++) {
        currentFun = currentPack[i];
        if (obRx.test(currentFun[0])) {
        	item.treechildren.treeitem +=
        		<treeitem >
        		  <treerow>
        		    <treecell label={currentFun[0]}
          			  properties={currentFun[3].replace(".", "-" )} />
        		    <treecell label={currentFun[1]} />
        		    <treecell label={currentFun[2]} />
        		    <treecell label={currentFun[3]} />
        		  </treerow>
        		</treeitem>;
        }
      }
      sv.tools.e4x2dom.appendTo(item, node);
      // k++;
    }
    if(goback) tb.focus();
};

// Change the display status of a package by clicking an item in the list
sv.r.objects.packageSelectedEvent = function(event) {
    var cb = event.target;
    var status = cb.checked;
    var spid = cb.getAttribute("spid");
    sv.r.objects.packageSelected(spid, status);
};

// Process selection/deselection of packages
sv.r.objects.packageSelected = function(pack, status) {
    if (status) {
				sv.r.objects.__addPackageToSelection(pack);
    } else {
				sv.r.objects.__removePackageFromSelection(pack);
    }
};

// Function that indicates whether a package is selected
sv.r.objects.__isSelected = function(p) {
		for (var pack in sv.r.objects.objectList){
			if(pack == p) return(true);
		}
    return(false);
};

// Add content of package to the tree
sv.r.objects.__addPackageToSelection = function(p) {
    if(sv.r.objects.debug) ko.statusBar.AddMessage("adding package" + p, "R", 5000, true)
    sv.r.objects.addObjectList(p);
};

// Remove content of the package from the tree
sv.r.objects.__removePackageFromSelection = function(p) {
    if(sv.r.objects.debug) ko.statusBar.AddMessage("removing package" + p, "R", 5000, true)
    sv.r.objects.objectList = sv.tools.array.removeItem(sv.r.objects.objectList, p);
    sv.r.objects.displayObjectList();
};

// Make sure to check .GlobalEnv at the beginning
// TODO: persitently save user's selection using Komodo mechanism
// sv.r.objects.packageSelected(".GlobalEnv", true);

sv.r.objects.debug = false ;

sv.robjects.refreshPackage = function(pack){
  if( sv.r.objects.__isSelected(pack) ){
    // TODO: there is probably a better way
    sv.r.objects.packageSelected(".GlobalEnv", false);
    sv.r.objects.packageSelected(".GlobalEnv", true);
  }
}

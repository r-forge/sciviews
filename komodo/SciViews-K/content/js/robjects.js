//TODO: sort inserted child nodes (3-state sorting), restoring natural order of sub-elements
	//(add orderIndex property to inserted elements)
//TODO: resolve filtering modes: should sub-object be filtered too?
//TODO: quoting non-syntactic sub-names inserted into text
//TODO: preserve opened sub-objects on refresh
//TODO: context menu for search-paths list
//TODO: renaming objects on the list - editable names
//TODO: add context menu item for environments: remove all objects
//TODO: tollbar: dropdown menu for packages maintenance (add, install, etc)
//TODO: solve problems with selection, when removing objects


//DONE: "remove" command: Shift + Command - removes immediatelly (confirmation box first), Command - adds R code to the current document


//sv.r.objects = rObjectsTree;

/*

rObjectsTree properties and methods:
TODO: complete this documentation, clean up the code

visibleData - displayed data
treeData - original tree data
isInitialized
atomSvc

//  functions/properties to implement tree view object //

treeBox - treeBoxObject
selection - tree selection object
toggleOpenState
rowCount
setTree
setCellText
setCellValue
getCellText
isContainer
isContainerOpen
isContainerEmpty
isSeparator
isSorted
isEditable
getParentIndex
getLevel
hasNextSibling
getImageSrc
getProgressMode - not really needed
getCellValue
cycleHeader
selectionChanged
cycleCell - not really needed
performAction
performActionOnCell
getRowProperties
getCellProperties
getColumnProperties
canDrop - always false
drop - not needed so far

// other //

iconTypes - icons to display
filterBy
createVisibleData - create visibleData from treeData
sort
applyFilter
filter
getFilter
addVItems
addVIChildren
getVItem
foldAll
getSelectedRows

toString - textual representation of the tree for debug purposes

init - initialize
refreshAll
removeSelected
getSelectedNames
insertName
setFilterBy

// Event handling //
contextOnShow
do
onEvent
listObserver - drag & drop handler

_parseObjectList
_addObjectList
_removeObjectList
packageSelected
_addSubObject, _parseSubObjectList - should be merged with _addObjectList and _parseObjectList

// search path box methods: //

getPackageList
_processPackageList
toggleViewSearchPath
displayPackageList
packageSelectedEvent
packageListObserver
packageListKeyEvent
searchPaths

*/


var rObjectsTree = {
	debug: false,
	//debug: true,
	visibleData : [],
	treeData: [],
	isInitialized: false,

	treeBox: null,
	selection: null,

	iconTypes: ['array', 'character', 'data.frame', 'Date', 'dist', 'empty',
				'factor', 'function', 'glm', 'integer', 'list', 'lm', 'lme',
				'logical', 'matrix', 'numeric', 'object', 'objects', 'package',
				'standardGeneric', 'S3', 'S4', 'ts', 'environment', 'formula'],

	filterBy: 0, // filter by name by default

	createVisibleData: function(){
		if (!this.isInitialized) {
			this.init();
			return;
		}

		var rowsBefore = this.visibleData.length;

		this.visibleData = [];
		this.addVItems(this.treeData, -1, 0);
		var rowsChanged = this.visibleData.length - rowsBefore;

		if (rowsChanged) {
			this.treeBox.rowCountChanged(0, rowsChanged);
		}
		this.treeBox.invalidateRange(this.treeBox.getFirstVisibleRow(),
							this.treeBox.getLastVisibleRow());
	},


	sort: function(column) {
		var columnName;
		var tree = document.getElementById("sciviews_robjects_objects_tree");

		var order = tree.getAttribute("sortDirection") == "ascending" ? 1 : -1;

		try {
			var currentElement = this.visibleData[this.selection.currentIndex].origItem;
		} catch (e) {
			var currentElement = null;
		}

		//if the column is passed and it's already sorted by that column, reverse sort
		if (column) {
			columnName = column.id;
			if (tree.getAttribute("sortResource") == columnName) {
				order *= -1;
			}
		} else {
			columnName = tree.getAttribute("sortResource");
		}

		var colNames = ["r-name", "r-dims",  "r-class", "r-group", "r-fullName"];
		var sCol = colNames.indexOf(columnName);

		var defaultSortCol = 0;
		if (typeof(sCol) == "undefined")
			sCol = 0;

		if (typeof(order) == "undefined")
			order = 1;

		function _sortCompare(a, b) {
			if (a.sortData[sCol] > b.sortData[sCol]) return 1 * order;
			if (a.sortData[sCol] < b.sortData[sCol]) return -1 * order;

			if (sCol != defaultSortCol) {
				if (a.sortData[defaultSortCol] > b.sortData[defaultSortCol]) return 1;
				if (a.sortData[defaultSortCol] < b.sortData[defaultSortCol]) return -1;
			}
			return 0;
		}

		function _sortCompareName(a, b) {
			if (a.sortData[defaultSortCol] > b.sortData[defaultSortCol]) return 1;
			if (a.sortData[defaultSortCol] < b.sortData[defaultSortCol]) return -1;
			return 0;
		}

		function _sortRecursive(arr) {
			arr.sort(_sortCompare);
			for (var i in arr) {
				if (typeof (arr[i].children) == "object") {
					_sortRecursive(arr[i].children);
				}
			}
		}

		//setting these will make the sort option persist
		tree.setAttribute("sortDirection", order == 1 ? "ascending" : "descending");
		tree.setAttribute("sortResource", columnName);

		var cols = tree.getElementsByTagName("treecol");
		for (var i = 0; i < cols.length; i++) {
			cols[i].removeAttribute("sortDirection");
		}

		document.getElementById(columnName).setAttribute("sortDirection", order == 1 ? "ascending" : "descending");

		// sort packages always by name:
		this.treeData.sort(_sortCompareName);
		for (var i in this.treeData) {
			if (typeof (this.treeData[i].children) == "object") {
				_sortRecursive(this.treeData[i].children);
			}
		}

		this.createVisibleData();

		if (currentElement) {
			this.selection.select(currentElement.index);
			this.treeBox.ensureRowIsVisible(currentElement.index);
		}
	},

	_parseObjectList: function(data, tv) {
		// when used as a callback, this = window, have to use rObjectsTree instead

		if (data == "" || (data.trim() == "An empty objects list") )
			return;	//no changes

		var lines = data.split(/\r?\n/);

		// get rid of the "Objects list:" line
		if (lines[0].indexOf("Objects list:") != -1)
			lines.shift();

		var item, line, pack, idx;
		var sep = ';';
		var packIdx = [], packAdded = [];
		for (var i = 0; i < rObjectsTree.treeData.length; i++) {
			packIdx[i] = rObjectsTree.treeData[i].name;
		}

		var isList, dimNumeric, p, dim, dimRegExp = /^(\d+x)*\d+$/;

		for (var i = 0; i < lines.length; i++) {
			if (lines[i].indexOf(sep) != -1) {
				line = lines[i].split(sep);

				if (line.length < 4)
					continue;

				pack = line[0];
				p =  packIdx.indexOf(pack);

				if (p == -1) { // create new top level branch
					p = packIdx.push(pack) - 1;

					rObjectsTree.treeData.push({
						name: pack,
						fullName: pack,
						children: [],
						type: "environment",
						class: "package",
						isOpen: true,
						sortData: [pack.toLowerCase(), 0, "package", "package"],
						index: -1,
						parentObject: rObjectsTree.treeData
					});
					packAdded.push(pack);

				} else if (packAdded.indexOf(pack) == -1) {
					rObjectsTree.treeData[p].children = [];
					packAdded.push(pack);
				}

				dimNumeric = 1;
				if (dimRegExp.test(line[2])) {
					dim = line[2].split(/x/);
					for (var j in dim)
						dimNumeric *= parseInt(dim[j]);
				}
				rObjectsTree.treeData[p].children.push({
					name: line[1],
					fullName: line[1],
					dims: line[2],
					group: line[3],
					class: line[4],
					list: line[5] == "TRUE",
					type: "object",
					childrenLoaded: false,
					isOpen: false,
					env: pack,
					sortData: [line[1].toLowerCase(), dimNumeric, line[4].toLowerCase(), line[3].toLowerCase()],
					index: -1,
					parentObject: rObjectsTree.treeData[p]
				});
			}
		}

		var currentElement = rObjectsTree.treeData[p];
		rObjectsTree.sort();
		if (packAdded.length == 1 && currentElement.index != -1)
			rObjectsTree.treeBox.ensureRowIsVisible(currentElement.index);

	},

	_addObjectList: function(pack) {
		// need this for attached files on windows:
		pack = pack.replace("\\", "\\\\");

		var id = sv.prefs.getString("sciviews.client.id", "SciViewsK");

		// for use with modified objList
		var cmd = 'print(objList(id = "' + id + '_' + pack + '", envir = "' + pack +
			'", all.info = TRUE, compare = FALSE), sep = ";", eol = "\\n")';

		if (this.debug)	sv.cmdout.append(cmd);
		sv.r.evalCallback(cmd, this._parseObjectList, this);
	},

	_removeObjectList: function(pack) {
		for (var i = 0; i < this.treeData.length; i++) {
			if (this.treeData[i].name == pack) {
				this.treeData.splice(i, 1);
				break;
			}
		}
		this.createVisibleData();

	},

	packageSelected: function(pack, status) {
		if (status) {
			rObjectsTree._addObjectList(pack);
		} else {
			rObjectsTree._removeObjectList(pack);
		}
	},

	_addSubObject: function(obj) {
		var objName = obj.origItem.name;
		// objList does not quote non syntactic names, so we do it here:
		if (
			obj.level == 1
			&& objName.search(/^[a-z\.][\w\._]*$/i) == -1)
			objName = "`" + objName + "`";
		else
			objName = obj.origItem.fullName;

		var env = obj.origItem.env.replace("\\", "\\\\");

		var id = sv.prefs.getString("sciviews.client.id", "SciViewsK");

		var cmd = 'print(objList(id = "' + id + '_' + env + '_' + objName + '", envir = "' + env +
			'", object = "' + objName + '", all.info = FALSE, compare = FALSE), sep = ";;", eol = "\\n")';


		if (this.debug)
			sv.cmdout.append(cmd);

		sv.r.evalCallback(cmd, this._parseSubObjectList, obj);
	},

	_parseSubObjectList: function(data, obj) {
		var sep = ';;';

		var lines = data.split(/\r?\n/);

		if (data == "" || (data.trim() == "An empty objects list")
		    || lines.length < 3) {
			obj.isContainer = false;
			rObjectsTree.treeBox.invalidateRow(obj.origItem.index);
			return;
		}

		// This is ony for compatibility with different print.objList versions
		// may be removed when final form of output will be estabilished
		// get rid of the "Objects list:" line
		if (lines[0].indexOf("Objects list:") != -1)
			lines.shift()
		if (!lines.length)
			return;

		var env = lines[0].substr(lines[0].lastIndexOf("=") + 1).trim(); // Environment - 1st line
		var treeParent = lines[1].substr(lines[1].lastIndexOf("=") + 1).trim(); // parent object - 2ng line

		var vd = rObjectsTree.visibleData;
		if (!obj) { // reloading sub-lists without passing parent tree item - not used yet
			if (treeParent) {
				// TODO: smarter way to do it than searching through all items
				for (var i = 0; i < vd.length; i++) {
					if (vd[i].origItem.env == env && vd[i].orgItem.fullName == treeParent) {
						obj = vd[i];
						break;
					}
				}
			} else {
				// TODO: search for pkgs on top level
			}
		}

		var origItem = obj.origItem;
		origItem.childrenLoaded = true;

		var childType = origItem.group == "function"? "args" : "sub-object";
		var dimNumeric, dim, dimRegExp = /^(\d+x)*\d+$/;

		origItem.children = [];
		for (var i = 2; i < lines.length; i++) {
			if (lines[i].indexOf(sep) != -1) {
				line = lines[i].split(sep);
				if (line.length < 6)
					continue;

				dimNumeric = 1;
				if (dimRegExp.test(line[3])) {
					dim = line[2].split(/x/);
					for (var j in dim)
						dimNumeric *= parseInt(dim[j]);
				}

				origItem.children.push({
					name: line[0],
					fullName: line[1],
					dims: line[2],
					group: line[3],
					class: line[4],
					list: line[5] == "TRUE",
					type: childType,
					childrenLoaded: false,
					isOpen: false,
					env: env,
					sortData: [line[0].toLowerCase(), dimNumeric, line[4].toLowerCase(), line[3].toLowerCase()],
					index: -1,
					parentObject: origItem
				});
			}
		}

		obj.childrenLength = origItem.children.length;
		rObjectsTree.toggleOpenState(origItem.index);
	},

	applyFilter: function() {
		this.filter = this.getFilter();
		this.createVisibleData();
	},

	filter: function(x) { return true; },
	getFilter: function() {
		var tb = document.getElementById("sciviews_robjects_filterbox");

		var obRx, filterRegExp, test;

		if (!tb.value)
			return function(x) {	return true;	}

		try {
			obRx = new RegExp(tb.value, "i");
			tb.className = "";
			return function(x) {	return (obRx.test(x));	}
		} catch (e) {
			obRx = tb.value;
			tb.className = "badRegEx";
			return function(x) {	return(x.indexOf(obRx) > -1);	}
		}
	},

	addVItems: function(item, parentIndex, level, parentUid) {
		if (typeof(item) == "undefined")
			return(parentIndex);
		if (typeof(level) == "undefined") level = -1;
		if (!parentUid) parentUid = "";
		if (!parentIndex) parentIndex = 0;

		var idx = parentIndex;
		var len = item.length;
		var conditionalView;
		var filterBy = this.filterBy;

		for (var i = 0; i < len; i++) {
			if (level == 1 && !this.filter(item[i].sortData[filterBy])) { //item[i].class != "package" &&
				item[i].index = -1;
				continue;
				// set conditionalView = true if any child nodes pass fitering
				//conditionalView = true;
			} else {
				//conditionalView = false;
			}
			idx++;
			var vItem = this.getVItem(item[i], idx, level,
				i == 0, i == len - 1,
				parentIndex, parentUid);
			this.visibleData[idx] = vItem;

			if (vItem.isContainer && vItem.isOpen && vItem.childrenLength > 0) {
				var idxBefore = idx;
				idx = this.addVItems(item[i].children, idx, level + 1, vItem.uid + "»");

				// no children is visible:
				if (idxBefore == idx) {
					vItem.isContainerEmpty = true;
					// if this item was to be viewed on condition any children is visible, remove this item:
					/*if (conditionalView) {
						this.visibleData.pop();
						idx--;
					}*/
				}
				//print(idx + "<-" + idxBefore);
			}
		}

		return idx;
	},

	// attaches one level list of child items to an item
	addVIChildren: function(vItem, parentIndex, isOpen) {
		var children = vItem.origItem.children;

		vItem.isOpen = isOpen;

		var len = children.length;
		vItem.children = [];
		var idx = parentIndex;
		for (var i = 0; i < len; i++) {
			if (vItem.level == 0 && !this.filter(children[i].name)) {
				children[i].index = -1;
				continue;
			}
			idx++;
			vItem.children
				.push(this.getVItem(children[i], idx, vItem.level + 1,
					i == 0, i == len - 1,
					isOpen? parentIndex : 0, // closed subtree elements have 0-based parentIndex
					vItem.uid + "»"));
		}

		vItem.isContainerEmpty = vItem.children.length == 0;

	},

	getVItem: function(obj, index, level, first, last, parentIndex, parentUid) {
		var vItem = {};

		if (obj.group == "list" || obj.group == "function" || obj.list) {
			vItem.isContainer = true;
			vItem.isContainerEmpty = false;
			vItem.childrenLength =
				(typeof(obj.children) == "undefined")? 0 : obj.children.length;
			vItem.isOpen = (typeof(obj.isOpen) != "undefined") && obj.isOpen;
			vItem.isList = true;
		} else {
			vItem.isContainer = typeof(obj.children) != "undefined";
			vItem.isContainerEmpty = vItem.isContainer && (obj.children.length == 0);
			vItem.childrenLength =  vItem.isContainer? obj.children.length : 0;
			vItem.isList = false;
		}
		vItem.isOpen = (typeof(obj.isOpen) != "undefined") && obj.isOpen;

		vItem.uid = parentUid + obj.name;
		vItem.parentIndex = parentIndex;
		vItem.level = level;
		vItem.first = first;
		vItem.last = last;
		vItem.labels = [obj.name, obj.dims, obj.group, obj.class, obj.fullName];
		vItem.origItem = obj;
		vItem.origItem.index = index;

		return vItem;
	},


	foldAll: function(open) {
		if (!this.rowCount)
			return;
		var idx = this.selection.currentIndex;
		if (idx == -1)
			idx = 0;

		var curItem = this.visibleData[idx].origItem;
		var parentObject = curItem.parentObject;
		if (parentObject) {
			var siblings;
			if (parentObject.children) {
				siblings = parentObject.children;
			} else {
				siblings = parentObject;
			}
			for (var i = 0; i < siblings.length; i++) {
				if (siblings[i].isOpen == open) {
					this.toggleOpenState(siblings[i].index);
				}
			}
		}
	},

	toggleOpenState: function(idx) {
		var vd = this.visibleData;
		var item = vd[idx];
		if (!item) {
			//print(idx);
			return;
		}

		if (item.isList && !item.origItem.isOpen && !item.origItem.childrenLoaded) {
			this._addSubObject(item);
			return;
		}

		var rowsChanged;

		var iLevel = item.level;

		if (!item.childrenLength) {
			return;
		}

		if (item.origItem.isOpen) { // closing subtree
			var k;
			for (k = idx + 1; k < vd.length && vd[k].level > iLevel; k++) { }
		    rowsChanged = k - idx - 1;
			item.children = vd.splice(idx + 1, rowsChanged);

			// make parentIndexes of child rows relative:
			for (var i = 0; i < item.children.length; i++) {
				item.children[i].parentIndex -= idx;
			}

			// decrease parentIndexes of subsequent rows:
			for (var i = idx + 1; i < vd.length; i++) {
				if (vd[i].parentIndex > idx)
					vd[i].parentIndex -= rowsChanged;
				vd[i].origItem.index = i;
			}


		} else { // opening subtree

			if (typeof(item.children) == "undefined") {
				this.addVIChildren(item, idx, false);
			}

			// filter child items
			var insertItems = [];
			for (var i = 0; i < item.children.length; i++) {
				//if (this.filter(item.children[i].origItem.name)) {
					insertItems.push(item.children[i]);
				//}
			}

			rowsChanged = insertItems.length;
			// change parentIndexes of child rows from relative to absolute
            for (var i = 0; i < insertItems.length; i++) {
				insertItems[i].parentIndex += idx;
				insertItems[i].origItem.index = i + idx + 1;
			}

			var vd2 = vd.slice(0, idx + 1).concat(insertItems, vd.slice(idx + 1));
			// increase parentIndexes of subsequent rows:
			for (var i = idx + 1 + insertItems.length; i < vd2.length; i++) {
				if (vd2[i].parentIndex > idx)
					vd2[i].parentIndex += rowsChanged;
				vd2[i].origItem.index = i;
			}
			this.visibleData = vd2;
			item.children = null;
		}
		item.origItem.isOpen = !item.origItem.isOpen;
		if (rowsChanged)
			this.treeBox.rowCountChanged(idx + 1, (item.origItem.isOpen? 1 : -1) * rowsChanged);

		this.treeBox.invalidateRow(idx);
	},

	get rowCount()  { return this.visibleData.length; },
	setTree: function(treeBox)         { this.treeBox = treeBox; },

	setCellText: function(idx, col, value) {
		this.visibleData[idx].labels[col.index] = value;
	},
	setCellValue: function(idx, col, value) {
	},

	getCellText: function(idx, column) {
			return this.visibleData[idx].labels[column.index];
			//+":" + this.visibleData[idx].level;
	},
	isContainer: function(idx)         {
		return this.visibleData[idx].isContainer;
	},
	isContainerOpen: function(idx)     { return this.visibleData[idx].origItem.isOpen; },
	isContainerEmpty: function(idx)    { return this.visibleData[idx].isContainerEmpty;  },
	isSeparator: function(idx)         { return false; },
	isSorted: function()               { return false; },
	isEditable: function(idx, column)  { return false; },

	getParentIndex: function(idx)		{ return this.visibleData[idx].parentIndex; },
	getLevel: function(idx) 			{ return this.visibleData[idx].level; },
	hasNextSibling: function(idx, after){ return !this.visibleData[idx].last; },
	getImageSrc: function(row, col) {
		if (col.index == 0) {
			var Class = this.visibleData[row].origItem.class;
			if (Class == "package" && this.visibleData[row].origItem.name.indexOf("package") != 0) {
					Class = "package_green";
			} else if (this.iconTypes.indexOf(Class) == -1) {
				Class = this.visibleData[row].origItem.group;
				if (this.iconTypes.indexOf(Class) == -1) {
					return "";
				}
			}
            return "chrome://sciviewsk/skin/images/" + Class + ".png";
		} else
			return "";
	},

	getProgressMode : function(idx,column) {},
	getCellValue: function(idx, column) {},
	cycleHeader: function(col, elem) {},
	selectionChanged: function() {},
	cycleCell: function(idx, column) {},
	performAction: function(action) {},
	performActionOnCell: function(action, index, column) {	},
	getRowProperties: function(idx, props) {
		var item = this.visibleData[idx]
		var origItem = item.origItem;

		props.AppendElement(this.atomSvc.getAtom("type-" + origItem.type));
		props.AppendElement(this.atomSvc.getAtom("class-" + origItem.class));

		if (item.last) {
			props.AppendElement(this.atomSvc.getAtom("lastChild"));
		}
		if (item.first) {
			props.AppendElement(this.atomSvc.getAtom("firstChild"));
		}
	},
	getCellProperties: function(idx, column, props) {
		if (column.id == "r-name") {
			props.AppendElement(this.atomSvc.getAtom("icon"));
			var item = this.visibleData[idx]
			var origItem = item.origItem;
			props.AppendElement(this.atomSvc.getAtom("type-" + origItem.type));
			props.AppendElement(this.atomSvc.getAtom("class-" + origItem.class));
			props.AppendElement(this.atomSvc.getAtom("group-" + origItem.group));

		}
	},
	getColumnProperties: function(column, element, prop) {},

	toString: function() {
		var vd = this.visibleData;
		var ret = "", indent;
		ret = "length: " + vd.length + "\n";
		for (var i = 0; i < vd.length; i++) {
			indent = ""; for (var j = 0; j < vd[i].level; j++) { indent += "+ "; }

			ret += vd[i].origItem.index + indent + " ^"+  vd[i].parentIndex +  "-> " + vd[i].uid + " (" +  vd[i].name + ")" +
				(vd[i].isContainer? "*" : "" )
				+ "\n";
		}
		return ret;
	},

	getSelectedRows: function() {
		var start = new Object();
		var end = new Object();
		var rows = new Array();

		var numRanges = this.selection.getRangeCount();
		for (var t = 0; t < numRanges; t++){
			this.selection.getRangeAt(t, start, end);
			for (var v = start.value; v <= end.value; v++){
				rows.push(v);
			}
		}
		return(rows);
	},

	// Drag'n'drop support
	listObserver: {
		onDragStart: function (event, transferData, action) {
			var namesArr = rObjectsTree.getSelectedNames(event.ctrlKey);
			transferData.data = new TransferData();
			transferData.data.addDataForFlavour("text/unicode", namesArr.join(', '));
			return true;
		}
	},

	canDrop: function() { return false; },
	drop: function(idx, orientation) {},


	init: function() {
		this.atomSvc = Components.classes["@mozilla.org/atom-service;1"]
			.getService(Components.interfaces.nsIAtomService);
		this.visibleData = [];
		this._addObjectList(".GlobalEnv");
		this.getPackageList();
		this.isInitialized = true;

		document.getElementById("sciviews_robjects_objects_tree").view = rObjectsTree;
		this.treeBox.scrollToRow(0);
	}

};

// Get the list of packages on the search path from R
rObjectsTree.getPackageList =  function(refreshObjects) {
	var cmd = 'cat(objSearch(sep = ";;", compare = FALSE))';
	sv.r.evalCallback(cmd, rObjectsTree._processPackageList, refreshObjects);
};

// Callback to process the list of packages in the search path from R
rObjectsTree._processPackageList = function(data, refreshObjects) {
	if (data == "") { return; }	// No changes
	rObjectsTree.searchPaths = data.replace(/[\n\r]/g, "").split(";;");
	rObjectsTree.displayPackageList(refreshObjects);
};

rObjectsTree.toggleViewSearchPath = function(event) {
	var what = event.target.tagName;
	var broadcaster = document.getElementById("cmd_robjects_viewSearchPath");
	var box = document.getElementById(broadcaster.getAttribute("box"));

	if (what == "splitter" || what == "grippy") {
		var state = document.getElementById("sciviews_robjects_splitter")
			.getAttribute("state");
		broadcaster.setAttribute("checked", state != "collapsed");
	} else {
		box.collapsed = !box.collapsed;
		broadcaster.setAttribute("checked", !box.collapsed);
		broadcaster.setAttribute("state", box.collapsed? "collapsed" : "open");
	}

	if (!box.collapsed) {
		if (!rObjectsTree.searchPaths.length) {
			rObjectsTree.getPackageList();
		}
	}
}

// Display the list of packages in the search path
rObjectsTree.displayPackageList = function(refreshObjects) {
	var pack;
	var node = document.getElementById("sciviews_robjects_searchpath_listbox");
	while(node.firstChild)
		node.removeChild(node.firstChild);
	var packs = this.searchPaths;

	var selectedPackages = new Array(rObjectsTree.treeData.length);
	for (var i = 0; i < selectedPackages.length; i++) {
		selectedPackages[i] = rObjectsTree.treeData[i].name;
	}

	for(var i = 0; i < packs.length; i++) {
		pack = packs[i];
		var item = document.createElement("listitem");
		item.setAttribute("type", "checkbox");
		item.setAttribute("label", pack);
		item.setAttribute("checked", selectedPackages.indexOf(pack) != -1);
		item.setAttribute("oncommand", "rObjectsTree.packageSelectedEvent(event);");

		node.appendChild(item);
	}

	if (refreshObjects)
		rObjectsTree.refreshAll();
};

// Change the display status of a package by clicking an item in the list
rObjectsTree.packageSelectedEvent = function(event) {
	var el = event.target;
	var pack = el.getAttribute("label");
	if (el.checked) {
		this._addObjectList(pack);
	} else {
		this._removeObjectList(pack);
	}
	//print(el.checked);
};

rObjectsTree.refreshAll = function () {
	var selectedPackages = new Array(rObjectsTree.treeData.length);
	for (var i = 0; i < selectedPackages.length; i++)
		selectedPackages[i] = rObjectsTree.treeData[i].name;

	if (selectedPackages.length == 0)
		selectedPackages.push('.GlobalEnv');

	// for use with modified objList
	var cmd = 'invisible(sapply(c("' + selectedPackages.join('","')	+ '"), function(x) print(objList(envir = x, all.info = TRUE, compare = FALSE), sep = ";")))';
	sv.r.evalCallback(cmd, rObjectsTree._parseObjectList);

}

rObjectsTree.removeSelected = function(doRemove) {
	var view = ko.views.manager.currentView;
	if (!view)
		return false;
	view.setFocus();

	var scimoz = view.scimoz;
	var item, type, name, vItem, cmd = [];
	var rmItems = {}, ObjectsToRemove = {}, envToDetach = [], ObjectsToSetNull = {};

	var rows = this.getSelectedRows();

	for (i in rows) {
		vItem = this.visibleData[rows[i]];
		item = vItem.origItem;
		name = item.fullName;
		type = item.type;

		switch (type){
			case "environment":
				if (name != ".GlobalEnv" && name != "TempEnv")
					envToDetach.push(name);
				break;
			case "object":
			case "sub-object":
				var env = item.env;
				thisItem:
				if (envToDetach.indexOf(env) == -1) {
					var parent = vItem;
					while (parent && parent.parentIndex && parent.parentIndex != -1) {
						parent = this.visibleData[parent.parentIndex].origItem;

						if (!parent
							|| (rmItems[env] && (rmItems[env].indexOf(parent.fullName) != -1))
							|| (parent.type == "environment" && (envToDetach.indexOf(parent.name) != -1))) {
							break thisItem;
						}

					}
					if (typeof rmItems[env] == "undefined")
						rmItems[env] = [];

					rmItems[env].push(name);

					if (type == "sub-object") {
						if (typeof ObjectsToSetNull[env] == "undefined")
							ObjectsToSetNull[env] = [];

						ObjectsToSetNull[env].push(name);

					} else {
						if (typeof ObjectsToRemove[env] == "undefined")
							ObjectsToRemove[env] = [];
						ObjectsToRemove[env].push(name);
					}

					var siblings = item.parentObject.children;
					for (var j in siblings) {
						if (siblings[j] == item) {
							siblings.splice(j, 1);
							break;
						}
					}
				}
				break;
			default:
		}
	}

	this.createVisibleData();



	for (i in envToDetach)
		cmd.push('detach("' + envToDetach[i] + '")');

	for (var env in ObjectsToRemove)
		cmd.push('rm(list = c("' + ObjectsToRemove[env].join('", "') + '"), pos = "' + env + '")');

	for (var env in ObjectsToSetNull) {
		cmd.push('eval(expression(' + ObjectsToSetNull[env].join(" <- NULL, ") + ' <- NULL), envir = as.environment("' + env + '"))');
	}


	if(doRemove) {
		sv.r.evalCallback(cmd.join("\n"), sv.cmdout.append);
		//sv.cmdout.append(cmd);
	} else {
		var nl = ["\r\n", "\n", "\r"][scimoz.eOLMode];
		scimoz.insertText(scimoz.currentPos, cmd.join(nl));
	}


	return true;
}

rObjectsTree.getSelectedNames = function(fullNames) {
	var rows = this.getSelectedRows();
	var namesArr = new Array();
	var cellText;
	var name = fullNames? "fullName" : "name"
	for (i in rows) {
		cellText = this.visibleData[rows[i]].origItem[name];
		if (cellText != "") {
			if (this.visibleData[rows[i]].level == 1 &&
				cellText.search(/^[a-z\.][\w\._]*$/i) == -1)
				cellText = "`" + cellText + "`";
			namesArr.push(cellText);
		}
	}
	return (namesArr);
}

rObjectsTree.insertName = function(fullNames) {
	var view = ko.views.manager.currentView;
	if (!view)
		return;
	var namesArr = rObjectsTree.getSelectedNames(fullNames);
	view.setFocus();
	var scimoz = view.scimoz;
	scimoz.insertText(scimoz.currentPos, namesArr.join(', '));
}

rObjectsTree.setFilterBy = function(menuItem, column) {
	var filterBy = ['name', 'dims', 'class', 'group', 'fullName'].indexOf(column);
	if (filterBy == -1)
		return;
	if (filterBy != this.filterBy) {
		var items = menuItem.parentNode.getElementsByTagName("menuitem");
		for (var i = 0; i < items.length; i++) {
			items[i].setAttribute("checked", items[i] == menuItem);
		}
		this.filterBy = filterBy;
		this.applyFilter();
	 } else {
		menuItem.setAttribute("checked", true);
	 }
	 return;
}

rObjectsTree.contextOnShow = function() {
	var currentIndex = rObjectsTree.selection.currentIndex;
	if (currentIndex != -1) {
		var isPackage, noDetach, isFunction;
		var item, type, name;
		item = this.visibleData[currentIndex].origItem;
		type = item.class;
		name = item.fullName;


		isPackage = type == "package";
		noDetach = isPackage && (name == ".GlobalEnv" || name == "TempEnv");
		isFunction = type == "function";
		var inPackage = false;

		if (!isPackage) {
			inPackage = item.env && (item.env.indexOf("package:") == 0);
		}

		document.getElementById("robjects_cmd_removeobj").setAttribute("disabled", noDetach);
		document.getElementById("robjects_cmd_attach").setAttribute("disabled", noDetach || !isPackage);
		document.getElementById("robjects_cmd_summary").setAttribute("disabled", isFunction || isPackage);
		document.getElementById("robjects_cmd_print").setAttribute("disabled", isPackage);
		document.getElementById("robjects_cmd_plot").setAttribute("disabled", isFunction || isPackage);
		document.getElementById("robjects_cmd_names").setAttribute("disabled", isFunction);
		document.getElementById("robjects_cmd_str").setAttribute("disabled", isPackage);

		document.getElementById("robjects_cmd_help").setAttribute("disabled", !isPackage && !inPackage);
	}
}

rObjectsTree.do = function(action) {
	var obj = [];
	var rows = rObjectsTree.getSelectedRows();
	var item, pkg, type, name;

	for (i in rows) {
		item = this.visibleData[rows[i]].origItem;
		type = item.class;
		name = item.fullName;
		pkg = item.env;
		obj.push({ name: name, type: type, pkg: pkg });
	}

	var command;

	switch(action) {
	// special handling for help:
	case 'help':
		for (i in obj) {
			// help only for packages and objects inside a package:
			if (obj[i].pkg.indexOf("package:") == 0) {
				sv.r.help(obj[i].name, obj[i].pkg.replace(/^package:/, ''));
			} else if (obj[i].name.indexOf("package:") == 0) {
				sv.r.help("", obj[i].name.replace(/^package:/, ''));
			}
		}
	break;
	// default treatment: just execute command and display results:
	case 'summary':
	case 'plot':
	case 'str':
	case 'names':
	default:
		var cmd = "";
		for (i in obj) {
			cmd += action + "(" + obj[i].name + ");\n";
		}

		//command = action + "(" + obj.join(");\n" + action) + ");";
		sv.r.eval(cmd);

	}

	//var view = ko.views.manager.currentView;
	//if (!view)		return;
	//var scimoz = view.scimoz;
	//view.setFocus();
	//scimoz.insertText(scimoz.currentPos, res.join(";" + ["\r\n", "\n", "\r"][scimoz.eOLMode]));
}

rObjectsTree.onEvent = function(event) {
	if (event.type == "keypress") {
		var keyCode = event.keyCode;

		if (this.debug)
			sv.cmdout.append("keyCode: " + keyCode);

		switch (keyCode) {
			case 46: // Delete key
				rObjectsTree.removeSelected(event.shiftKey);
				event.originalTarget.focus();
				return;
			case 45: //insert
				sv.cmdout.append("Insert");
				break;
			case 0:
				// Ctrt + A
				if (event.ctrlKey && event.charCode == 97 || event.charCode == 65){
					rObjectsTree.selection.selectAll();

				}
				return;
			case 93:
				//windows context menu key
				var contextMenu =  document.getElementById("rObjectsContext");
				//event.initMouseEvent()

				rObjectsTree.treeBox.ensureRowIsVisible(rObjectsTree.selection.currentIndex);

				var y = ((2 + rObjectsTree.selection.currentIndex - rObjectsTree.treeBox.getFirstVisibleRow())
					* rObjectsTree.treeBox.rowHeight)	+ rObjectsTree.treeBox.y;
				var x = rObjectsTree.treeBox.x;

				contextMenu.openPopup(null, "after_pointer", x, y, true);

			// TODO: Escape key stops retrieval of r objects
			default:
				//sv.cmdout.append(String.fromCharCode(event.charCode));
				//sv.cmdout.append("keyCode: " + keyCode);
				return;
		}

	} else if (event.type == "dblclick") {
		if (event.button != 0)
			return;

		if (rObjectsTree.selection && (rObjectsTree.selection.currentIndex == -1
			|| rObjectsTree.isContainer(rObjectsTree.selection.currentIndex)))
			return;
	}

	// default action: insert selected names:
	rObjectsTree.insertName(event.ctrlKey);
	event.originalTarget.focus();
}

// drag & drop handling for search paths list
rObjectsTree.packageListObserver = {
	onDrop : function (event, transferData, session) {
		window.temp = transferData;
		var data = transferData;
		var path;
		if (transferData.flavour.contentType == "application/x-moz-file") {
			path = transferData.data.path;
		} else if (transferData.flavour.contentType == "text/unicode") {
			path = new String(transferData.data).trim();
		}
		if (path.search(/\.RData$/i) > 0) {
			//sv.cmdout.append(path);
			sv.r.loadWorkspace(path, true);
			rObjectsTree.getPackageList();
		}
	},

	onDragEnter : function(event, flavour, session) {
		var s = "";
		for (i =0 ; i < arguments.length; i++){      //Get argument contents.
			s += "  Arg " + i + " = " + arguments[i] + "\n";
		}
		sv.cmdout.append(s);
	},

	onDragOver : function(event, flavour, session) {
		session.canDrop = flavour.contentType == 'text/unicode'	|| flavour.contentType == 'application/x-moz-file';
	},

	getSupportedFlavours : function () {
		var flavours = new FlavourSet();
		flavours.appendFlavour("application/x-moz-file","nsIFile");
		flavours.appendFlavour("text/unicode");
		return flavours;
	}
}

rObjectsTree.packageListKeyEvent = function(event) {
	var keyCode = event.keyCode;
	switch(keyCode) {
		case 46: // Delete key
			var listbox = event.target;
			var listItem = listbox.selectedItem;
			var pkg = listItem.getAttribute("label");;

			if (pkg == ".GlobalEnv" || pkg == "TempEnv")
				return;

			sv.r.evalCallback(
				'tryCatch(detach("' + pkg + '"), error = function(e) cat("<error>"));', function(data) {
				sv.cmdout.append(data);
				if (data.trim() != "<error>") {
					rObjectsTree._removeObjectList(pkg);
					listbox.removeChild(listItem);
					sv.cmdout.append("Namespace " + pkg + " detached.");
				} else {
					sv.cmdout.append("Namespace " + pkg + " could not be detached.");
				}
			});
			return;
		default:
			return;
	}
}

//ondragover="nsDragAndDrop.dragOver(event,rObjectsTree.packageListObserver);"
//ondragenter="nsDragAndDrop.dragEnter(event,rObjectsTree.packageListObserver);"

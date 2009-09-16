// SciViews-K R objects explorer functions
// Define the 'sv.r.objects' tree and implement RObjectsOverlay functions
// Copyright (c) 2009, Kamil Barton & Ph. Grosjean (phgrosjean@sciviews.org)
// License: MPL 1.1/GPL 2.0/LGPL 2.1
////////////////////////////////////////////////////////////////////////////////
// sv.r.objects properties and methods
//TODO: complete this documentation, clean up the code
//
///// These variables store all the information ////////////////////////////////
// treeData - original tree data
// visibleData - displayed data
//
///// Functions/properties to implement the tree view object ///////////////////
// treeBox - treeBoxObject
// selection - tree selection object
// toggleOpenState
// rowCount
// setTree
// setCellText
// setCellValue
// getCellText
// isContainer
//isContainerOpen
// isContainerEmpty
//isSeparator
// isSorted
// isEditable
// getParentIndex
// getLevel
// hasNextSibling
// getImageSrc
// getProgressMode - not used, not really needed
// getCellValue
// cycleHeader
// selectionChanged
// cycleCell - not used, not really needed
// performAction
// performActionOnCell
// getRowProperties
// getCellProperties
// getColumnProperties
// canDrop - always false (but may be later, with svIO functions?)
// drop - not needed so far
//
///// Other ////////////////////////////////////////////////////////////////////
///// Private methods
// _createVisibleData () - create visibleData from treeData
// _addObjectList(pack)
// _parseObjectList(data, packSelected)
// _removeObjectList(pack)
// _addSubObject(obj)
// _parseSubObjectList(data, obj)
// _getFilter()
// _addVItems(item, parentIndex, level, parentUid)
// _addVIChildren(vItem, parentIndex, isOpen)
// _getVItem(obj, index, level, first, last, parentIndex, parentUid)
//TODO: _addSubObject, _parseSubObjectList - should be possibly merged with
//      _addObjectList and _parseObjectList
//
///// Private properties
// iconTypes - icons to display
// debug - well, you know...
// isInitialized
// atomSvc
//
///// Public methods not belonging to the tree object implementation
// sort
// applyFilter
// filter
// foldAll
// getSelectedRows
// toString - textual representation of the tree for debugging purposes
// init - initialize
// refreshAll()
// refreshGlobalEnv(data); // R sends data to refresh the global environment
// removeSelected
// getSelectedNames
// insertName
// setFilterBy
//
///// Event handling
// contextOnShow
// do
// onEvent
// listObserver - drag & drop handler
//
///// Search path box methods
// _processPackageList - private method
// getPackageList
// toggleViewSearchPath
// displayPackageList
// packageSelectedEvent
// packageListObserver
// packageListKeyEvent
// searchPaths
//
////////////////////////////////////////////////////////////////////////////////
//TODO: identify packages by pos rather than name (allow for non-unique names)
//TODO: sort inserted child nodes (3-state sorting), restoring natural order of
//      sub-elements (add orderIndex property to inserted elements)
//TODO: resolve filtering modes: should sub-object be filtered too?
//TODO: preserve opened sub-objects on refresh
//TODO: context menu for search-paths list
//TODO: renaming objects on the list - editable names
//TODO: add context menu item for environments: remove all objects
//TODO: add a checkbutton to show also hidden objects (starting with a dot)
//TODO: delegate context menu calculation to R
//TODO: automatic refresh of the browser from R
////////////////////////////////////////////////////////////////////////////////

// TODO: make this a sv.robjects.tree instead!
sv.r.objects = {};

// sv.r.objects constructor
(function () {
	
	// Item separator for objList
	var sep = ";;";
	
	var cmdPattern = 'print(objList(id = "$ID$_$ENV$_$OBJ$", envir = "$ENV$",' +
		' object = "$ENV$", all.info = FALSE, compare = FALSE), sep = "' + sep +
		'", eol = "\\n")';
	
	// This should be changed if new icons are added
	var iconTypes = ['array', 'character', 'data.frame', 'Date', 'dist',
		'empty', 'factor', 'function', 'glm', 'integer', 'list', 'lm', 'lme',
		'logical', 'matrix', 'numeric', 'object', 'objects', 'package',
		'standardGeneric', 'S3', 'S4', 'ts', 'environment', 'formula'];
	
	// Reference to parent object for private functions
	var _this = this;
	
	var filterBy = 0; // Filter by name by default
	var isInitialized = false;
	
	// Set debug mode
	this.debug = sv.log.isAll();
	
	this.visibleData = [];
	this.treeData = [];
	
	this.treeBox = null;
	this.selection = null;
	
	var atomSvc = Components.classes["@mozilla.org/atom-service;1"]
		.getService(Components.interfaces.nsIAtomService);
	
	this.__defineGetter__ ('rowCount', function () {
		return this.visibleData.length;
	});
	
	function _createVisibleData () {
		if (!isInitialized) {
			_this.init();
			return;
		}
		var rowsBefore = _this.visibleData.length;
		_this.visibleData = [];
		_addVItems(_this.treeData, -1, 0);
		var rowsChanged = _this.visibleData.length - rowsBefore;
	
		if (rowsChanged) {
			_this.treeBox.rowCountChanged(0, rowsChanged);
		}
		_this.treeBox.invalidateRange(_this.treeBox.getFirstVisibleRow(),
			_this.treeBox.getLastVisibleRow());
	};
	
	function _addObjectList (pack) {
		// Need this for attached files on windows
		pack = pack.addslashes();
	
		var id = sv.prefs.getString("sciviews.client.id", "SciViewsK");
	
		// For use with modified objList
		var cmd = 'print(objList(id = "' + id + '_' + pack + '", envir = "' +
			pack + '", all.info = FALSE, compare = FALSE), sep = "' + sep +
			'", eol = "\\n", raw.output = TRUE, header = TRUE)';
	
		sv.log.debug(cmd);
		sv.r.evalCallback(cmd, _parseObjectList, pack);
	};
	
	function _parseObjectList (data, packSelected) {
		// Get position in the search path
		function getPos (pack) {
			var pos, searchPaths = _this.searchPaths;
			for (pos = 0; pos < searchPaths.length &&
				searchPaths[pos] != pack; pos++) { }
			return pos;
		}
	
		var p, pos, packAdded = [];
		if (data.trim() != "") {
			var lines = data.split(/[\r\n]{1,2}/);
	
			// Get rid of the "Objects list:" line
			if (lines[0].indexOf("Objects list:") != -1)
				lines.shift();
	
			var item, line, pack, idx;
			var packIdx = [];
			for (var i = 0; i < _this.treeData.length; i++)
				packIdx[i] = _this.treeData[i].name;
	
			var isList, dimNumeric, dim, dimRegExp = /^(\d+x)*\d+$/;
	
			for (var i = 0; i < lines.length; i++) {
				if (lines[i].indexOf(sep) == -1) {
					// Parse header line: look for environment name
					if (lines[i].indexOf("Env=") == 0) {
						pack = lines[i].substr(4);
						p =  packIdx.indexOf(pack);
						if (p == -1) { // Create new top level branch
							p = packIdx.push(pack) - 1;
							pos = getPos(pack);
							_this.treeData.push({
								name: pack,
								fullName: pack,
								children: [],
								type: "environment",
								class: "package",
								isOpen: true,
								dims: pos,
								sortData: [pack.toLowerCase(), pos, "package",
									"package"],
								index: -1,
								//pos: pos,
								parentObject: _this.treeData
							});
							packAdded.push(pack);
						} else if (packAdded.indexOf(pack) == -1) {
							_this.treeData[p].children = [];
							packAdded.push(pack);
						}
					}
				} else {
					line = lines[i].split(sep);
	
					if (line.length < 4)
						continue;
	
					dimNumeric = 1;
					if (dimRegExp.test(line[1])) {
						dim = line[1].split(/x/);
						for (var j in dim)
							dimNumeric *= parseInt(dim[j]);
					}
					var parent = _this.treeData[p];
	
					parent.children.push({
						name: line[0],
						fullName: line[0],
						dims: line[1],
						group: line[2],
						class: line[3],
						list: line[4] == "TRUE",
						type: "object",
						childrenLoaded: false,
						isOpen: false,
						env: pack,
						sortData: [line[0].toLowerCase(),
							dimNumeric, line[3].toLowerCase(),
							line[2].toLowerCase(),
							parent.children.length
						],
						index: -1,
						parentObject: parent
					});
				}
			}
		}
	
		var currentElement = _this.treeData[p];
		_this.sort();
		if (packAdded.length == 1 && currentElement.index != -1)
			_this.treeBox.ensureRowIsVisible(currentElement.index);
	};
	
	function _removeObjectList (pack) {
		for (var i = 0; i < _this.treeData.length; i++) {
			if (_this.treeData[i].name == pack) {
				_this.treeData.splice(i, 1);
				break;
			}
		}
		_createVisibleData();
	};
	
	function _addSubObject (obj) {
		var objName = obj.origItem.name;
		// objList does not quote non syntactic names, so we do it here
		if (
			obj.level == 1
			&& objName.search(/^[a-z\.][\w\._]*$/i) == -1)
			objName = "`" + objName + "`";
		else
			objName = obj.origItem.fullName;
			
		var env = obj.origItem.env.addslashes();
		var id = sv.prefs.getString("sciviews.client.id", "SciViewsK");
		var cmd = 'print(objList(id = "' + id + '_' + env + '_' + objName +
			'", envir = "' + env + '", object = "' + objName +
			'", all.info = FALSE, compare = FALSE), sep = "' + sep +
			'", eol = "\\n")';
		sv.log.debug(cmd);
		sv.r.evalCallback(cmd, _parseSubObjectList, obj);
	};
	
	function _parseSubObjectList (data, obj) {
		var lines = data.split(/[\r\n]{1,2}/);
		
		if (data == "" || (data.trim() == "An empty objects list")
			|| lines.length < 3) {
			obj.isContainer = false;
			_this.treeBox.invalidateRow(obj.origItem.index);
			return;
		}
	
		// This is only for compatibility with different print.objList versions
		// may be removed when final form of output will be estabilished
		// get rid of the "Objects list:" line
		if (lines[0].indexOf("Objects list:") != -1)
			lines.shift()
		if (!lines.length)
			return;
	
		// Environment - 1st line
		var env = lines[0].substr(lines[0].lastIndexOf("=") + 1).trim();
		// Parent object - 2ng line
		var treeParent = lines[1].substr(lines[1].lastIndexOf("=") + 1).trim();
	
		var vd = _this.visibleData;
		if (!obj) {
			// Reloading sub-lists without passing parent tree item not used yet
			if (treeParent) {
				// TODO: smarter way to do it than searching through all items
				for (var i = 0; i < vd.length; i++) {
					if (vd[i].origItem.env == env && vd[i]
						.orgItem.fullName == treeParent) {
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
				if (dimRegExp.test(line[2])) {
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
					sortData: [line[0].toLowerCase(), dimNumeric,
						line[4].toLowerCase(), line[3].toLowerCase(), i],
					index: -1,
					parentObject: origItem
				});
			}
		}
	
		obj.childrenLength = origItem.children.length;
		_this.toggleOpenState(origItem.index);
	};
	
	function _getFilter () {
		var tb = document.getElementById("sciviews_robjects_filterbox");
		var obRx, filterRegExp, test;
	
		if (!tb.value)
			return function (x) {
				return true;
			}
	
		try {
			obRx = new RegExp(tb.value, "i");
			tb.className = "";
			return function (x) {
				return(obRx.test(x));
			}
		} catch (e) {
			obRx = tb.value;
			tb.className = "badRegEx";
			return function(x) {
				return(x.indexOf(obRx) > -1);
			}
		}
	};
	
	this.applyFilter = function () {
		_this.filter = _getFilter();
		_createVisibleData();
	};
	
	this.filter =  function (x) {
		return true;
	};
	
	function _addVItems (item, parentIndex, level, parentUid) {
		if (typeof(item) == "undefined")
			return(parentIndex);
		if (typeof(level) == "undefined") level = -1;
		if (!parentUid) parentUid = "";
		if (!parentIndex) parentIndex = 0;
	
		var idx = parentIndex;
		var len = item.length;
		var conditionalView;
	
		for (var i = 0; i < len; i++) {
			//item[i].class != "package" &&
			if (level == 1 && !_this.filter(item[i].sortData[filterBy])) { 
				item[i].index = -1;
				continue;
				// Set conditionalView = true if any child nodes pass fitering
				//conditionalView = true;
			} else {
				//conditionalView = false;
			}
			idx++;
			var vItem = _getVItem(item[i], idx, level,
				i == 0, i == len - 1,
				parentIndex, parentUid);
			_this.visibleData[idx] = vItem;
	
			if (vItem.isContainer && vItem.isOpen && vItem.childrenLength > 0) {
				var idxBefore = idx;
				idx = _addVItems(item[i].children, idx, level + 1,
					vItem.uid + "»");
	
				// No children is visible
				if (idxBefore == idx) {
					vItem.isContainerEmpty = true;
					// if this item was to be viewed on condition any children
					// is visible, remove this item:
					/*if (conditionalView) {
						this.visibleData.pop();
						idx--;
					}*/
				}
				//sv.log.debug(idx + "<-" + idxBefore);
			}
		}
		return idx;
	};
	
	// Attach one level list of child items to an item
	function _addVIChildren (vItem, parentIndex, isOpen) {
		var children = vItem.origItem.children;
		vItem.isOpen = isOpen;
		var len = children.length;
		vItem.children = [];
		var idx = parentIndex;
		for (var i = 0; i < len; i++) {
			if (vItem.level == 0 && !_this.filter(children[i].name)) {
				children[i].index = -1;
				continue;
			}
			idx++;
			vItem.children
				.push(_getVItem(children[i], idx, vItem.level + 1,
					i == 0, i == len - 1,
					// Closed subtree elements have 0-based parentIndex
					isOpen? parentIndex : 0,
					vItem.uid + "»"));
		}
		vItem.isContainerEmpty = vItem.children.length == 0;
	};
	
	function _getVItem (obj, index, level, first, last, parentIndex, parentUid) {
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
			vItem.isContainerEmpty = vItem.isContainer &&
				(obj.children.length == 0);
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
	};
	
	this.sort =  function (column) {
		var columnName, currentElement, tree, sortDirection, realOrder, order,
			sortDirs;
		tree = document.getElementById("sciviews_robjects_objects_tree");
		sortDirection = tree.getAttribute("sortDirection");

		sortDirs = ["descending", "natural", "ascending", "descending"];
		realOrder = sortDirs.indexOf(sortDirection) - 1;
	
		try {
			currentElement = this.visibleData[this.selection.currentIndex].
				origItem;
		} catch (e) {
			currentElement = null;
		}
	
		// If the column is passed and sort already done, reverse it
		if (column) {
			columnName = column.id;
			if (tree.getAttribute("sortResource") == columnName)
				realOrder = ((realOrder + 2) % 3) - 1;
			else
				realOrder = 1;
		} else {
			columnName = tree.getAttribute("sortResource");
		}
	
		var colNames = ["r-name", "r-dims",  "r-class", "r-group", "r-fullName",
						"r-position"];
		var sCol = colNames.indexOf(columnName);
		var defaultSortCol = 0;
		if (typeof(sCol) == "undefined")
			sCol = 0;
	
		// Sort using original element order
		if (realOrder == 0) {
			sCol = 4;
			order = 1;
		} else {
			order = realOrder;
		}
	
		function _sortCompare (a, b) {
			if (a.sortData[sCol] > b.sortData[sCol]) return 1 * order;
			if (a.sortData[sCol] < b.sortData[sCol]) return -1 * order;
	
			if (sCol != defaultSortCol) {
				if (a.sortData[defaultSortCol] > b.sortData[defaultSortCol])
					return 1;
				if (a.sortData[defaultSortCol] < b.sortData[defaultSortCol])
					return -1;
			}
			return 0;
		}
	
		function _sortComparePkgs (a, b) {
			// Index 1 is the package's position in the search path
			if (a.sortData[1] > b.sortData[1]) return 1;
			if (a.sortData[1] < b.sortData[1]) return -1;
			return 0;
		}
	
		function _sortRecursive (arr) {
			arr.sort(_sortCompare);
			for (var i in arr) {
				if (typeof (arr[i].children) == "object") {
					_sortRecursive(arr[i].children);
				}
			}
		}
	
		sortDirection = sortDirs[realOrder + 1];
	
		// Setting these will make the sort option persist
		tree.setAttribute("sortDirection", sortDirection);
		tree.setAttribute("sortResource", columnName);
	
		var cols = tree.getElementsByTagName("treecol");
		for (var i = 0; i < cols.length; i++) {
			cols[i].removeAttribute("sortDirection");
		}
	
		document.getElementById(columnName)
			.setAttribute("sortDirection", sortDirection);
	
		// Sort packages always by name
		this.treeData.sort(_sortComparePkgs);
		for (var i in this.treeData) {
			if (typeof (this.treeData[i].children) == "object") {
				_sortRecursive(this.treeData[i].children);
			}
		}
	
		_createVisibleData();
	
		if (currentElement) {
			this.selection.select(currentElement.index);
			this.treeBox.ensureRowIsVisible(currentElement.index);
		}
	};
	
	this.foldAll = function (open) {
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
	};
	
	this.toggleOpenState = function (idx) {
		var vd = this.visibleData;
		var item = vd[idx];
		if (!item) {
			//sv.log.debug(idx);
			return;
		}
	
		if (item.isList && !item.origItem.isOpen &&
			!item.origItem.childrenLoaded) {
			_addSubObject(item);
			return;
		}
	
		var rowsChanged;
		var iLevel = item.level;
	
		if (!item.childrenLength) {
			return;
		}
	
		if (item.origItem.isOpen) { // Closing subtree
			var k;
			for (k = idx + 1; k < vd.length && vd[k].level > iLevel; k++) { }
			rowsChanged = k - idx - 1;
			item.children = vd.splice(idx + 1, rowsChanged);
	
			// Make parentIndexes of child rows relative
			for (var i = 0; i < item.children.length; i++) {
				item.children[i].parentIndex -= idx;
			}
	
			// Decrease parentIndexes of subsequent rows
			for (var i = idx + 1; i < vd.length; i++) {
				if (vd[i].parentIndex > idx)
					vd[i].parentIndex -= rowsChanged;
				vd[i].origItem.index = i;
			}
		} else { // Opening subtree
			if (typeof(item.children) == "undefined") {
				_addVIChildren(item, idx, false);
			}
	
			// Filter child items
			var insertItems = [];
			for (var i = 0; i < item.children.length; i++) {
				//if (this.filter(item.children[i].origItem.name)) {
					insertItems.push(item.children[i]);
				//}
			}
	
			rowsChanged = insertItems.length;
			// Change parentIndexes of child rows from relative to absolute
			for (var i = 0; i < insertItems.length; i++) {
				insertItems[i].parentIndex += idx;
				insertItems[i].origItem.index = i + idx + 1;
			}
	
			var vd2 = vd.slice(0, idx + 1).concat(insertItems,
				vd.slice(idx + 1));
			// Increase parentIndexes of subsequent rows:
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
			this.treeBox.rowCountChanged(idx + 1,
				(item.origItem.isOpen? 1 : -1) * rowsChanged);
		this.treeBox.invalidateRow(idx);
	};
	
	this.setTree = function (treeBox) {
		this.treeBox = treeBox;
	};
	
	this.setCellText = function (idx, col, value) {
		this.visibleData[idx].labels[col.index] = value;
	};
	
	this.setCellValue = function (idx, col, value) {
	};
	
	this.getCellText = function (idx, column) {
		//if (column.index == 1)
		//	return "*" + this.visibleData[idx].origItem.sortData[1];
		return _this.visibleData[idx].labels[column.index];
		//+":" + this.visibleData[idx].level;
	};
	
	this.isContainer = function (idx) {
		return this.visibleData[idx].isContainer;
	};
	
	this.isContainerOpen = function (idx) {
		return this.visibleData[idx].origItem.isOpen;
	};
	
	this.isContainerEmpty = function (idx) {
		return this.visibleData[idx].isContainerEmpty;
	};
	
	this.isSeparator = function (idx) {
		return false;
	};
	
	this.isSorted = function () {
		return false;
	};
	
	this.isEditable = function (idx, column) {
		return false;
	};
	
	this.getParentIndex = function (idx) {
		return this.visibleData[idx].parentIndex;
	};
	
	this.getLevel = function (idx) {
		return this.visibleData[idx].level;
	};
	
	this.hasNextSibling = function (idx, after) {
		return !this.visibleData[idx].last;
	};
	
	this.getImageSrc = function (row, col) {
		if (col.index == 0) {
			var Class = this.visibleData[row].origItem.class;
			if (Class == "package" && this.visibleData[row].origItem.name
				.indexOf("package") != 0) {
				Class = "package_green";
			} else if (iconTypes.indexOf(Class) == -1) {
				Class = this.visibleData[row].origItem.group;
				if (iconTypes.indexOf(Class) == -1) {
					return "";
				}
			}
			return "chrome://sciviewsk/skin/images/" + Class + ".png";
		} else
			return "";
	};
	
	this.getCellValue = function (idx, column) {};
	
	this.cycleHeader = function (col, elem) {};
	
	this.selectionChanged = function () {};
	
	this.cycleCell = function (idx, column) {};
	
	this.performAction = function (action) {};
	
	this.performActionOnCell = function (action, index, column) {};
	
	this.getRowProperties = function (idx, props) {
		var item = this.visibleData[idx]
		var origItem = item.origItem;
	
		props.AppendElement(atomSvc.getAtom("type-" + origItem.type));
		props.AppendElement(atomSvc.getAtom("class-" + origItem.class));
	
		if (item.last) {
			props.AppendElement(atomSvc.getAtom("lastChild"));
		}
		if (item.first) {
			props.AppendElement(atomSvc.getAtom("firstChild"));
		}
	};
	
	this.getCellProperties = function (idx, column, props) {
		if (column.id == "r-name") {
			props.AppendElement(atomSvc.getAtom("icon"));
			var item = this.visibleData[idx]
			var origItem = item.origItem;
			props.AppendElement(atomSvc.getAtom("type-" + origItem.type));
			props.AppendElement(atomSvc.getAtom("class-" + origItem.class));
			props.AppendElement(atomSvc.getAtom("group-" + origItem.group));
	
			if (item.isContainerEmpty && origItem.class == "package")
				props.AppendElement(atomSvc.getAtom("empty_package"));
		}
	};
	
	this.getColumnProperties = function (column, element, prop) {};
	
	this.getSelectedRows = function () {
		var start = new Object();
		var end = new Object();
		var rows = new Array();
		var numRanges = this.selection.getRangeCount();
		for (var t = 0; t < numRanges; t++){
			this.selection.getRangeAt(t, start, end);
			for (var v = start.value; v <= end.value; v++) {
				rows.push(v);
			}
		}
		return(rows);
	};
	
	// Drag'n'drop support
	this.listObserver = {
		onDragStart: function (event, transferData, action) {
			_this.onEvent(event);
			var namesArr = _this.getSelectedNames(event.ctrlKey, event.shiftKey);
			transferData.data = new TransferData();
			transferData.data.addDataForFlavour("text/unicode",
				namesArr.join(', '));
			return true;
		},
	
		onDrop: function (event, transferData, session) {
			var path, pos;
			var data = transferData;
			if (transferData.flavour.contentType == "text/unicode")
				path = new String(transferData.data).trim();
			else
				return false;
			pos = _this.searchPaths.indexOf(path);
			if (pos == -1)
				return false;
	
			document.getElementById("sciviews_robjects_searchpath_listbox")
				.getItemAtIndex(pos).checked = true;
			_addObjectList(path);
			return true;
		},
	
		onDragOver: function (event, flavour, session) {
			session.canDrop = flavour.contentType == 'text/unicode'
				|| flavour.contentType == 'text/x-r-package-name';
		},
	
		getSupportedFlavours: function () {
			var flavours = new FlavourSet();
			flavours.appendFlavour("text/x-r-package-name");
			flavours.appendFlavour("text/unicode");
			return flavours;
		}
	};
	
	this.canDrop = function () {
		return false;
	};
	
	this.drop = function (idx, orientation) {};
	
	this.init = function () {
		this.visibleData = [];
		_addObjectList(".GlobalEnv");
		this.getPackageList();
	
		// For compatibility with Komodo 4 where "listbox" apparently does not
		// fire "oncommand" event. So, replace it with "onclick". This causes
		// issue with selection by key-press
		var listBox = document
			.getElementById("sciviews_robjects_searchpath_listbox");
	
		//listBox.oncommand = this.packageSelectedEvent;
	
		if ((typeof listBox.oncommand == "undefined")) {
			listBox.onclick = this.packageSelectedEvent;
			listBox.removeAttribute("oncommand");
		}
		isInitialized = true;
	
		document.getElementById("sciviews_robjects_objects_tree").view = this;
		this.treeBox.scrollToRow(0);
	};
	
	// Callback to process the list of packages in the search path from R
	function _processPackageList (data, refreshObjects) {
		if (data == "") { // No changes
			return;
		}
		_this.searchPaths = data.replace(/[\n\r]/g, "").split(sep);
		_this.displayPackageList(refreshObjects);
	};
	
	// Get the list of packages on the search path from R
	this.getPackageList =  function (refreshObjects) {
		var cmd = 'cat(objSearch(sep = "' + sep + '", compare = FALSE))';
		sv.r.evalCallback(cmd, _processPackageList, refreshObjects);
	};
	
	this.toggleViewSearchPath = function (event) {
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
			broadcaster.setAttribute("state",
				box.collapsed? "collapsed" : "open");
		}
	
		if (!box.collapsed) {
			if (!_this.searchPaths.length) {
				_this.getPackageList();
			}
		}
	}
	
	// Display the list of packages in the search path
	this.displayPackageList = function (refreshObjects) {
		var pack;
		var node = document.
			getElementById("sciviews_robjects_searchpath_listbox");
		while(node.firstChild)
			node.removeChild(node.firstChild);
		var packs = this.searchPaths;
	
		var selectedPackages = new Array(_this.treeData.length);
		for (var i = 0; i < selectedPackages.length; i++) {
			selectedPackages[i] = _this.treeData[i].name;
		}
	
		for(var i = 0; i < packs.length; i++) {
			pack = packs[i];
			var item = document.createElement("listitem");
			item.setAttribute("type", "checkbox");
			item.setAttribute("label", pack);
			item.setAttribute("checked", selectedPackages.indexOf(pack) != -1);
			node.appendChild(item);
		}
	
		if (refreshObjects)
			_this.refreshAll();
	};
	
	// Change the display status of a package by clicking an item in the list
	this.packageSelectedEvent = function (event) {
		var el = event.target;
		var pack = el.getAttribute("label");
		if (!pack)
			return;
		if (el.checked) {
			_addObjectList(pack);
		} else {
			_removeObjectList(pack);
		}
	};
	
	this.refreshAll = function () {
		var selectedPackages = new Array(_this.treeData.length);
		for (var i = 0; i < selectedPackages.length; i++)
			selectedPackages[i] = _this.treeData[i].name;
	
		if (selectedPackages.length == 0)
			selectedPackages.push('.GlobalEnv');
	
		var cmd = 'invisible(sapply(c("' + selectedPackages.join('","')	+
			'"), function(x) ' + 'print(objList(envir = x, all.info = FALSE,' +
			' compare = FALSE), sep = "' + sep +
			'", raw.output = TRUE, header = TRUE)))';
		sv.log.debug(cmd);
		sv.r.evalCallback(cmd, _parseObjectList);
	}
	
	this.refreshGlobalEnv = function (data) {
		this._parseObjectList(data);
	}
	
	//TODO: on package deletion -> remove it also from the search path
	this.removeSelected = function (doRemove) {
		var item, type, name, vItem, cmd = [];
		var rmItems = {}, ObjectsToRemove = {}, envToDetach = [];
		var ObjectsToSetNull = {};
		var rows = this.getSelectedRows();
		if (rows.length == 0)
			return false;
	
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
						while (parent && parent.parentIndex &&
							parent.parentIndex != -1) {
							parent = this.visibleData[parent.parentIndex].
								origItem;
	
							if (!parent || (rmItems[env] &&
								(rmItems[env].indexOf(parent.fullName) != -1))
								|| (parent.type == "environment" &&
								(envToDetach.indexOf(parent.name) != -1))) {
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
	
		for (var i in envToDetach) {
			cmd.push('detach("' + envToDetach[i].addslashes() + '")');
			for (var j in _this.treeData) {
				if (_this.treeData[j].name == envToDetach[i]) {
					_this.treeData.splice(j, 1);
					break;
				}
			}
		}
	
		for (var env in ObjectsToRemove)
			cmd.push('rm(list = c("' + ObjectsToRemove[env].join('", "') +
				'"), pos = "' + env + '")');
	
		for (var env in ObjectsToSetNull) {
			cmd.push('eval(expression(' +
				ObjectsToSetNull[env].join(" <- NULL, ") +
				' <- NULL), envir = as.environment("' + env + '"))');
		}
	
		_createVisibleData();
	
		if (!cmd.length) return false;
	
		if(doRemove) {
			// Remove immediately
			sv.r.evalCallback(cmd.join("\n"), sv.cmdout.append);
		} else {
			// Insert commands to current document
			var view = ko.views.manager.currentView;
			if (!view) return false;
			//view.setFocus();
			var scimoz = view.scimoz;
			var nl = ";" + ["\r\n", "\n", "\r"][scimoz.eOLMode];
			scimoz.scrollCaret();
			scimoz.insertText(scimoz.currentPos, cmd.join(nl) + nl);
		}
	
		_this.selection.select(Math.min(rows[0], _this.rowCount - 1));
		//_this.selection.clearSelection();
		return true;
	}
	
	this.getSelectedNames = function (fullNames, extended) {
		if (typeof extended == 'undefined')
			extended = false;
		var rows = this.getSelectedRows();
		var namesArr = new Array();
		var cellText, item;
		var name = fullNames? "fullName" : "name";
		var selectedItemsOrd = _this.selectedItemsOrd;
		for (i in selectedItemsOrd) {
			item = selectedItemsOrd[i];
			cellText = item[name];
	
			if (cellText) {
				if ((!fullNames || item.type == "object")
					&& cellText.search(/^[a-z\.][\w\._]*$/i) == -1) {
					cellText = "`" + cellText + "`";
				}
				if (!fullNames && extended) {
					if (item.type == "sub-object")
						cellText = '"' + cellText + '"';
					else if (item.group == "function")
						cellText += "()";
					else if (item.type == "args")
						cellText += "="; // Attach '=' to function args
				}
			}
			namesArr.push(cellText);
		}
		return (namesArr);
	}
	
	this.insertName = function (fullNames, extended) {
		// TODO: `quote` non-syntactic names of 1st level (.type = 'object')
		// extended mode: object[c('sub1', 'sub2', 'sub3')]
		var view = ko.views.manager.currentView;
		if (!view) return;
		var text = _this.getSelectedNames(fullNames, extended).join(', ');
		//view.setFocus();
		var scimoz = view.scimoz;
		var length = scimoz.length;
	
		if (scimoz.getWCharAt(scimoz.selectionStart - 1)
			.search(/^[\w\.\u0100-\uFFFF"'`,\.;:=]$/) != -1)
			text = " " + text;
		if (scimoz.getWCharAt(scimoz.selectionEnd)
			.search(/^[\w\.\u0100-\uFFFF"'`]$/) != -1)
			text += " ";
	
		scimoz.insertText(scimoz.currentPos, text);
		scimoz.currentPos += scimoz.length - length;
		scimoz.charRight();
	}
	
	this.setFilterBy = function (menuItem, column) {
		var newFilterBy = ['name', 'dims', 'class', 'group', 'fullName']
			.indexOf(column);
		if (newFilterBy == -1)
			return;
	
		if (newFilterBy != filterBy) {
			var items = menuItem.parentNode.getElementsByTagName("menuitem");
			for (var i = 0; i < items.length; i++)
				items[i].setAttribute("checked", items[i] == menuItem);
	
			filterBy = newFilterBy;
			this.applyFilter();
		 } else {
			menuItem.setAttribute("checked", true);
		 }
	
		 var filterBox = document.getElementById("sciviews_robjects_filterbox") ;
	
		 filterBox.emptyText = menuItem.getAttribute("label") + "...";
		 filterBox.focus();
	
		//document.getElementById("sciviews_robjects_filterbox")
		//    .setAttribute("emptytext", menuItem.getAttribute("label"));
		//sv.alert(document.getElementById("sciviews_robjects_filterbox")
		//    .getAttribute("emptytext"));
		return;
	}
	
	this.contextOnShow = function () {
		var currentIndex = _this.selection.currentIndex;
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
	
			document.getElementById("robjects_cmd_removeobj")
				.setAttribute("disabled", noDetach);
			document.getElementById("robjects_cmd_attach")
				.setAttribute("disabled", noDetach || !isPackage);
			document.getElementById("robjects_cmd_summary")
				.setAttribute("disabled", isFunction || isPackage);
			document.getElementById("robjects_cmd_print")
				.setAttribute("disabled", isPackage);
			document.getElementById("robjects_cmd_plot")
				.setAttribute("disabled", isFunction || isPackage);
			document.getElementById("robjects_cmd_names")
				.setAttribute("disabled", isFunction);
			document.getElementById("robjects_cmd_str")
				.setAttribute("disabled", isPackage);
			document.getElementById("robjects_cmd_help")
				.setAttribute("disabled", !isPackage && !inPackage);
		}
	}
	
	this.do = function (action) {
		var obj = [];
		var rows = _this.getSelectedRows();
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
		// Special handling for help
		case 'help':
			for (i in obj) {
				// Help only for packages and objects inside a package
				if (obj[i].pkg.indexOf("package:") == 0) {
					sv.r.help(obj[i].name, obj[i].pkg.replace(/^package:/, ''));
				} else if (obj[i].name.indexOf("package:") == 0) {
					sv.r.help("", obj[i].name.replace(/^package:/, ''));
				}
			}
		break;
		// Default is to just execute command and display results
		case 'summary':
		case 'plot':
		case 'str':
		case 'names':
		default:
			var cmd = [];
			for (i in obj) {
				cmd.push(action + "(eval(" + obj[i].name +
					", envir = as.environment(\"" +
					obj[i].pkg.addslashes() + "\")))");
			}
			sv.r.eval(cmd.join("\n"));
		}
	
		//var view = ko.views.manager.currentView;
		//if (!view) return;
		//var scimoz = view.scimoz;
		//view.setFocus();
		//scimoz.insertText(scimoz.currentPos, res.join(";" +
		//    ["\r\n", "\n", "\r"][scimoz.eOLMode]));
	}
	
	this.selectedItemsOrd = [];
	
	this.onEvent = function (event) {
		switch (event.type) {
			case "select":
				var selectedRows = _this.getSelectedRows();
				var selectedItems = [];
				for (var i = 0; i < selectedRows.length; i++)
					selectedItems.push(_this.visibleData[selectedRows[i]].origItem);
				var curRowIdx = selectedRows.indexOf(_this.selection.currentIndex);
	
				// This maintains array of selected items in order they were
				// added to selection
				var prevItems = _this.selectedItemsOrd;
				var newItems = [];
				for (var i = 0; i < prevItems.length; i++) {
					var j = selectedItems.indexOf(prevItems[i]);
					if (j != -1) // Present in Prev, but not in Cur
						newItems.push(prevItems[i])
				}
				for (var i = 0; i < selectedItems.length; i++) {
					if (prevItems.indexOf(selectedItems[i]) == -1) {
						// Present in Cur, but not in Prev
						newItems.push(selectedItems[i]);
					}
				}
				_this.selectedItemsOrd = newItems;
				return;
			case "keyup":
			case "keypress":
				var key = event.keyCode? event.keyCode : event.charCode;
				switch (key) {
					//case 38: // up
					//case 40: // down
					//	if (event.shiftKey) {
					//		sv.log.debug("Select: " +
					//          _this.visibleData[_this.selection.currentIndex]
					//          .origItem.name);
					//	}
					//	return;
					case 46: // Delete key
						_this.removeSelected(event.shiftKey);
						event.originalTarget.focus();
						return;
					case 45: // Insert
					case 32: // Space
						sv.log.debug("Insert");
						break;
					case 65: // Ctrl + A
						if (event.ctrlKey){
							_this.selection.selectAll();
						}
					case 0:
						return;
					case 93:
						// Windows context menu key
						var contextMenu = document.
							getElementById("rObjectsContext");
						_this.treeBox.
							ensureRowIsVisible(_this.selection.currentIndex);
						var y = ((2 + _this.selection.currentIndex -
							_this.treeBox.getFirstVisibleRow())
							* _this.treeBox.rowHeight)	+ _this.treeBox.y;
						var x = _this.treeBox.x;
						contextMenu.openPopup(null, "after_pointer", x, y, true);
	
					// TODO: Escape key stops retrieval of R objects
					default:
						return;
				}
				break;
			case "dblclick":
				if (event.button != 0)	return;
				if (_this.selection && (_this.selection.currentIndex == -1
					|| _this.isContainer(_this.selection.currentIndex)))
					return;
				break;
			case "click":
			case "draggesture":
				return;
			default:
		}
		sv.log.debug("event.type = " + event.type);
		// Default action: insert selected names
		_this.insertName(event.ctrlKey, event.shiftKey);
	
		// This does not have any effect
		//document.getElementById("sciviews_robjects_objects_tree").focus();
		event.originalTarget.focus();
	}
	
	// Drag & drop handling for search paths list
	this.packageListObserver = {
		onDrop : function (event, transferData, session) {
			var data = transferData;
			sv.log.debug("dropped object was " +
				transferData.flavour.contentType);
			var path;
			if (transferData.flavour.contentType == "application/x-moz-file") {
				path = transferData.data.path;
			} else if (transferData.flavour.contentType == "text/unicode") {
				path = new String(transferData.data).trim();
			}
			// Attach the file if it is an R workspace
			if (path.search(/\.RData$/i) > 0) {
				//sv.alert("will attach: " + path);
				sv.r.loadWorkspace(path, true, function(message) {
					_this.getPackageList();
					sv.alert(sv.translate("Attach workspace, R said:"), message);
				});
			} else {
				path = path.replace(/^package:/, "");
	
				sv.r.evalCallback("tryCatch(library(\"" + path +
					"\"), error=function(e) {cat(\"<error>\"); message(e)})",
					function (message) {
						if (message.indexOf('<error>') > -1) {
							message = message.replace('<error>', '');
						} else {
							_this.getPackageList();
						}
						if (message) {
							sv.alert(sv.translate("Load library, R said:"), message);
						}
					}
				);
			}
			return true;
		},
	//	onDragEnter: function (event, flavour, session) {
	//		sv.log.debug(event.type + ":" + session);
	////package:gpclibpackage:adehabitat
	//		//sv.xxx = session;
	//	},
		//
		//onDragExit: function (event, session) {
		//	//sv.log.debug(event.type + ":" + session);
		//},
		onDragStart: function (event, transferData, action) {
			if (event.target.tagName != 'listitem')
				return false;
	
			var text = _this.searchPaths[document
				.getElementById("sciviews_robjects_searchpath_listbox")
				.selectedIndex];
			transferData.data = new TransferData();
			transferData.data.addDataForFlavour("text/unicode", text);
			return true;
		},
	
		onDragOver: function (event, flavour, session) {
			session.canDrop = flavour.contentType == 'text/unicode'
							   || flavour.contentType == 'application/x-moz-file';
		},
	
		getSupportedFlavours: function () {
			var flavours = new FlavourSet();
			flavours.appendFlavour("application/x-moz-file","nsIFile");
			flavours.appendFlavour("text/unicode");
			return flavours;
		}
	}
	
	this.packageListKeyEvent = function (event) {
		var keyCode = event.keyCode;
		switch(keyCode) {
			case 46: // Delete key
				var listbox = event.target;
				var listItem = listbox.selectedItem;
				var pkg = listItem.getAttribute("label");
	
				if (pkg == ".GlobalEnv" || pkg == "TempEnv")
					return;
	
				sv.r.evalCallback(
					'tryCatch(detach("' + pkg.addslashes() +
					'"), error = function(e) cat("<error>"));',
					function (data) {
						sv.log.debug(data);
						if (data.trim() != "<error>") {
							_removeObjectList(pkg);
							listbox.removeChild(listItem);
							sv.cmdout.append(sv.translate(
								"Namespace %S detached.", pkg));
						} else {
							sv.cmdout.append(sv.translate(
								"Namespace %S could not be detached.", pkg));
						}
				});
				return;
			default:
				return;
		}
	}
	
	//_setOnEvent("sciviews_robjects_searchpath_listbox", "ondragdrop",
	//		"nsDragAndDrop.drop(event, sv.r.objects.packageListObserver);"
	//		);
	//_setOnEvent("sciviews_robjects_searchpath_listbox", "ondragover",
	//		"nsDragAndDrop.dragOver(event, sv.r.objects.packageListObserver);"
	//		);
	//_setOnEvent("sciviews_robjects_searchpath_listbox", "ondragexit",
	//		"nsDragAndDrop.dragExit(event, sv.r.objects.packageListObserver);"
	//		);
	//_setOnEvent("sciviews_robjects_searchpath_listbox", "ondraggesture",
	//		"nsDragAndDrop.startDrag(event, sv.r.objects.packageListObserver);"
	//		);
	//_setOnEvent("sciviews_robjects_objects_tree_main", "ondragover",
	//		"nsDragAndDrop.dragOver(event, sv.r.objects.listObserver);"
	//		);
	//_setOnEvent("sciviews_robjects_objects_tree_main", "ondragdrop",
	//		"nsDragAndDrop.drop(event, sv.r.objects.listObserver);"
	//		);

} ).apply(sv.r.objects);

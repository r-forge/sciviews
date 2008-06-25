// SciViews-K R unit functions
// Define the 'sv.r.unit' namespace
// Copyright (c) 2008, Philippe Grosjean

////////////////////////////////////////////////////////////////////////////////
// sv.r.unit.version // Version of the svUnit R package it was designed for
// sv.r.unit.release; // The release (bug fixes). Full version is "version.release"
//
// sv.r.unit.getRUnitList(); // Get the list of available units
// sv.r.unit.showRUnitList(); // Show/hide the unit list
// sv.r.unit.setAutoTest(state); // Change autoTest on/off
// sv.r.unit.isAutoTest(); // Is it currently in autoTest mode?
// sv.r.unit.autoTest(); // autoTest on/off, not supposed to be called directly
// sv.r.unit.runTest(); // Run the R test suite
// sv.r.unit.runTest_feedback(data); // Feedback during run of the R test suite
// sv.r.unit.runTest_finished(data); // The test suite is done in R
// sv.r.unit.showRUnitPane(); // Show the R Unit pane
// sv.r.unit.jumpToObject(event); // Go to the corresponding object (user event)
// sv.r.unit.fillInTooltip(event); // Change the tooltip content (user event)
//
////////////////////////////////////////////////////////////////////////////////
//
// TODO:
// * Modify FileObserver to use run tests only if a R file changes (or even only
//   if R code is loaded in R, or a R package is installed!)
// * In AutoMode, also trigger test units when something is submitted to R
// * Allow for progression indication using sv.r.runTest_feedback()
// * Bug: arrows in the tree do not change their orientation when nodes are
//   opened or closed
// * Autoinstallation of the -ko.xpi and version checking when the svUnit R
//   package is loaded in R
// * Finalize localization
//
////////////////////////////////////////////////////////////////////////////////

// Make sure that 'sv.r' is defined, i.e., the SciViews-K extension is loaded
if (typeof(sv.r) == 'undefined') {
    alert("You must install the SciViews-K extension to use SciViews-K Unit! Visit http://www.sciviews.org/SciViews-K to download it.")
} else {

// Define the 'sv.r.unit' namespace
if (typeof(sv.r.unit) == 'undefined') sv.r.unit = {
	version: 0.6,
	release: 0,
	debug: true
};

(function() { // 'sv.r.unit' namespace inside closure

	var DEACTIVATED = 0;
	var PASS = 1;
    var FAIL = 2;
    var ERROR = 3;

    var CELLTEXT = 0;
    var LEVEL = 1;
    var ERRORTYPE = 2;
    var ERRORTEXT = 3;
    var OPEN = 4;
    var PARENT = 5;
    var ID = 6;
    var URI = 7;

    var gUnitTestRunning = false;
    var gUnitTreeObject = null;
    var gFileObserver = new _FileObserver();
    var gPrefSvc = Components.classes["@activestate.com/koPrefService;1"].
        getService(Components.interfaces.koIPrefService);

	var gUnitList = [];
	var gOldUnitList = [];
	var gUnitListSelected = [];

	this.showRUnitList = function() {
		var splitter = document.getElementById("svunit_splitter");
		var state = splitter.getAttribute("state");
		if (state == "collapsed") {
			state = "open";
			this.getRUnitList();
		} else {
			state = "collapsed";
		}
		splitter.setAttribute("state", state);
	}

	this.getRUnitList = function() {
		// TODO: a more sophisticated process looking (1) if svUnit R package
		// is installed, and (2) if its version is correct. If not, propose to
		// install or update it!
		sv.r.evalHidden('require(svUnit, quietly = TRUE)', false);	// Make sure svUnit is loaded
		var cmd = 'cat(guiSuiteList(sep = ",", compare = FALSE))';
		sv.r.evalCallback(cmd, sv.r.unit.getRUnitList_Callback);
	}

	this.getRUnitList_Callback = function(data) {
		gUnitList = [];
		if (data != "")
			gUnitList = data.replace(/[\n\r]/g, "").split(/,/);
		// Add unit tests in currently edited packages
		// TODO: add items from all opened projects, not just active one
		var numfiles = new Object();
        var projfiles = new Array();
        var project = ko.projects.manager.getCurrentProject();
        if (project != null) {
            project.getAllContainedURLs(projfiles, numfiles);
            var files = projfiles.value;
            for (var i=0; i<numfiles.value; i++) {
                if (files[i].slice(0, 4) == "runit" &&
					(files[i].slice(-2) == '.r' ||
                    files[i].slice(-2) == '.R'))
                    gUnitList.push("dir:" + files[i]);
            }
        }
		// Display the unit list
		var unit;
		var node = document.getElementById("svunit_unitlist_listbox");
		sv.tools.e4x2dom.clear(node);
		var item;
		var k = 0;
		var checked = "false";
		for(var i = 0; i < gUnitList.length; i++) {
			unit = gUnitList[i];
			if (isSelected(unit)) {
				ischecked = "true";
				if (!isInOldList(unit))
					gOldUnitList[gOldUnitList.length] = unit; // Add it
			} else if (isInOldList(unit)) {
				ischecked = "false";
			} else {	// New items are automatically added to selected items
				ischecked = "true";
				gUnitListSelected[gUnitListSelected.length] = unit;
				gOldUnitList[gOldUnitList.length] = unit;
			}
			item =
				<listitem type="checkbox" label={unit} checked={ischecked}
				  onclick="sv.r.unit.unitSelect(event);"
		          spid={unit}
		         />;
		    sv.tools.e4x2dom.append(item, node, k);
		    k++;
		}
	}

	this.unitSelect = function(event) {
		var cb = event.target;
		var status = cb.checked;
		var unit = cb.getAttribute("spid");
		if (status) {
			if (!isSelected(unit)) {
				gUnitListSelected[gUnitListSelected.length] = unit;
			}
		} else {
			if (isSelected(unit)) {
				sv.tools.array.remove(gUnitListSelected, unit);
			}
	    }
	}

	function isSelected(unit) {
		return(sv.tools.array.contains(gUnitListSelected, unit));
	}

	function isInOldList(unit) {
		return(sv.tools.array.contains(gOldUnitList, unit));
	}

	this.setAutoTest = function(state) {
		var autoTestButton = document.getElementById('svunit-auto-tests-button');
		if (autoTestButton.checked != state) {
			autoTestButton.checked = state;
			this.autoTest();
		}
	}

	this.isAutoTest = function() {
		var autoTestButton = document.getElementById('svunit-auto-tests-button');
		return(autoTestButton.checked);
	}

	this.autoTest = function() {
        try {
            var autoTestButton = document.getElementById('svunit-auto-tests-button');
            var runTestsButton = document.getElementById('svunit-run-tests-button');
            //runTestsButton.disabled = autoTestButton.checked;
            if (autoTestButton.checked) {
                gUnitTestRunning = false;   // Reset testing flag TODO: what if test is running?
                gFileObserver.addObserver();
                this.runTest();
            } else {
                gFileObserver.removeObserver();
            }
            gPrefSvc.prefs.setBooleanPref("svunitAutoTest", autoTestButton.checked);
        } catch (e) {
            alert(e);
        }
    }

    this.runTest = function () {
        if (!gUnitTestRunning) {
            try {
                // Determine, among select test, which one are in the current list
				var Selected = [];
				k = 0;
				for (var i = 0; i < gUnitList.length; i++) {
					if (sv.tools.array.contains(gUnitListSelected, gUnitList[i])) {
						Selected[k] = gUnitList[i];
						k += 1;
					}
				}
				if (Selected.length == 0) {
					// If not autotest, issue a warning
					ko.statusBar.AddMessage("No test selected. Do '?svUnit' in R to learn how to create tests...", "svUnit", 2000, true);
					return;
				}
				// Start running the tests
				gUnitTestRunning = true;
				// Update the GUI
                var pass_label = document.getElementById('svunit-pass-label');
                pass_label.value = "Pass: -"
                var fail_label = document.getElementById('svunit-fail-label');
                fail_label.value = "Fail: -"
                var error_label = document.getElementById('svunit-error-label');
                error_label.value = "Errors: -"
				var deact_img = document.getElementById('svunit-deactivated-image');
				deact_img.setAttribute("tooltiptext", "");
				deact_img.src = "";
				var statusbar_pane = document.getElementById('statusbar-svunit');
                statusbar_pane.src = "chrome://famfamfamsilk/skin/icons/hourglass.png";
				statusbar_pane.setAttribute("tooltiptext", "R Unit Status: running");
				var progressbar = document.getElementById('svunit-progress-bar');
				progressbar.style.backgroundColor = "#E6E6E6";
				// Collect together selected tests and run them
				var cmd = 'require(svUnit, quietly = TRUE); createLog(deleteExisting = TRUE); runTest(svSuite(c("'
				cmd = cmd + Selected.join('", "')
				cmd = cmd + '")), name = "objects"); cat(guiTestReport(Log()))'
//				if (this.debug) alert("'" + cmd + "'");
				var res = sv.r.evalCallback(cmd, sv.r.unit.runTest_finished);
				ko.statusBar.AddMessage("R unit test started", "svUnit", 1000, true);
            } catch(e) {
                alert(e);
            }
        }
    }

    this.runTest_feedback = function(data) {
        gUnitTestRunning = true;
        // TODO: provide feedback about tests execution
    }

    this.runTest_finished = function(data) {
        try {
			ko.statusBar.AddMessage("", "svUnit");
			gUnitTestRunning = false;

			if (this.debug) { // For debugging purposes
				gUnitData = data;
			}

			if (sv.tools.strings.removeLastCRLF(data) != "" &&
				gUnitTreeObject) {
				var items = data.split("\t");
				var item = [];
				var tests = [];
				var nPass = 0;
				var nFail = 0;
				var nError = 0;
				var nDeactivated = 0;
				var k = 0;
				for (var i = 0; i < items.length; i++) {
					item = items[i].split("|||")
					// svUnit items start with '<<<svUnit'
					if (item[0] == "<<<svUnitSummary>>>") {
						nPass = item[1];
						nFail = item[2];
						nError = item[3];
						nDeactivated = item[4];
					} else if (item[0] == "<<<svUnitFile>>>") {
						// TODO: create a new file node
					} else if (item[0] == "<<<svUnitTest>>>") {
						tests[k] = item;
						k += 1;
					}
				}
				// Update the tree
				gUnitTreeObject.UnitTreeView.loadTests(tests);
				// Update the GUI
                var pass_label = document.getElementById('svunit-pass-label');
                pass_label.value = "Pass: " + nPass
                var fail_label = document.getElementById('svunit-fail-label');
                fail_label.value = "Fail: " + nFail
                var error_label = document.getElementById('svunit-error-label');
                error_label.value = "Errors: " + nError
				var deact_img = document.getElementById('svunit-deactivated-image');
				if (nDeactivated == 0) {
					deact_img.setAttribute("tooltiptext", "");
					deact_img.src = "";
				} else if (nDeactivated == 1) {
					deact_img.setAttribute("tooltiptext", "Warning: " +
						nDeactivated + " test is deactivated!");
					deact_img.src = "chrome://famfamfamsilk/skin/icons/help.png";
				} else {
					deact_img.setAttribute("tooltiptext", "Warning: " +
						nDeactivated + " tests are deactivated!");
					deact_img.src = "chrome://famfamfamsilk/skin/icons/help.png";
				}
                // Update bar in test pane
                var progressbar = document.getElementById('svunit-progress-bar');
				if (nFail > 0 || nError > 0)
                    progressbar.style.backgroundColor = "#C00000";
                else
                    progressbar.style.backgroundColor = "#008000";
                // update icon in statusbar
                var statusbar_pane = document.getElementById('statusbar-svunit');
                if (nError > 0) {
                    statusbar_pane.src = "chrome://famfamfamsilk/skin/icons/delete.png";
					statusbar_pane.setAttribute("tooltiptext", "R Unit Status: error (" + nError + ")");
				} else if (nFail > 0) {
                    statusbar_pane.src = "chrome://famfamfamsilk/skin/icons/error.png";
					statusbar_pane.setAttribute("tooltiptext", "R Unit Status: fail (" + nFail + ")");
				} else {
                    statusbar_pane.src = "chrome://famfamfamsilk/skin/icons/accept.png";
					statusbar_pane.setAttribute("tooltiptext", "R Unit Status: ok");
				}
			}
		} catch(e) {
            alert(e);
        }
    }

    this.showRUnitPane = function(state) {
        if (state == null) {
			// Toggle RUnit pane
			ko.uilayout.togglePane('workspace_right_splitter',
				'right_toolbox_tabs', 'cmd_viewRightPane');
			if (ko.uilayout.isPaneShown(document.getElementById('right_toolbox_tabs'))) {
				// Make the R Unit tab the current tab that is shown
				ko.uilayout.ensureTabShown("sciviews_svunit_tab", false);
			}
        } else if (state == true) {
			// Make sure the R Unit tab is displayed
			ko.uilayout.ensureTabShown("sciviews_svunit_tab", false);
		} else {
			if (ko.uilayout.isPaneShown(document.getElementById('right_toolbox_tabs'))) {
				// Hide the R Unit tab
				ko.uilayout.togglePane('workspace_right_splitter',
					'right_toolbox_tabs', 'cmd_viewRightPane');
			}
		}
    }

    function getRowForEvent(event) {
        var row = new Object();
        var colId = new Object();
        var child = new Object();
        var tree = document.getElementById('svunit_tree');
        var boxObject = tree.boxObject;
        boxObject.QueryInterface(Components.interfaces.nsITreeBoxObject);
        boxObject.getCellAt(event.clientX, event.clientY, row, colId, child);
        return row.value;
    }

    this.jumpToObject = function(event) {
        try {
            var row = getRowForEvent(event);
            var view = gUnitTreeObject.UnitTreeView;
            if (!view.rows[row] ||
                view.getChildren(row).length > 0) {
                event.stopPropagation();
                event.preventDefault();
                event.cancelBubble = true;
            }
            if (view.rows[row][URI] && view.rows[row][URI] != ""
                && view.getChildren(row).length == 0) {
                var urilist = view.rows[row][URI].split("#");
				// Look at urilist[1]: number => goto line, name => search for it
				if (urilist[1]) {
					if (parseInt(urilist[1]) > 0) { // Goto line...
						gViewMgr.doFileOpenAtLine(urilist[0], urilist[1], 'editor');
					} else { // Look for the function in the file
						gViewMgr.doFileOpenAtLine(urilist[0], 1, 'editor');
						var FindService = Components.classes['@activestate.com/koFindService;1'].
							getService(Components.interfaces.koIFindService);
						var FindContext = Components.classes['@activestate.com/koFindContext;1'].
							createInstance(Components.interfaces.koIFindContext);
						var FindSession = Components.classes['@activestate.com/koFindSession;1'].
							getService(Components.interfaces.koIFindSession);
						var FindOptions = FindService.options;
						FindContext.type = FindOptions.preferredContextType;
						FindOptions.patternType = FindOptions.FOT_REGEX_PYTHON;
						FindOptions.searchBackward = false;
						var FindPattern = urilist[1].replace(/[\n\r]/g, "") + '("|\'|`)?\\s*(<-|=)';
						Find_FindNext(window, FindContext, FindPattern,
							'find', true, false);
					}
				} else {
					gViewMgr.doFileOpen(urilist[0].replace(/[\n\r]/g, ""), 'editor');
				}
				var kv = ko.views.manager.currentView;
				kv.setFocus();
				kv.scimoz.homeDisplay();
            }
        }
        catch (e) {
            alert(e);
        }
    }

    function fillInTooltip(event) {
        try {
            var row = getRowForEvent(event);
            var tip = document.getElementById('svunit-tooltip');
            var tree = document.getElementById('svunit_tree');
            var view = gUnitTreeObject.UnitTreeView;
            if (!view.rows[row] || view.getChildren(row).length > 0) {
                event.stopPropagation();
                event.preventDefault();
                event.cancelBubble = true;
                return false;
            }
            var etext = view.rows[row][ERRORTEXT];
            var elist = etext.split('\n');
            var textholder = document.getElementById('svunit-tooltip-container');
            while (textholder.hasChildNodes())
                textholder.removeChild(textholder.firstChild);
            for (var i=0; i<elist.length; i++) {
                var descriptionNode = document.createElement("description");
                var linetext = document.createTextNode(elist[i]);
                descriptionNode.appendChild(linetext);
                textholder.appendChild(descriptionNode);
            }
            tip.setAttribute('style','height: 0px');
            tip.showPopup(tree,event.clientX,event.clientY,
                'tooltip',"topleft","topleft");
            var box = document.getBoxObjectFor(textholder);
            tip.setAttribute('style','height: '+ box.height + 'px');
        } catch (e) {
            alert(e);
            return false;
        }
        return true;
    }

    // File observer used to trigger tests of file/project changed
    function _FileObserver() {
        this.obsSvc = Components.classes["@mozilla.org/observer-service;1"].
            getService(Components.interfaces.nsIObserverService);
        this.added = false;
    }

    _FileObserver.prototype.constructor = _FileObserver;

    _FileObserver.prototype.addObserver = function() {
        if (!this.added) {
            this.obsSvc.addObserver(this, "file_changed", false);
        //    this.obsSvc.addObserver(this, "file_project", false);
        //    this.obsSvc.addObserver(this, "current_project_changed", false);
            this.added = true;
        }
    }

    _FileObserver.prototype.removeObserver = function() {
        if (this.added) {
            this.obsSvc.removeObserver(this, "file_changed");
        //    this.obsSvc.removeObserver(this, "file_project");
        //    this.obsSvc.removeObserver(this, "current_project_changed");
            this.added = false;
        }
    }

    _FileObserver.prototype.finalize = function() {
        this.removeObserver();
    }

    _FileObserver.prototype.observe = function(subject, topic, data) {
        try {
            if (topic == "file_changed") {
				// If an R source file is changed; if auto mode, source it...
				if (data.substr(-2, 2).toUpperCase() == ".R" &
					sv.r.unit.isAutoTest()) {
					sv.r.eval('source("' + ko.uriparse.URIToLocalPath(data).replace(/\\/g, "/") + '")');
					// ... then, run the selected test
					sv.r.unit.runTest();
				}
			}
        } catch(e){
            alert(e);
        }
    }

    // Custom tree view for displaying tests performed by svUnit
    function _UnitTreeView() {
        this._debug = 0;
        this._showHidden = false;
        this.rows = [];
        this.testItems = [];
    }

    _UnitTreeView.prototype = {
        // The nsITreeView object for the tree view
        getCellText : function(row, column) {
            return this.rows[row][CELLTEXT];
        },
        get rowCount() { return this.rows.length; },

        // Everything below here is just to satisfy the interface, and not all
        // of it may be required
        tree : null,
        getLevel: function(row) {
            return this.rows[row][LEVEL];
            },
        setTree : function(out) { this.tree = out; },
        getRowProperties : function(row,prop) {},
        getColumnProperties : function(column,prop){},
        getCellProperties : function(row,column,props) {},
        cycleCell: function(row, colId) {},
        selectionChanged : function() {},
        performAction : function(action) {},
        isSorted : function() { return false; },
        getImageSrc : function(row, col) {
            var errorType = parseInt(this.rows[row][ERRORTYPE]);
			if (errorType == PASS)
                return "chrome://famfamfamsilk/skin/icons/bullet_green.png";
            else if (errorType == FAIL)
                return "chrome://famfamfamsilk/skin/icons/bullet_error.png";
            else if (errorType == ERROR)
                return "chrome://famfamfamsilk/skin/icons/bullet_delete.png";
			else if (errorType == DEACTIVATED)
				return "chrome://famfamfamsilk/skin/icons/bullet_white.png";
            return null;
        },
        cycleHeader : function() {},
        isSeparator : function(row) { return false; },

        // Multi level tree functions
        getParentIndex: function(row) {
            return this.rows[row][PARENT];
        },
        isContainer : function(row) { return this.getChildren(row).length > 0; },
        isContainerOpen: function(row) { return this.rows[row][OPEN]; },
        isContainerEmpty: function(row) { return false; },

        hasNextSibling: function(row, after) {
            var level = this.getLevel(row);
            // March on!
            var l;
            while (++row < this.rows.length) {
                l = this.getLevel(row);
                if (l < level)
                    return false;
                else if (l == level && row > after)
                    return true;
            }
            return false;
        },
        toggleOpenState: function(row) {
            window.setCursor("wait");
            try {
                var rowItem = this.rows[row];
                if (rowItem[OPEN]) {
                    // close subtree
                    rowItem[OPEN] = false;

                    var thisLevel = rowItem[LEVEL];
                    var deletecount = 0;
                    for (var t = row + 1; t < this.rows.length; t++) {
                        if (this.getLevel(t) > thisLevel)
                            deletecount++;
                        else
                            break;
                    }
                    if (deletecount) {
                        this.rows.splice(row + 1, deletecount);
                        this.tree.rowCountChanged(row + 1, -deletecount);
                    }
                } else {
                    // open subtree
                    rowItem[OPEN] = true;
                    var entries = this.getChildren(row);
                    var nodecount = 0;
                    for (var i = 0; i < entries.length; i++) {
                        child = entries[i];
                        this.rows.splice(row + nodecount + 1, 0, child);
                        nodecount += 1;
                    }
                    this.tree.rowCountChanged(row + 1, nodecount);
                }
            } catch (e) {
                alert(e);
            }
            window.setCursor("auto");
        }
    }

    _UnitTreeView.prototype.getChildren = function(row) {
        var parentId = this.rows[row][ID];
        var currLevel = this.rows[row][LEVEL];
        var children = [];
        for (var i=0; i<this._testItems.length; i++) {
            var rowId = this._testItems[i][ID];
            if (rowId == parentId) {
                for (var j=i+1; j<this._testItems.length; j++) {
                    var rowItem = this._testItems[j];
                    if (rowItem[LEVEL] <= currLevel)
                        break;
                    children.push(rowItem);
                }
                break;
            }
        }
        return children;
    }

    _UnitTreeView.prototype.loadTests = function(tests) {
        try {
            this.tree.rowCountChanged(0, -this.rows.length);
            var new_rows = [];
            var old_row = ['','',''];
            var id = 0;
            var k = 0;
			var parentArray = [-1, 0, 1, 999]; // last value is unused
            for (var i=0; i < tests.length; i++) {
                var test = tests[i];
				var subtree = test[1].split('>');
				var errorType = parseInt(test[2]);
				var errorText = test[3];
				var URI = test[4];
                var level = 0;
                // Create a hierarchy in the test nodes (Unit > File > Function)
                if (subtree[0] == old_row[0] && subtree[1] == old_row[1])
                    level = 2;
                else if (subtree[0] == old_row[0])
                    level = 1;
                for (k=level; k<subtree.length; k++) {
                    // nodetext, depth, errortype, errortext, open, parentIdx,
                    // id, linenum
                    new_rows.push([subtree[k], k, errorType, errorText, 1,
                        parentArray[k], id , URI]);
                    parentArray[k+1] = id;
                    id += 1;
                }
                var currParent = parentArray[subtree.length-1];
                while (currParent != -1) {
                    if (new_rows[currParent][ERRORTYPE] < errorType)
                        new_rows[currParent][ERRORTYPE] = errorType;
                    currParent = new_rows[currParent][PARENT];
                }
                old_row = subtree;
            }
            this._testItems = new_rows.slice(0); // get a unique copy
            this.rows = new_rows;
            this._errors = errorText;

            // Using rowCountChanged to notify rows were added
            this.tree.rowCountChanged(0, this.rows.length);
        } catch (e) {
            alert(e);
        }
    }

    function _UnitTree() {
        try {
            // Find some xul elements
			// TODO: look in prefs if the unit list is visible or not and change
			// its state accordingly
            this.svunit_tree = document.getElementById("svunit_tree");
            this.loadTree();
            document.getElementById('svunit-tooltip').
                addEventListener('popupshowing', fillInTooltip, true);
            var autoTestSetting = true;
            if (gPrefSvc.prefs.hasPref("svunitAutoTest"))
                autoTestSetting = gPrefSvc.prefs.getBooleanPref("svunitAutoTest");
            else
                gPrefSvc.prefs.setBooleanPref("svunitAutoTest", autoTestSetting);
            if (autoTestSetting == true) {
                document.getElementById('svunit-auto-tests-button').checked = true;
            } else {
                document.getElementById('svunit-auto-tests-button').checked = false;
            }
			sv.r.unit.getRUnitList();
			sv.r.unit.autoTest();
        } catch (e) {
            alert(e);
        }
    }

    _UnitTree.prototype.loadTree = function() {
        try {
            this.UnitTreeView = new _UnitTreeView();
            this.svunit_tree.treeBoxObject.view = this.UnitTreeView;
        } catch (e) {
            alert(e);
        }
    }

    this.InitOverlay = function() {
        gUnitTreeObject = new _UnitTree();
    }

}).apply(sv.r.unit);

// Ensure we load the remote server information when the overlay is loaded
addEventListener("load", sv.r.unit.InitOverlay, false);
}

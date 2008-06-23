// SciViews-K functions
// Define default preferences values for SciViews-K
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

// Define default socket ports for the client and server, and other parameters
sv.prefs.setString("sciviews.server.socket", "7052", false);
sv.prefs.setString("sciviews.client.socket", "8888", false);
sv.prefs.setString("sciviews.client.id", "SciViewsK", false);

// Where do we want to display R help? In internal browser or not?
sv.prefs.setString("sciviews.r.help", "internal", false);

// This is the base path for the R Wiki context help feature of sv.helpContext()
sv.prefs.setString("sciviews.rwiki.help.base",
	"http:/wiki.r-project.org/rwiki/doku.php?id=", false);

// SciViews-K R functions
// Define functions to command R from Komodo Edit
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.r.console' namespace
if (typeof(sv.r.console) == 'undefined') sv.r.console = { };

sv.r.console.handleConsoleInputKey = function(e){
  var cmd = sv.r.console.getConsoleContent() ;
  
  if( e.keyCode == 9){ // TODO: [tab]: trigger completion, 
    return(0); 
  }
  
  if( e.keyCode == 38 && e.ctrlKey ){ // [ctrl] + [up]: cycle history
    return(0);
  }
  
  if( e.keyCode == 40 && e.ctrlKey ){ // [ctrl] + [down]: cycle history
    return(0);    
  }
  
  if( e.keyCode == 13){ // [enter] pressed : submit to R
    sv.r.console.parse(cmd) ;
    return(0); 
  }
  
  return(0);

}

sv.r.console.getConsoleContent = function(){
  return document.getElementById("sciviews_rconsole_console_input").value ;
}

sv.r.console.clearConsoleContent = function(){
  document.getElementById("sciviews_rconsole_console_input").value = "" ;
}

// parse code using Parse and run it if possible
sv.r.console.parse = function(cmd){
  cmd = "Parse('" + cmd.replace(/'/g, "\\'")  + "')" ;
  sv.r.evalCallback(cmd, sv.r.console.parse_cb); 
}

// callback called after an R command is parsed
sv.r.console.parse_cb = function(data){
  if(data.substring(0,10) == "expression" ){
    // command is ok, run it
    sv.r.evalCallback( sv.r.console.getConsoleContent() , sv.r.console.run_cb);
  } 
  
}

// callback called after an R cmmand is run
sv.r.console.run_cb  = function(data){
  var output = document.getElementById("sciviews_rconsole_console_results") ;
  var cmd = sv.r.console.getConsoleContent();
  
  var div =
      <html:pre class="consoleInput" xmlns:html="http://www.w3.org/1999/xhtml">{ "R> " + cmd }</html:pre> ;
  sv.tools.e4x2dom.appendTo(div,output) ;
  
  var div =
      <html:pre class="consoleOutput" xmlns:html="http://www.w3.org/1999/xhtml">{data}</html:pre> ;
  sv.tools.e4x2dom.appendTo(div,output) ;
  
  // add the current command to the history and refresh the history
  sv.r.console.addCommandToHistory(cmd);
  sv.r.console.refreshHistory();
  
}

sv.r.console.addCommandToHistory = function(cmd){
  sv.r.console.history[ sv.r.console.history.length ] = cmd ;
}

sv.r.console.refreshHistory = function(){
  var his = document.getElementById("sciviews_rconsole_console_history_richlistbox");
  var cmd;
  var item ;
  var filter = new RegExp( document.getElementById("sciviews_rconsole_history_filter").value ) ;
  sv.tools.e4x2dom.clear(his) ;
  for( i=sv.r.console.history.length-1; i>=0; i--){
    cmd = sv.r.console.history[i] ;
    if( filter.test(cmd) ){
      item = <richlistitem class="historyListitem">
          <html:pre xmlns:html="http://www.w3.org/1999/xhtml" class="historyPre" >
            {cmd}
          </html:pre>
        </richlistitem> ;
      sv.tools.e4x2dom.appendTo(item,his) ;
    }
  }
  
}

sv.r.console.history = [];

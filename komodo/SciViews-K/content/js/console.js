// SciViews-K R functions
// Define functions to command R from Komodo Edit
// Copyright (c) 2008, Ph. Grosjean (phgrosjean@sciviews.org)

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

// Define the 'sv.r.console' namespace
if (typeof(sv.r.console) == 'undefined') sv.r.console = { };

sv.r.console.handleConsoleKeyPress = function(e){
  
  if( e.keyCode == 38 && e.ctrlKey ){ // [ctrl] + [up]: cycle history
    return(0);
  }
  
  if( e.keyCode == 40 && e.ctrlKey ){ // [ctrl] + [down]: cycle history
    return(0);    
  }
  
  if( e.keyCode == 13){ // [enter] pressed : submit to R
    sv.r.console.setCurrentCommand (sv.r.console.getConsoleContent() ) ;
    sv.r.console.parse() ;
    
    return(0); 
  }
  
  return(0);

}

sv.r.console.handleConsoleKeyUp = function(e){
  if( e.keyCode == 9){ // [tab]: explicit completion, 
    // FIXME: tabs are not caught here, and the <textbox> loses the focus
    sv.r.console.completeExplicit( );
  } else{
    sv.r.console.complete(); 
  }

}


sv.r.console.getConsoleContent = function(){
  return document.getElementById("sciviews_rconsole_console_input").value ;
}

sv.r.console.clearConsoleContent = function(){
  document.getElementById("sciviews_rconsole_console_input").value = "" ;
}

// function to run R code in the console
sv.r.console.run = function(cmd){
  sv.r.console.setCurrentCommand( cmd );
  sv.r.console.parse() ;
}

// parse code using Parse and run it if possible
sv.r.console.parse = function(){
  var cmd = "Parse('" + sv.r.console.getCurrentCommand().replace(/'/g, "\\'")  + "')" ;
  sv.r.evalCallback(cmd, sv.r.console.parse_cb); 
}

// callback called after an R command is parsed
sv.r.console.parse_cb = function(data){
  if(data.substring(0,10) == "expression" ){
    // command is ok, run it
    sv.r.evalCallback( sv.r.console.getCurrentCommand() , sv.r.console.run_cb);
  } 
}

// callback called after an R cmmand is run
sv.r.console.run_cb  = function(data){
  var output = document.getElementById("sciviews_rconsole_console_results") ;
  var cmd = sv.r.console.getCurrentCommand() ;
  
  var div =
      <html:pre class="consoleInput" xmlns:html="http://www.w3.org/1999/xhtml">{ "R> " + cmd }</html:pre> ;
  sv.tools.e4x2dom.appendTo(div,output) ;
  
  // FIXME: replace the dot with something invisible (space gets swallowed by the <pre>)
  //        or use something else than a <pre>
  data = data.replace(/^ /, ".") ;
  var div =
      <html:pre class="consoleOutput" xmlns:html="http://www.w3.org/1999/xhtml">{data}</html:pre> ;
  sv.tools.e4x2dom.appendTo(div,output) ;
  
  // add the current command to the history and refresh the history
  sv.r.console.addCommandToHistory(cmd);
  sv.r.console.refreshHistory();
  
  // reset the command
  sv.r.console.setConsoleContent( "" ) ;
  // sv.robjects.refreshPackage( ".GlobalEnv" ) ;
}

// TODO: use something else for the history, the R history, a file, mozStorage, ... ?
// TODO: make the history persistant
sv.r.console.history = [];
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

// set the content of the console
sv.r.console.setConsoleContent = function(cmd){
  document.getElementById( "sciviews_rconsole_console_input" ).value = "" ;
}

sv.r.console.getCompletionTypes = function(){
  var out = "" ;
  var types = [ "arguments", "packages", "functions" ] ;
  for( var i=0; i<types.length; i++){
    if( sv.prefs.getString( "sciviews.console.completion.setting." + types[i] ) == "true"){
      out += types[i] + "," ;
    }
  }
  return(out);
}

// completion
sv.r.console.complete = function(){
  sv.r.console.clearCompletionTab();
  sv.r.console._completionCounter++ ;
  var types = sv.r.console.getCompletionTypes() ;
  if( types != ""){
    cmd = "CompletePlus('" + sv.r.console.getConsoleContent().replace(/'/g, "\\'")  + "' , simplify = TRUE, types= '"+ types +"')" ;
    sv.r.evalCallback(cmd, sv.r.console.complete_cb, sv.r.console._completionCounter );
  }
}
// completion asked by the user
sv.r.console.completeExplicit = function(){
  // cmd = "cat( Complete('" + sv.r.console.getConsoleContent().replace(/'/g, "\\'")  + "') )" ;
  // sv.r.evalCallback(cmd, sv.r.console.completeExplicit_cb); 
}

sv.r.console.complete_cb = function(data, counter){
  if( counter == sv.r.console._completionCounter && data != ""){
    var completions = data.split("\n") ;
    sv.r.console.updateCompletionTab( completions ) ;
  }
}

sv.r.console.completeExplicit_cb = function(data){
  var completions = data.split("\t") ;
  if( completions.length == 1 ){
    // sv.r.console.setConsoleContent( sv.r.console.getConsoleContent( ) + completions[0] ) ;
  } else{
    // sv.r.console.updateCompletion(completions);
  }
}

sv.r.console.clearCompletionTab = function(){
  var compTree = document.getElementById( "sciviews_rconsole_completion_tree_main" ) ;
  sv.tools.e4x2dom.clear(compTree);
}

sv.r.console.updateCompletionTab = function( completions ) {
  
  var cmd = sv.r.console.getConsoleContent() ;
  var histCompletions = [] ;
  // TODO: consider using some sort of grep for this instead
  try{
    var cmdRx = new RegExp( sv.tools.strings.toRegex(cmd) ) ;
    var currentCmd ;
    for( var i=sv.r.console.history.length-1; i>=0; i--){
      currentCmd = sv.r.console.history[i] ;
      if( cmdRx.test(currentCmd) ){
        histCompletions[ histCompletions.length ] = [ currentCmd, "", "" ] ;
      }
    }
  } catch( e ){
    // problem when creating the RegExp
    alert( "problem when creating the regex from the command:\n" + cmd + "\n\n" + e ) ;
  }
  
  // TODO: use other objects for this
  var argCompletions = [] ;
  var argRx = new RegExp( "=" ) ;
  
  var packCompletions = [] ;
  var packRx = new RegExp( "::" );
  
  var otherCompletions = [] ;
  
  if( completions.length > 0){
    var tab, comp;
    for(var i=0; i<completions.length; i++){
      if(completions[i] != ""){
        tab = completions[i].split(",");
        comp = tab[0];
        if( argRx.test(comp) ){
          argCompletions[ argCompletions.length] = tab ;
        } else if( packRx.test(comp) ){
          packCompletions[ packCompletions.length] = tab ;
        } else {
          otherCompletions[ otherCompletions.length] = tab ;
        }
      }
    }
  }
  
  // TODO : find a way to describe each completion
  //        - description of function from help page
  //        - description of arguments
  //        - description of package : use packageDescription
  var makeTree = function( tab, name, root){
    if(sv.prefs.getString( "sciviews.console.completion.setting.arguments" ) == "true" && tab.length > 0 ){
      var newItem = <treeitem container="true" open="true">
                        <treerow>
                          <treecell label={name} />
                          <treecell label="" />
                          <treecell label="" />
                        </treerow>
                        <treechildren />
                      </treeitem> ;
      newItem.treechildren.treeitem = new XMLList() ;                
      for( var i=0; i<tab.length; i++){
        var item = tab[i] ;
        newItem.treechildren.treeitem +=
          <treeitem>
            <treerow>
              <treecell label={item[0]} />
              <treecell label={item[1]} />
              <treecell label={item[2]} />
            </treerow>
          </treeitem>
      }
      sv.tools.e4x2dom.appendTo(newItem, root) ;
    }
  }
  var compTree = document.getElementById( "sciviews_rconsole_completion_tree_main" ) ;
  
  // TODO: move the if to the makeTree function
  
  makeTree(argCompletions  ,  "arguments", compTree ) ;
  makeTree(packCompletions ,  "packages", compTree ) ;
  makeTree(otherCompletions,  "functions", compTree ) ;
  makeTree(histCompletions ,  "history", compTree ) ;
  
}


sv.r.console.updateCompletionChoiceSetting = function(event, type){
  var checked = event.target.checked;
  if( checked ){
    checked = "false" ;
  } else{
    checked = "true" ;
  }
  sv.prefs.setString( "sciviews.console.completion.setting." + type, checked  ) ; 
}


sv.r.console.init = function(){
  var types = ["arguments", "functions", "packages", "history"] ;
  var defaults = ["true" , "true", "true", "false" ] ;
  var type;
  var checked;
  for( var i=0; i<types.length; i++){
    type = types[i] ;
    //if( sv.prefs.getString( "sciviews.console.completion.setting." + type ) == undefined){
      sv.prefs.setString( "sciviews.console.completion.setting." + type, defaults[i] ) ; 
    //}
    document.getElementById("sciviews_rconsole_completion_cb_" + type ).checked =
      sv.prefs.getString( "sciviews.console.completion.setting." + type ) == "true"  ;
  }
}


// accessors for the _cmd object
sv.r.console._cmd = "" ;
sv.r.console.getCurrentCommand = function(){
  return( sv.r.console._cmd ) ;
}
sv.r.console.setCurrentCommand = function( cmd ){
  sv.r.console._cmd = cmd ;
}

sv.r.console._completionCounter = 0 ;

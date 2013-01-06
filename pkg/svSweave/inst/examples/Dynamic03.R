#! /usr/bin/Rscript -e 'svSweave::RdocConvert()'
svSweave::RdocHeader("Dynamic R document - Reactivity", toc = "none")
!"
<<server, eval = FALSE, echo = FALSE>>="
## Define server logic required to summarize and view the selected dataset
dynamicServer({
	## By declaring databaseInput as a dynamic function we ensure that:
	##
	##  1) It is only called when the inputs it depends on changes
	##  2) The computation and result are shared by all the callers (it 
	##     only executes a single time)
	##  3) When the inputs change and the function is re-executed, the
	##     new result is compared to the previous result; if the two are
	##     identical, then the callers are not notified
	##
	datasetInput <- dynamic({
		switch(input$dataset,
			"rock" = rock,
			"pressure" = pressure,
			"cars" = cars)
	})
  
	## The output$caption is computed based on a dynamic function that
	## returns input$caption. When the user changes the "caption" field:
	##
	##  1) This function is automatically called to recompute the output 
	##  2) The new caption is pushed back to the browser for re-display
	## 
	## Note that because the data-oriented reactive functions below don't 
	## depend on input$caption, those functions are NOT called when 
	## input$caption changes.
	output$caption <- dynamicText({
		input$caption
	})
  
	## The output$summary depends on the datasetInput dynamic function, 
	## so will be re-executed whenever datasetInput is re-executed 
	## (i.e. whenever the input$dataset changes)
	output$summary <- dynamicPrint({
		dataset <- datasetInput()
		summary(dataset)
	})
  
	## The output$view depends on both the databaseInput dynamic function
	## and input$obs, so will be re-executed whenever input$dataset or 
	## input$obs is changed. 
	output$view <- dynamicTable({
		head(datasetInput(), n = input$obs)
	})
})
!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	uiInput(
		## A text input
		wiText("caption", "Caption:", "Data Summary"),
	
		br(),
		
		## A selection box and numeric input box
		wiSelect("dataset", "Choose a dataset:", 
			choices = c("rock", "pressure", "cars")),
		
		br(),
		
		## A numeric input box
		wiNumeric("obs", "Number of observations to view:", 10)			 
	)
    
	uiDiv(
		## Show the caption, a summary of the dataset and an HTML table with
		## the requested number of observations
		h3(woText("caption")),
		woVerbatim("summary"),
		woTable("view")
	)
})
## What to display in static mode
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!"
NOTE: //This is a reimplementation of **`03_reactivity'** shiny example as a **SciViews R script**.//
<<>>="

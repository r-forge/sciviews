#! /usr/bin/Rscript -e 'svSweave::RdocConvert()'
svSweave::RdocHeader("Dynamic R document - More Widgets", toc = "none")
!"
<<server, eval = FALSE, echo = FALSE>>="
require(datasets)

## Define server logic required to summarize and view the selected dataset
dynamicServer({
  
	## Return the requested dataset
	datasetInput <- dynamic({
		switch(input$dataset,
			"rock" = rock,
			"pressure" = pressure,
			"cars" = cars)
	})
  
	## Generate a summary of the dataset
	output$summary <- dynamicPrint({
		dataset <- datasetInput()
		summary(dataset)
	})
  
	## Show the first "n" observations
	output$view <- dynamicTable({
		head(datasetInput(), n = input$obs)
	})
})
!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	uiInput(
		## Sidebar with controls to select a dataset and specify the number
		## of observations to view. The helpText function is also used to 
		## include clarifying text. Most notably, the inclusion of a 
		## submitButton defers the rendering of output until the user 
		## explicitly clicks the button (rather than doing it immediately
		## when inputs change). This is useful if the computations required
		## to render output are inordinately time-consuming.
		wiSelect("dataset", "Choose a dataset:", 
		    choices = c("rock", "pressure", "cars")),
		br(),
		wiNumeric("obs",
			"Number of observations to view:", 10),
		br(),
		wiLabel(
			"Note: while the data view will show only the specified",
		    "number of observations, the summary will still be based",
		    "on the full dataset."),
		br(),
		wiSubmitButton("Update View")
	)
	
	## Show a summary of the dataset and an HTML table with the requested
	## number of observations. Note the use of the h4 function to provide
	## an additional header above each output section.	catHtml(tabsetPanel(
	uiDiv(
		h4("Summary"),
		woVerbatim("summary"),
    
		h4("Observations"),
		woTable("view")
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!"
NOTE: //This is a reimplementation of **`07_widgets'** shiny example as a **SciViews R script**//
<<>>="

#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - Shiny Text")
!!"
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
!!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	uiInput(
		## A selection box
		wiSelect("dataset", "Choose a dataset:",
			choices = c("rock", "pressure", "cars")),
		
		## Goto next line
		br(),
		
		## A numeric input box
		wiNumeric("obs", "Number of observations to view:", 10)
	)
  
	uiDiv(
		## Show a summary of the dataset and an HTML table with the requested
		## number of observations
		woVerbatim("summary"),
		woTable("view")
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!!"
NOTE: //This is a reimplementation of **`02_text'** shiny example as a **SciViews R script**.//
<<>>="

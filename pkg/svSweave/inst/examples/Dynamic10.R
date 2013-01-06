#! /usr/bin/Rscript -e 'svSweave::RdocConvert()'
svSweave::RdocHeader("Dynamic R document - Downloading Data")
!"
<<server, eval = FALSE, echo = FALSE>>="
dynamicServer({
	datasetInput <- dynamic({
		switch(input$dataset,
			"rock" = rock,
			"pressure" = pressure,
			"cars" = cars)
	})
  
	output$table <- dynamicTable({
		datasetInput()
	})
  
	output$downloadData <- dynamicDownload(
		filename = function () paste0(input$dataset, ".csv"),
		content = function (file) write.csv(datasetInput(), file)
	)
})
!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	uiInput(
		wiSelect("dataset", "Choose a dataset:", 
            choices = c("rock", "pressure", "cars")),
		
		wiDownloadButton("downloadData", "Download")
	)
  
	uiDiv(
		woTable("table")
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!"
NOTE: //This is a reimplementation of **`10_download'** shiny example as a **SciViews R script**.//
<<>>="

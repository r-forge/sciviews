#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - CSV Viewer")
!!"
<<server, eval = FALSE, echo = FALSE>>="
dynamicServer({
	output$contents <- dynamicTable({
		## input$file1 will be NULL initially. After the user selects and uploads a 
		## file, it will be a data frame with 'name', 'size', 'type', and 'data' 
		## columns. The 'data' column will contain the local filenames where the data
		## can be found.

		inFile <- input$file1

		if (is.null(inFile))
			return(NULL)
    
		## There is a bug: \t is transformed into a series of spaces
		sep <- input$sep
		if (nchar(sep) > 1) sep <- "\t"
		read.csv(inFile$data, header = input$header, sep = sep,
			quote = input$quote)
	})
})
!!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	uiInput(
		## A file selector
		wiFile("file1", "Choose CSV File",
            accept = c("text/csv", "text/comma-separated-values,text/plain")),
    
		## Horizontal line
		tags$hr(),
    
		wiCheckbox("header", "Header", TRUE),
		
		## Goto line
		br(),
		
		## Radio buttons input
		wiRadioButtons("sep", "Separator",
            c(Comma = ",", Semicolon = ";", Tab = "\t"), "Comma"),
		
		## Goto line
		br(),
		
		wiRadioButtons("quote", "Quote",
            c(None = "", "Double Quote" = '"', "Single Quote" = "'"),
            "Double Quote")
	)
  
	uiDiv(
		woTable("contents")
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!!"
NOTE: //This is a reimplementation of **`09_upload'** shiny example as a **SciViews R script**.//
<<>>="

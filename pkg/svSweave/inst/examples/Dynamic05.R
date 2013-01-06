#! /usr/bin/Rscript -e 'svSweave::RdocConvert()'
svSweave::RdocHeader("Dynamic R document - Sliders", toc = "none")
!"
<<server, eval = FALSE, echo = FALSE>>="
## Define server logic for slider examples
dynamicServer({
  
	## Dynamic function to compose a data frame containing all of the values
	sliderValues <- dynamic({
		## Compose data frame
		data.frame(
			Name = c("Integer", "Decimal", "Range", "Custom Format", "Animation"),
			Value = as.character(c(input$integer, input$decimal,
                paste(input$range, collapse=' '), input$format, input$animation)), 
		stringsAsFactors = FALSE)
	}) 
  
	## Show the values using an HTML table
	output$values <- dynamicTable({
		sliderValues()
	})
})
!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	## Sliders that demonstrate various available options
	uiInput(
		## Simple integer interval
		sliderInput("integer", "Integer:",
			min = 0, max = 1000, value = 500),
    
		## Decimal interval with step value
		sliderInput("decimal", "Decimal:",
			min = 0, max = 1, value = 0.5, step= 0.1),
   
		## Specification of range within an interval
		sliderInput("range", "Range:",
			min = 1, max = 1000, value = c(200,500)),
    
		## Provide a custom currency format for value display, with basic animation
		sliderInput("format", "Custom Format:",
			min = 0, max = 10000, value = 0, step = 2500,
			format = "$#,##0", locale = "us", animate = TRUE),
    
		## Animation with custom interval (in ms) to control speed, plus looping
		sliderInput("animation",
			"Looping Animation (not in SciViews R document):", 1, 2000, 1,
			step = 10, animate = animationOptions(interval = 300, loop = TRUE))
	)
	
	## Show a table summarizing the values entered 
    uiDiv(woTable("values"))
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!"
NOTE: //This is a reimplementation of **`05_sliders'** shiny example as a **SciViews R script**.//
<<>>="

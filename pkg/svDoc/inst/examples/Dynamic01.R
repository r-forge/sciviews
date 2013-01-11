#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - Hello Shiny!")
!!"
<<server, eval = FALSE, echo = FALSE>>="
## The code to generate our dynamic elements on the page
dynamicServer({
	## Function that generates a plot of the distribution. The function
	## is wrapped in a call to dynamicPlot() to indicate that:
	##
	##  1) It is "dynamic" and therefore should be automatically 
	##     re-executed when inputs change
	##  2) Its output type is a plot
	##
	output$distPlot <- dynamicPlot({
        ## Generate an rnorm distribution and plot it
		dist <- rnorm(input$obs)
		hist(dist, col = "red") #"cornsilk")
	})  
})
!!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	## A simple slider
	uiInput(wiSlider("obs", "Number of observations:",
		min = 0, max = 1000, value = 500))
  
	## Show a plot of the generated distribution
	uiP(woPlot("distPlot"))
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!!"
NOTE: //This is a reimplementation of **`01_hello'** shiny example as a **SciViews R script**.//
<<>>="

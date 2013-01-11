#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - Miles Per Gallon")
!!"
<<server, eval = FALSE, echo = FALSE>>="
require(datasets)

## We tweak the "am" field to have nicer factor labels. Since this doesn't
## rely on any user inputs we can do this once at startup and then use the
## value throughout the lifetime of the application
mpgData <- mtcars
mpgData$am <- factor(mpgData$am, labels = c("Automatic", "Manual"))

## Define server logic required to plot various variables against mpg
dynamicServer({
  
	## Compute the forumla text in a dynamic function since it is 
	## shared by the output$caption and output$mpgPlot functions
	formulaText <- dynamic({
		paste("mpg ~", input$variable)
	})
   
	## Return the formula text for printing as a caption
	output$caption <- dynamicText({
		formulaText()
	})
  
	## Generate a plot of the requested variable against mpg and only 
	## include outliers if requested
	output$mpgPlot <- dynamicPlot({
		boxplot(as.formula(formulaText()), data = mpgData,
            outline = input$outliers, col = "cornsilk")
	})
})
!!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	## A text input and a checkbox
	uiInput(
		wiSelect("variable", "Variable:",
			c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")),

		wiCheckbox("outliers", "Show outliers", FALSE)
	)
	
	uiDiv(
		## Show the caption and plot of the requested variable against mpg
		h3(woText("caption")), 
		woPlot("mpgPlot")
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!!"
NOTE: //This is a reimplementation of **`04_mpg'** shiny example as a **SciViews R script**.//
<<>>="

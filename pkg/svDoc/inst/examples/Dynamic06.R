#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - Tabsets")
!!"
<<server, eval = FALSE, echo = FALSE>>="
## Define server logic for random distribution application
dynamicServer({
  
	## Dynamic function to generate the requested distribution. This is 
	## called whenever the inputs change. The output functions defined 
	## below then all use the value computed from this function
	data <- dynamic({  
		dist <- switch(input$dist, norm = rnorm, unif = runif,
            lnorm = rlnorm, exp = rexp, rnorm)
    
		dist(input$n)
	})
  
	## Generate a plot of the data. Also uses the inputs to build the 
	## plot label. Note that the dependencies on both the inputs and
	## the data reactive function are both tracked, and all functions 
	## are called in the sequence implied by the dependency graph
	output$plot <- dynamicPlot({
		dist <- input$dist
		n <- input$n
		hist(data(), main = paste("r", dist, "(", n, ")", sep = ""),
			col = "cornsilk")
	})
  
	## Generate a summary of the data
	output$summary <- dynamicPrint({
		summary(data())
	})
  
	## Generate an HTML table view of the data
	output$table <- dynamicTable({
		data.frame(x = data())
	})  
})
!!"
<<ui, echo = FALSE, results = ascii>>="
## What to display in dynamic mode?
asciiDynamic({
	## Sidebar with controls to select the random distribution type
	## and number of observations to generate. Note the use of the br()
	## element to introduce extra vertical spacing
	uiInput(
		wiRadioButtons("dist", "Distribution type:",
			c("Normal" = "norm", "Uniform" = "unif",
			"Log-normal" = "lnorm", "Exponential" = "exp")),
		br(),
		wiSlider("n", "Number of observations:",
			value = 500, min = 1, max = 1000)
	)
	
	## # Show a tabset that includes a plot, summary, and table view
	## of the generated distribution
	uiTabsetPanel(
		wiTabPanel("Plot", woPlot("plot")), 
		wiTabPanel("Summary", woVerbatim("summary")), 
		wiTabPanel("Table", woTable("table"))
	)
})
## What to display in static mode?
asciiStatic(uiP(strong(
	"This application works only in dynamic mode through the shiny server!")))
!!"
NOTE: //This is a reimplementation of **`06_tabsets'** shiny example as a **SciViews R script**//
<<>>="

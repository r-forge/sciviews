#! /usr/bin/Rscript -e svDoc::render...
svDoc::header("Dynamic R document - HTML UI")
!!"
<<server, eval = FALSE, echo = FALSE>>="
## Define server logic for random distribution application
dynamicServer({
	## Dynamic function to generate the requested distribution. This is 
	## called whenever the inputs change. The output functions defined 
	## below then all used the value computed from this function
	data <- dynamic({  
		dist <- switch(input$dist,
            norm = rnorm,
            unif = runif,
            lnorm = rlnorm,
			exp = rexp,
            rnorm)
    
		dist(input$n)
	})
  
	## Generate a plot of the data. Also uses the inputs to build the 
	## plot label. Note that the dependencies on both the inputs and
	## the data dynamic function are both tracked, and all functions 
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
## We can completely define the UI in HTML inside a passthrough block
## This allows us the see how input and output widgets are defined in the page
cat('
[pass]
++++++++++
	<p>
		<label>Distribution type:</label><br />
		<select name="dist">
			<option value="norm">Normal</option>
			<option value="unif">Uniform</option>
			<option value="lnorm">Log-normal</option>
			<option value="exp">Exponential</option>
		</select> 
	</p>
 
	<p>
		<label>Number of observations:</label><br /> 
		<input type="number" name="n" value="500" min="1" max="1000" />
	</p>
 
	<pre id="summary" class="shiny-text-output"></pre> 
  
	<div id="plot" class="shiny-plot-output" 
		style="width: 100%; height: 400px"></div> 
	
	<div id="table" class="shiny-html-output"></div>
+++++++++++
')
!!"
NOTE: //This is a reimplementation of **`08_html'** shiny example as a **SciViews R script**.//
<<>>="

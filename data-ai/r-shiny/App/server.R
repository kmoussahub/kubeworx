function(input, output, session) {
  output$table <- DT::renderDataTable({
    SQL <- paste(
		"SELECT order_id, customer_id, order_date, freight from orders ",
		"WHERE order_id BETWEEN ?oid_min AND ?oid_max AND freight BETWEEN ?min and ?max;",
		sep=" ")
    query <- sqlInterpolate(ANSI(), SQL,
               		oid_min = input$order_id_selector[1], oid_max = input$order_id_selector[2], 
			min = input$freight_selector[1], max = input$freight_selector[2])
    outp <- dbGetQuery(pool, query)
    ret <- DT::datatable(outp)
    return(ret)
  })

  output$distPlot <- renderPlot({
    SQL <- paste(
		"SELECT freight from orders ",
		"WHERE order_id BETWEEN ?oid_min and ?oid_max and freight BETWEEN ?min and ?max;",
		sep=" ")

    histQry <- sqlInterpolate(ANSI(), SQL,
               		oid_min = input$order_id_selector[1], oid_max = input$order_id_selector[2], 
			min = input$freight_selector[1], max = input$freight_selector[2])
    histOp <- dbGetQuery(pool, histQry)

    freight_cost <- histOp$freight
    bins <- seq(min(freight_cost), max(freight_cost), length.out = 11)
    hist(freight_cost, breaks = bins, col = 'darkgray', border = 'white')
  })
}
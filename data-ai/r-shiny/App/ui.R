fluidPage( 
    sidebarLayout( 
        sidebarPanel( 
            sliderInput("order_id_selector","Select Order ID", 
                min = order_id_maxmin$min, 
                max = order_id_maxmin$max, 
                value = c(order_id_maxmin$min, order_id_maxmin$max), step = 1), 
        sliderInput("freight_selector","Select Freight Ranges", 
                min = freight_maxmin$min, 
                max = freight_maxmin$max, 
                value = c(freight_maxmin$min, freight_maxmin$max), step = 1) 
        , plotOutput("distPlot", height=250) 

    ), mainPanel( 
        DT::dataTableOutput("table") 
    ) 
  ) 
)
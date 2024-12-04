### Moisture Content Predictor
### Michael J Burns
### 5/20/2021

# Load R packages
if(!require(shiny)) install.packages('shiny')
if(!require(shinythemes)) install.packages('shinythemes')
if(!require(tidyverse)) install.packages('tidyverse')
if(!require(prospectr)) install.packages('prospectr')
if(!require(kernlab)) install.packages('kernlab')
if(!require(pls)) install.packages('pls')
if(!require(caret)) install.packages('caret')
if(!require(stringr)) install.packages('stringr')
if(!require(rstudioapi)) install.packages('rstudioapi')
if(!require(vroom)) install.packages('vroom')
if(!require(tools)) install.packages('tools')

# Shiny options
options(shiny.maxRequestSize = 35 * 1024^2)
setwd(str_remove(rstudioapi::getSourceEditorContext()$path, 'app.R'))

# Define UI
ui <- fluidPage(theme = shinytheme('cosmo'),
                # Creating multiple pages for navigation
                navbarPage(
                    'CHIP-NMC: Corn Hybrid and Inbred Prediction of Nixtamalization Moisture Content',
                    # Page 1 - the actual tool
                    tabPanel('Prediction Tool',
                             # Sidebar panel for the main page - input data, model options, and download
                             sidebarPanel(
                                 tags$h3('Input Path:'),
                                 fileInput('spectra',
                                           'Spectra Data File:'),
                                 radioButtons('model',
                                              'Model Option:',
                                              choices = c('Inbred' = 'inbred',
                                                          'Hybrid' = 'hybrid',
                                                          'Custom' = 'custom'
                                                          ),
                                              selected = character(0)),
                                 conditionalPanel(condition = 'input.model == "custom"',
                                                  fileInput('custom_model',
                                                            'Custom Model:')),
                                 numericInput('min_value',
                                              'Output Minimum Value:', 
                                              value = 0,
                                              min = 0,
                                              max = 1,
                                              step = 0.001),
                                 numericInput('max_value',
                                              'Output Maximum Value:',
                                              value = 1,
                                              min = 0,
                                              max = 1,
                                              step = 0.001),
                                 checkboxInput('extremes',
                                               'Include Extrapolated Values?'),
                                 downloadButton('download')
                             ),
                             # Main body of the main page - display summary and statistics of predictions
                             mainPanel(
                                 h1(textOutput('summary_header')),
                                 h3(textOutput('spectra_header')),
                                 splitLayout(cellWidths = c("50%", "50%"), plotOutput("spectra_raw"), plotOutput("spectra_norm")),
                                 h3(textOutput('distribution_header')),
                                 plotOutput('distribution'),
                                 h3(textOutput('table_header')),
                                 tableOutput('summary_table'),
                             ) 
                             
                    ), 
                    # Page 2 - the instructions for use
                    tabPanel('Instructions', 
                             h2('How to Use the Nixtamalization Moisture Content Prediction Tool:'),
                             h3('Dataset Requirements:'),
                             h4('142 columns (column 1 = Sample_ID, columns 2-142 = spectral waveband absorbances from 950 to 1650 by 5).'),
                             h4('Either a .csv or .tsv file format.'),
                             h4('Less than 35Mb of data (~20,000 samples).'),
                             
                             h3('To Run the Moisture Content Prediction Application:'),
                             h4('Make sure you are in the "Prediction Tool" tab at the top of the screen.'),
                             h4('Click on the "Browse..." button to select the file you would like to upload.'),
                             h4('When a dataset has been uploaded, a plot of the spectra will appear momentarily. Please ensure this plot looks acceptable before continuing.'),
                             h4('Select the model for predictions based on the genetic background of your samples.'),
                             h4('If you select "custom" under model selction, an additional input option will appear for you to select your model (saved as a .rda file). Please note that if you select custom model, your dataset will need to be in normalized according the the training procedures of the custom model prior to upload.'),
                             h4('Information about the predictions will appear automatically after the spectra is uploaded and a model is selected.'),
                             h4('After the information in the primary panel of the page has appeared, click the "Download" button to write the file to your local computer.'),
                             h4('Note: The first time you open the application, it will take a few moments to start up.'),
                             
                             h3('Additional Options:'),
                             h4('Output boundary values are provided to restrict the file size that is output. These values are set to automatically export all samples that were predicted.'),
                             h4('Including extrapolated values is also an option (turned off by default), in case you want to assess germplasm regardless of how robust the prediction may be. Please note that by checking this box you will receive predictions that are outside the training bounds and will not be trustworthy.'),
                             
                             h3('On Screen Outputs:'),
                             h4('Section 1: Histogram of nixtamalization moisture content predcitions. This should look roughly normal. Data points within the vertical gray lines are interpolated, whereas data points outside the vertical lines are extrapolated and not necessarily accurate. Additionally, red vertical lines will appear when output boundary values are within the limits of the x-axis to illustrate the range of value you have selected. Please note that to protect the viewability of the histogram, quantiles of predictions were used, so not all data (particularly extreme values) will be depicted. These predictions are still accessible through proper use of the extrapolated values checkbox (checked), and the minimum and maximum value boundary boxes (in extreme cases, these values may need to be set beyond 0 and 1).'),
                             h4('Section 2: Summary of the predicted nixtamalization moisture contents of the given data. This includes the total number of samples, the number that are within the training bounds, the number of samples within the specified output range, the average predicted nixtamalization moisture content, and the standard deviation of predicted nixtamalization moisture content.'),
                             ),
                    # Page 3 - citation for the tool
                    tabPanel('Citation', 
                             h2('Citation'),
                             h4('Publication: CHIP-NMC: Corn Hybrid and Inbred Prediction of Nixtamalization Moisture Content'),
                             h4('Authors: Michael J. Burns, Sydney P. Berry, Molly Loftus, Amanda M. Gilbert, Candice N. Hirsch'),
                             h4('Journal: Cereal Chemistry'),
                             h4('Date: XX/XX/XXXX'),
                             h4('Volume: XX'),
                             h4('Issue: XX'),
                             h4('doi: XXXXXXXXXX')
                             ) 
                    
                ) 
)

# Define server function  
server <- function(input, output) {
  # Loading Requested Model - require model selection first
  prediction_model = reactive({
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    if(input$model != 'custom'){
      readRDS(paste0(input$model, '_model.rda'))
    } else{
      readRDS(input$custom_model$datapath)
    }
  })
  
  prediction_min = reactive({
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    min(prediction_model()$trainingData$.outcome)
  })
  
  prediction_max = reactive({
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    max(prediction_model()$trainingData$.outcome)
  })
  
  
  
  # Headers - only appear after spectra has been loaded
  output$summary_header <- renderText({
    req(input$spectra)
    'Summary Report'
  })
  output$spectra_header <- renderText({
    req(input$spectra)
    'Spectral Profile'
  })
  output$distribution_header <- renderText({
    req(input$spectra)
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    'Distribution of Predictions'
  })
  output$table_header <- renderText({
    req(input$spectra)
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    'Summary of Predictions'
  })
  
  # Loading Dataset from Upload Button
  dataset <- reactive({
      req(input$spectra)
      ext <- tools::file_ext(input$spectra$name)
      switch(ext,
             csv = vroom::vroom(input$spectra$datapath, delim = ','),
             tsv = vroom::vroom(input$spectra$datapath, delim = '\t'),
             validate('Invalid file; Please upload a .csv or .tsv file')
      )
  })
  
  # Plotting raw spectra
  output$spectra_raw <- renderPlot({
    req(input$spectra)
    dataset() %>%
      mutate(row = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)),
                  names_to = 'Waveband',
                  values_to = 'Absorbance') %>%
      mutate(Waveband = as.numeric(Waveband)) %>%
      ggplot(aes(x = Waveband, y = Absorbance, group = row))+
      geom_line(alpha = 0.5)+
      labs(title = 'Input Spectral Profile')+
      theme_classic()
  })
     
  # Normalizing Data
  normalized_data <- reactive({
          req(input$spectra)
          req(input$model)
          if(input$model == 'custom') req(input$custom_model)
          if(input$model == 'inbred'){
            dataset() %>%
              select(-c(as.character(seq(950,1650,5)))) %>%
              bind_cols(dataset() %>%
                          select(as.character(seq(950,1650,5))) %>%
                          mutate(row = row_number()) %>%
                          pivot_longer(cols = -row, names_to = 'Waveband', values_to = 'Absorbance') %>%
                          group_by(row) %>%
                          mutate(sum_lxl_abs = sum(abs(Absorbance)),
                                 Norm_Abs = Absorbance / sum_lxl_abs) %>%
                          select(-c(Absorbance, sum_lxl_abs)) %>%
                          ungroup() %>%
                          pivot_wider(id_cols = c(row),
                                      values_from = Norm_Abs,
                                      names_from = Waveband) %>%
                          unnest(cols = as.character(seq(950,1650,5))) %>%
                          select(-row) %>%
                          as_tibble())
          } else{ 
            if(input$model == 'hybrid'){
              dataset() %>%
                select(-as.character(seq(950,1650,5))) %>%
                bind_cols(as_tibble(detrend(dataset() %>%
                                              select(as.character(seq(950,1650,5))),
                                            wav = as.numeric(seq(950,1650,5)),
                                            p = 2)))
            } else{
                dataset()
              }
          }
  })
  
  # Plotting normalized data
  output$spectra_norm <- renderPlot({
    req(input$spectra)
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    normalized_data() %>%
      mutate(row = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)),
                   names_to = 'Waveband',
                   values_to = 'Absorbance') %>%
      mutate(Waveband = as.numeric(Waveband)) %>%
      ggplot(aes(x = Waveband, y = Absorbance, group = row))+
      geom_line(alpha = 0.5)+
      labs(title = 'Transformed Spectral Profile')+
      theme_classic()
  })
  
  # Generating Predictions
  model_predictions <- reactive({
      req(input$spectra)
      req(input$model)
      if(input$model == 'custom') req(input$custom_model)
      predict(prediction_model(), normalized_data())
  })
  
  prediction_data <- reactive({as_tibble(dataset()[,1]) %>%
           mutate(Predicted_Moisture_Content = model_predictions()) %>%
           mutate(Prediction_Quality = case_when(Predicted_Moisture_Content < prediction_min() | Predicted_Moisture_Content > prediction_max() ~ 'Low',
                                                 Predicted_Moisture_Content >= prediction_min() & Predicted_Moisture_Content <= prediction_max() ~ 'High'),
                  Within_Selection_Bounds = case_when(Predicted_Moisture_Content < input$min_value | Predicted_Moisture_Content > input$max_value ~ 'No',
                                                      Predicted_Moisture_Content >= input$min_value & Predicted_Moisture_Content <= input$max_value ~ 'Yes'))})
  
  
  # Distribution of Predictions Plot
  output$distribution <- renderPlot({
    req(input$spectra)
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    prediction_data() %>%
        ggplot(aes(x = Predicted_Moisture_Content))+
        geom_density(fill = 'gray50', color = 'gray50')+
        labs(x = 'Predicted Moisture Content',
             subtitle = 'Black Lines Show Training Set Boundaries\nRed Lines Show Selection Boundaries')+
        geom_vline(aes(xintercept = prediction_min()), color = 'black')+
        geom_vline(aes(xintercept = prediction_max()), color = 'black')+
        geom_vline(aes(xintercept = input$min_value), color = 'red')+
        geom_vline(aes(xintercept = input$max_value), color = 'red')+
        xlim(min(quantile(model_predictions(), 0.025), prediction_min()) - 0.01,
             max(quantile(model_predictions(), 0.975), prediction_max()) + 0.01)+
        theme_classic()+
        theme(text = element_text(size = 18))
  })
  
  # Summary of Predictions
  data_summary <- reactive({
    req(input$spectra)
    req(input$model)
    if(input$model == 'custom') req(input$custom_model)
    prediction_data() %>%
          summarise(`Number of Samples` = n(),
                    `Number Interpolated` = sum(Prediction_Quality == 'High'),
                    `Number within Specified Range` = sum(Within_Selection_Bounds == 'Yes'),
                    `Average Prediction` = mean(Predicted_Moisture_Content),
                    `Standard Deviation of Predictions` = sd(Predicted_Moisture_Content))
  })
  
  output$summary_table <- renderTable(data_summary())
  
  # Filter output data
  output_data = reactive({
    if(input$extremes){
      prediction_data() %>%
        filter(Within_Selection_Bounds == 'Yes') %>%
        select(-Within_Selection_Bounds, -Prediction_Quality)
    } else{
      prediction_data() %>%
          filter(Within_Selection_Bounds == 'Yes' & Prediction_Quality == 'High') %>%
        select(-Within_Selection_Bounds, -Prediction_Quality)
    }
  })
  
  
  # Downloading Output
  output$download <- downloadHandler(
    filename = function() {
      paste0(str_remove(string = input$spectra, pattern = '.csv'),'_', input$model, '_model_predictions.csv')
    },
    content = function(file) {
      write.csv(output_data(), file, row.names = F)
    }
  )

}

# Create Shiny object
shinyApp(ui = ui, server = server)

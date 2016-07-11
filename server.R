library(shiny)
library(mailR)
library(DBI)
library(shinyjs)
require(parallel)
require(jsonlite)

options(shiny.maxRequestSize = 1000*1024^2) #Determines allowed filesize from user input

shinyServer(function(input, output,session){
  
  # output$dlButton <- downloadHandler(
  #   filename = "downloadedFile",
  #   content = function(file){
  #     write.table(read.delim("message.txt", sep = ":"),file)
  #   }
  # )
 
  # Important! : creationPool should be hidden to avoid elements flashing before they are moved.
  #              But hidden elements are ignored by shiny, unless this option below is set.
  # Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
  output$creationPool <- renderUI({})
  outputOptions(output, "creationPool", suspendWhenHidden = FALSE)
  # End Important
  
  # Important! : This is the make-easy wrapper for adding new tabPanels.
  addTabToTabset <- function(Panels, tabsetName){
    titles <- lapply(Panels, function(Panel){return(Panel$attribs$title)})
    Panels <- lapply(Panels, function(Panel){Panel$attribs$title <- NULL; return(Panel)})
    
    output$creationPool <- renderUI({Panels})
    session$sendCustomMessage(type = "addTabToTabset", message = list(titles = titles, tabsetName = tabsetName))
  }
  # End Important 
  # Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
  
  observe({
    # Disable textarea if input WG selected
    toggleState("WG_input", input$id_or_wg != "WG")
    
    # Disable the Submit button if email, WG_file, TRANS_file, not inputted
    toggleState("submit", 
                !is.null(input$email) && input$email != "" && !is.null(input$WG_file) && !is.null(input$TRANS_file) && input$theta != "")
    
    # Disable theta if no filter selected
    toggleState("theta", !is.null(input$filtering))
    
  })
  
  
  #This button created the 'Job Status' Tab + job initiation logic
  observeEvent(input$submit, {
    noClicks <- input$submit
    
    # Validate that numericinput is integer, >=2
    validate(
      need(input$col_start >= 2, message = "Please enter a start column greater than or equal to 2.")
    )
    
    #Start user input assignments
    ##############################
    
    # if (input$pathway == 'Kegg') {
   
    workflow <- "KEGGWorkflow.R"
    # } else if (input$pathway == 'TF') {
    # workflow <- "TFWorkflow.R" 
    # } else {
    # workflow <- "WikiWorkflow.R" }
    
    #End user input assignments
    
    if (!is.null(input$WG_file) && !is.null(input$TRANS_file ) && noClicks==1){

      createJobStatusBar() #Internal code found below

      filtering <- paste(input$filtering, collapse="")
      script <- paste("Rscript", workflow, input$WG_file$datapath, input$TRANS_file$datapath, input$col_start, filtering, input$theta)

      #Spawn asyncronous R process for the workflow
      system(script, wait=FALSE)
    }
    
    if (noClicks > 1){}
    
  })
  
  #This button creates the 'Results' Tab
  observeEvent(input$jobReadyButton, {
    noClicks <- input$jobReadyButton
    
    if (noClicks > 1 ){}
    
    if (noClicks == 1){
      createResultsBar()#Internal code found below    
    }
  })

  #Start code for SendEmailButton (in Results tab)
  observeEvent(input$sendEmailButton, {
    table = read.delim("message.txt", sep = ":")

    topic = as.character(table$value[[1]])
    message = as.character(table$value[[2]])

    send.mail(from = "hassam303@gmail.com",
              to = list("hassam303@gmail.com"),
              subject = topic,
              body = message,
              smtp = list(host.name = "smtp.gmail.com",
                          port = 465,
                          user.name = "hassam303@gmail.com",
                          passwd = "Sammyandtom",
                          ssl = TRUE),
              authenticate = TRUE,
              debug = TRUE,
              send = TRUE)

    output$mailSent <- renderText("Sent!")
  })
  #End code for SendEmailButton (in Results tab)
  
  createJobStatusBar <- function(){
    
    newTabPanels <- list(
      tabPanel("Job Status", value = "Job",
               ###Start Job Status tab Layout###
               
               column(3),
               column(7, align = "center", 
                      
                      h3("Your Job Has Been Submitted!"),
                      h4("Your job has been submitted to the server for processing. Below is 
                         your Job ID which can be used to return to the page to retrieve your
                         results (once they are ready) up to seven days after they are processed"),
                      h3("Job ID: 000-000-000"),
                      
                      actionButton("jobReadyButton",
                                   "Go To Results")
               )
               ###End Job Status tab Layout###
      )
    )    
    addTabToTabset(newTabPanels, "navbar")   
    
  }
  
  createResultsBar <- function(){
    
    newTabPanels <- list(
      tabPanel("Results",
               ###Start Results Layout###
               
               h3("All kinds of cool results will be displayed here! Exciting"),
               downloadButton("download_priori", "Download prioritized data"),
               br(),
               textOutput("mailSent"), 
               actionButton("sendEmailButton", "Send Email")
               
               ###End Results Layout###
      )    
    )  
    addTabToTabset(newTabPanels, "navbar")  
  } 
})

# #Build user JSON file
# jsonData<- fromJSON("jobConfigBlank.txt")
# 
# jsonData$entrezIDS <- strsplit(input$WG_input,"\n")
# jsonData$jobID <- gsub("([.-])|[[:punct:]]|[ ]","",as.POSIXlt(Sys.time()))
# jsonData$enrichmentType <- input$pathway
# jsonData$thetaVal <- input$theta
# jsonData$filtering <- input$filtering
# jsonData$email<- input$email
# jsonData$startCol<- input$col_start
# jsonData$WG_file_path<- input$WG_file$datapath
# jsonData$TRANS_file_path<- input$TRANS_file$datapath
#   
#   
# write(toJSON(jsonData,
#              null = "null",
#              pretty = TRUE,
#              auto_unbox = TRUE), 
#       file = paste("users/","userData.txt",sep = ""))

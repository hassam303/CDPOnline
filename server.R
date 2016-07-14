library(shiny)
library(sendmailR)
library(DBI)
library(shinyjs)
require(parallel)
require(jsonlite)

options(shiny.maxRequestSize = 1000*1024^2) #Determines allowed filesize from user input

shinyServer(function(input, output,session){
  
  jsonData<- fromJSON("jobConfigBlank.txt")
  
  
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
    toggleState("Entrez_text", input$id_or_wg != "WG" && is.null(input$Entrez_file$datapath) )
    toggleState("Entrez_file", input$id_or_wg != "WG" && input$Entrez_text == "")
    
    # Disable WG_file if Entrez selected
    toggleState("WG_file", input$id_or_wg != "Entrez")
    
    # Disable the Submit button if email, WG_file or Entrez file or Entrez text, TRANS_file, not inputted
    toggleState("submit", checkGeneIDEntry() && input$email != "" && !is.null(input$TRANS_file$datapath) )
    
    # Disable theta if no filter selected
    toggleState("theta", !is.null(input$filtering))
    
  })
  
  #This button creates the 'Job Status' Tab + job initiation logic
  observeEvent(input$submit, {
    noClicks <- input$submit
    
    # # Validate that numericinput is integer, >=2
    # validate(
    #   need(input$col_start >= 2, message = "Please enter a start column greater than or equal to 2.")
    # )
    
    #Build user JSON file
    jsonData$jobID<- gsub("([.-])|[[:punct:]]|[ ]","",as.POSIXlt(Sys.time()))
    jsonData$email<- input$email
    jsonData$enrichmentType <- input$pathway
    jsonData$thetaVal<- input$theta
    jsonData$filtering<- paste(input$filtering, collapse="")
    jsonData$startCol<- input$col_start
    
    if (input$Entrez_text != "" ){
      jsonData$entrezIDs <- strsplit(input$Entrez_text,"\n")
    }
    if (!is.null(input$Entrez_file$datapath) ){
      jsonData$Entrez_file_path<- input$Entrez_file$datapath
    }
    if (!is.null(input$WG_file$datapath) ){
      jsonData$WG_file_path<- input$WG_file$datapath
    }
    if (!is.null(input$TRANS_file$datapath) ){
      jsonData$TRANS_file_path<- input$TRANS_file$datapath
      
    }

    #Create a folder to store temp job files 
    newUserFolderPath <- paste("users/", jsonData$jobID, sep = "")
    dir.create(newUserFolderPath)
    
    #Save JSON file to temp job folder 
    write(toJSON(jsonData, 
                 na = "null",
                 null = "null",
                 pretty = TRUE,
                 auto_unbox = TRUE),
          file = paste(newUserFolderPath,"/userData.txt",sep = ""))

    #Create new JobStatusTab
    createJobStatusBar()
    
    #Determine workflow to be and pass argument to JobStatus page 
    workflowScript <- paste(input$pathway,"Workflow.R",sep="")
    
    #Spawn asyncronous R process for the workflow
    # system2("Rscript", 
    #         args = c(workflowScript,paste("users/", jsonData$jobID,"/userData.txt",sep ="")),
    #         wait = FALSE)
    # 
    
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
    
    
    sendmail(from = "hassam303@gmail.com", 
             to = c("hassamsolano@gmail.com"), 
             subject = topic, 
             msg = message,
             control=list(smtpServer="relay.cougars.int"))
    
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
                      h3(paste("Job ID:", jsonData$jobID)),
                      
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

  checkGeneIDEntry <- function(){
    
    entrez <- FALSE
    webG <- FALSE
    
    if (input$id_or_wg == "Entrez" && trimws(input$Entrez_text, which = "both") != ""){ 
      entrez <- TRUE
    }
    
    else{
      if ( !is.null(input$WG_file$datapath) ) {  
        webG <- TRUE  
      }
    }
    
    return(entrez || webG)
  }
  
  
  
  })
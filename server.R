library(shiny)
library(shinyjs)
library(metabologram)
require(jsonlite)
source("ui.R")

options(shiny.maxRequestSize = 1000*1024^2) #Determines allowed filesize from user input

shinyServer(function(input, output,session){
  jsonData<- fromJSON("jobConfigBlank.txt")
  
  print(system("whoami"))

  output$download_priori <- downloadHandler(
    filename = function(){
      paste("prioritized_Data_", jsonData$jobID,".tar.gz",
            sep = "")
    },
    content = function(file){
      tar(tarfile = file,
          files = file.path("users",jsonData$jobID,"prioritizedData"),
          compression = "gzip")
    }
  )
  
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
    jsonData$jobID<<- gsub("([.-])|[[:punct:]]|[ ]","",as.POSIXlt(Sys.time()))
    jsonData$email<<- input$email
    jsonData$enrichmentType <<- input$pathway
    jsonData$thetaVal<<- input$theta
    jsonData$filtering<<- paste(input$filtering, collapse="")
    jsonData$startCol<<- input$col_start
    jsonData$cutoff<<- input$cutoff
    jsonData$minGenes<<- input$min
    
    if (input$Entrez_text != "" ){
      jsonData$entrezIDs <<- strsplit(input$Entrez_text,"\n")
    }
    if (!is.null(input$Entrez_file$datapath) ){
      jsonData$Entrez_file_path<<- input$Entrez_file$datapath
    }
    if (!is.null(input$WG_file$datapath) ){
      jsonData$WG_file_path<<- input$WG_file$datapath
    }
    if (!is.null(input$TRANS_file$datapath) ){
      jsonData$TRANS_file_path<<- input$TRANS_file$datapath
      
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
    addTabToTabset(createJobStatusBar(jsonData$jobID), "navbar")
    
    #Determine workflow to be and pass argument to JobStatus page 
    workflowScript <- paste(input$pathway,"Workflow.R",sep="")
    
    #Spawn asyncronous R process for the workflow
    system2("Rscript",
            args = c(workflowScript,paste("users/", jsonData$jobID,"/userData.txt",sep ="")),
            wait = FALSE)

    
    if (noClicks > 1){}
    
  })
  
  #This button triggers the creation 'Results' Tab
  observeEvent(input$jobReadyButton, {
    noClicks <- input$jobReadyButton
    
    genes <- read.csv("metabologram_sample_data/genes.csv")
    proteins <- read.csv("metabologram_sample_data/proteins.csv")
    
    if (noClicks > 1 ){}
    
    if (noClicks == 1){
      addTabToTabset(createResultsBar(),"navbar")   

      genes <- read.csv("metabologram_sample_data/genes.csv")
      proteins <- read.csv("metabologram_sample_data/proteins.csv")

      sampleMetabologramData <- list(
        list(
          name="Genes",
          colour="#FF6E6E",
          children=list(
            list(name="HSPH1", colour="#0000FF"),
            list(name="DNAJC3", colour="#F3F3FF"),
            list(name="UGGT2", colour="#FFF3F3"),
            list(name="HSPA1A", colour="#FFDDDD"),
            list(name="MAN1A1", colour="#FF8585"),
            list(name="RAD23A", colour="#FF1616"),
            list(name="PDIA4", colour="#FF8585"),
            list(name="CAPN2", colour="#FF1616"),
            list(name="ERO1LB", colour="#DDDDFF"),
            list(name="EDEM1", colour="#FF1616"),
            list(name="UBE2J1", colour="#FF8585"),
            list(name="BAX", colour="#FF8585"),
            list(name="HSP90AA1", colour="#8585FF"),
            list(name="STT3B", colour="#FF8585"),
            list(name="LMAN1", colour="#8585FF"),
            list(name="PDIA6", colour="#FF1616"),
            list(name="BAK1", colour="#FF8585"),
            list(name="SEC23A", colour="#DDDDFF"),
            list(name="DERL3", colour="#FF8585"),
            list(name="UBQLN4", colour="#FF8585"),
            list(name="HSP90AB1", colour="#FF1616"),
            list(name="ERO1L", colour="#FF8585"),
            list(name="HERPUD1", colour="#FF1616"),
            list(name="SAR1B", colour="#FF8585"),
            list(name="DERL1", colour="#DDDDFF"),
            list(name="TUSC3", colour="#DDDDFF"),
            list(name="DNAJC10", colour="#FF8585"),
            list(name="PPP1R15A", colour="#DDDDFF"),
            list(name="XBP1", colour="#FF8585"),
            list(name="EIF2S1", colour="#FF8585"),
            list(name="MAP3K5", colour="#DDDDFF"),
            list(name="HSPA4L", colour="#FF5858")
          )
        ),
        list(
          name="Proteins",
          colour="#FFDDDD",
          children=list(
            list(name="RPN1", colour="#B1B1FF"),
            list(name="DDOST", colour="#DDDDFF"),
            list(name="SAR1A", colour="#F3F3FF"),
            list(name="P4HB", colour="#FF6E6E"),
            list(name="RRBP1", colour="#8585FF"),
            list(name="ERO1L", colour="#FF1616"),
            list(name="RAD23B", colour="#FF6E6E"),
            list(name="BAX", colour="#FF0000"),
            list(name="DNAJB1", colour="#DDDDFF"),
            list(name="LMAN1", colour="#F3F3FF"),
            list(name="CANX", colour="#FF0000"),
            list(name="GANAB", colour="#FFF3F3"),
            list(name="VCP", colour="#B1B1FF")
          )
        )
      )
      
      sampleMetabologramBreaks <- c(
        -3.00, -2.75, -2.50, -2.25, -2.00, -1.75, -1.50, -1.25, -1.00, 
        -0.75, -0.50, -0.25, 0.00,  0.25,  0.50,  0.75,  1.00,  
        1.25,  1.50,  1.75,  2.00,  2.25,  2.50,  2.75, 3.00
      )
      
      sampleMetabologramColors <- c(
        "#0000FF", "#1616FF", "#2C2CFF", "#4242FF", "#5858FF", "#6E6EFF", "#8585FF",
        "#9B9BFF", "#B1B1FF", "#C7C7FF", "#DDDDFF", "#F3F3FF", "#FFF3F3", "#FFDDDD",
        "#FFC7C7", "#FFB1B1", "#FF9B9B", "#FF8585", "#FF6E6E", "#FF5858", "#FF4242",
        "#FF2C2C", "#FF1616", "#FF0000"
      )
      
      output$metabologram <- renderMetabologram({
        
        metabologram(
          sampleMetabologramData, 
          width=600, 
          height=500, 
          main="Sample Data",
          showLegend=TRUE,
          fontSize=12,
          legendBreaks=sampleMetabologramBreaks,
          legendColors=sampleMetabologramColors,
          legendText="Legend Title"
        )
        
      })
      
      output$test_path <- renderText({
        print(jsonData$enrichmentType)
      })
      
      output$test_jobID <- renderText({
        print(jsonData$jobID)
      })
  
      output$test_filter <- renderText({
        switch (jsonData$filtering,
          "m" = print("Mean Abundance"),
          "v" = print("Variance"),
          "mv" = print("Mean Abundance & Variance")
        )
        })
      
      output$test_cutoff <- renderText({
        print(jsonData$thetaVal)
      })
      
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
  
  #Start code for JobID Button 
  observeEvent(input$submit_jobid,{
    if(input$jobid_textbox == "" || is.null(input$jobid_textbox) ){
      return()
    }
    else{
      dir <- gsub("users/",replacement ="", x= list.dirs(path="users"))
      #Check for folder exsistence 
      if (length(grep(input$jobid_textbox, x = dir)) > 0){
        wd <- paste("users/",input$jobid_textbox,sep ="")
        
        #Load user data
        jsonData<<- fromJSON(paste(wd,"/userData.txt",sep =""))
        addTabToTabset(createJobStatusBar(jsonData$jobID), "navbar")
      }
      else {
        return()
      }
    }
  })
  #End code for JobID Button
  
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
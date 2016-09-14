#!/usr/bin/env Rscript
require(ComplementaryDomainPrioritization)
require(jsonlite)
require(sendmailR)

KEGGWorkflow <- function(){
  
  success <- FALSE #Used to determine if proper files were created
  
  # Get WebGestalt Data if needed 
  if (length(userData$WG_file_path) == 0){
    system2("irb",
            args = c("CDP_WebGestalt_Watir_Script.rb",userData$jobID),
            wait = TRUE)
    userData <- fromJSON(args[1])
  }
  
  kegg.pathways = load.WebGestalt(userData$WG_file_path, 'Kegg')
  print(kegg.pathways)
  KEGGgene.ids = get.genes.kegg(kegg.pathways)
  
  startCol = userData$startCol
  theta = userData$theta
  filtering = userData$filtering
  
  transc.rna = load.gene.data(userData$TRANS_file_path, startCol) 
  KEGGprioritized.data = list.filter(transc.rna$transposed.data,KEGGgene.ids)
  
  resultFolder  = paste("/srv/shiny-server/CDPOnline/users/", userData$jobID,"/prioritizedData",sep ="")
  dir.create(resultFolder)
  
  resultFile = paste(resultFolder,"/prioritizedData.csv", sep = "")
  
  write.table(KEGGprioritized.data,
              resultFile,
              sep = ",",
              append = FALSE)
  
  fixResultsFile(resultFile)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {
   if(length(grep(pattern = "prioritizedData.csv",x = list.dirs(path = paste(getwd(),"/users",userData$jobID,"prioritizedData")),
                  fixed = TRUE))>0){
     
     success <- TRUE
     
   } 
  } 
  else if (filtering == "m") { 
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    meanResultFile = paste(resultFolder,"/prioritizedData_meanfiltered.csv",sep ="")

    write.table(KEGGprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(meanResultFile)
      
  } 
  else if (filtering == "v") {
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
    varResultFile = paste(resultFolder,"/prioritizedData_varfiltered.csv",sep ="")
    
    write.table(KEGGprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    
  } 
  else if (filtering == "mv") {
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
    varResultFile = paste(resultFolder,"/prioritizedData_varfiltered.csv",sep ="")
    meanResultFile = paste(resultFolder,"/prioritizedData_meanfiltered.csv",sep ="")
    
    write.table(KEGGprioritized.50meanfiltered.data,
                   meanResultFile,
                   sep = ",",
                   append = FALSE)
    
    write.table(KEGGprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    fixResultsFile(meanResultFile)
  }
  
  sendmail(sucess)
}

fixResultsFile <- function(filePath){
 system2("irb", 
         args = c("/srv/shiny-server/CDPOnline/fixResults.rb", filePath),
         wait = TRUE,
         stdout = NULL)
}

#Start code for SendEmailButton (in Results tab)
sendEmail <- function(success){
  if(success){
    table = read.delim("message.txt", sep = ":")
    
    topic = as.character(table$value[[1]])
    message = as.character(table$value[[2]])
    
    sendmail(from = "hassam303@gmail.com", 
             to = c(userData$email), 
             subject = topic, 
             msg = message,
             control=list(smtpServer="relay.cougars.int"))
  }
  else{
    sendmail(from = "hassam303@gmail.com", 
             to = c(userData$email), 
             subject = "CDPOnline:Error Occured", 
             msg = "something went wrong that caused us not to be able to filter your data #ENTER_ERROR_HERE#, please try again",
             control=list(smtpServer="relay.cougars.int"))
    
  }
}
#End code for SendEmailButton (in Results tab)

args <- commandArgs(trailingOnly = TRUE)
userData <- fromJSON(args[1])

KEGGWorkflow()

print("Workflow Complete")
print(Sys.time())


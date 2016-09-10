#!/usr/bin/env Rscript
require(ComplementaryDomainPrioritization)
require(jsonlite)
require(sendmailR)

WIKIWorkflow <- function(){
  
  # Get WebGestalt Data if needed 
  if (length(userData$WG_file_path) == 0){
    system2("irb",
            args = c("CDP_WebGestalt_Watir_Script.rb",userData$jobID),
            wait = TRUE)
    userData <- fromJSON(args[1])
  }
  
  wiki.pathways = load.WebGestalt(userData$WG_file_path, 'Wiki')
  print(wiki.pathways)
  WIKIgene.ids = get.genes.wiki(wiki.pathways)
  
  startCol = userData$startCol
  theta = userData$theta
  filtering = userData$filtering
  
  transc.rna = load.gene.data(userData$TRANS_file_path, startCol) 
  WIKIprioritized.data = list.filter(transc.rna$transposed.data,WIKIgene.ids)
  
  resultFolder  = paste("users/", userData$jobID,"/prioritizedData",sep ="")
  dir.create(resultFolder)
  
  resultFile = paste(resultFolder,"/prioritizedData.csv", sep = "")
  
  write.table(WIKIprioritized.data,
              resultFile,
              sep = ",",
              append = FALSE)
  
  fixResultsFile(resultFile)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {} 
  else if (filtering == "m") { 
    WIKIprioritized.50meanfiltered.data = overall.mean.filter(WIKIprioritized.data, theta)
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")
    
    write.table(WIKIprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(meanResultFile)
    
  } 
  else if (filtering == "v") {
    WIKIprioritized.50varfiltered.data = overall.var.filter(WIKIprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    
    write.table(WIKIprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    
  } 
  else if (filtering == "mv") {
    WIKIprioritized.50meanfiltered.data = overall.mean.filter(WIKIprioritized.data, theta)
    WIKIprioritized.50varfiltered.data = overall.var.filter(WIKIprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")
    
    write.table(WIKIprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    write.table(WIKIprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    fixResultsFile(meanResultFile)
  }
}

fixResultsFile <- function(filePath){
  system2("irb", 
          args = c("fixResults.rb", filePath),
          wait = TRUE,
          stdout = NULL)
}



args <- commandArgs(trailingOnly = TRUE)
userData <- fromJSON(args[1])

WIKIWorkflow()

print("Workflow Complete")
print(Sys.time())


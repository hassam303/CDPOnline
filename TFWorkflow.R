#!/usr/bin/env Rscript
require(ComplementaryDomainPrioritization)
require(jsonlite)
require(sendmailR)

TFWorkflow <- function(){
  
  # Get WebGestalt Data if needed 
  if (length(userData$WG_file_path) == 0){
    system2("irb",
            args = c("CDP_WebGestalt_Watir_Script.rb",userData$jobID),
            wait = TRUE)
    userData <- fromJSON(args[1])
  }
  
  tf.pathways = load.WebGestalt(userData$WG_file_path, 'TF')
  print(tf.pathways)
  TFgene.ids = get.genes.tf(tf.pathways)
  
  startCol = userData$startCol
  theta = userData$theta
  filtering = userData$filtering
  
  transc.rna = load.gene.data(userData$TRANS_file_path, startCol) 
  TFprioritized.data = list.filter(transc.rna$transposed.data,TFgene.ids)
  
  resultFolder  = paste("users/", userData$jobID,"/prioritizedData",sep ="")
  dir.create(resultFolder)
  
  resultFile = paste(resultFolder,"/prioritizedData.csv", sep = "")
  
  write.table(TFprioritized.data,
              resultFile,
              sep = ",",
              append = FALSE)
  
  fixResultsFile(resultFile)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {} 
  else if (filtering == "m") { 
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")
    
    write.table(TFprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(meanResultFile)
    
  } 
  else if (filtering == "v") {
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    
    write.table(TFprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    
  } 
  else if (filtering == "mv") {
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")
    
    write.table(TFprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    write.table(TFprioritized.50varfiltered.data,
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

TFWorkflow()

print("Workflow Complete")
print(Sys.time())


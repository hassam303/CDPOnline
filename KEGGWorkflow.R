#!/usr/bin/env Rscript
require(ComplementaryDomainPrioritization)
require(jsonlite)
require(sendmailR)

KEGGWorkflow <- function(){
  
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
  
  resultFolder  = paste("users/", userData$jobID,"/prioritizedData",sep ="")
  dir.create(resultFolder)
  
  resultFile = paste(resultFolder,"/prioritizedData.csv", sep = "")
  
  write.table(KEGGprioritized.data,
              resultFile,
              sep = ",",
              append = FALSE)
  
  fixResultsFile(resultFile)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {} 
  else if (filtering == "m") { 
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")

    write.table(KEGGprioritized.50meanfiltered.data,
                meanResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(meanResultFile)
      
  } 
  else if (filtering == "v") {
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    
    write.table(KEGGprioritized.50varfiltered.data,
                varResultFile,
                sep = ",",
                append = FALSE)
    
    fixResultsFile(varResultFile)
    
  } 
  else if (filtering == "mv") {
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
    varResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_varfiltered.csv",sep ="")
    meanResultFile = paste("users/", userData$jobID,"/prioritizedData/prioritizedData_meanfiltered.csv",sep ="")
    
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
}

fixResultsFile <- function(filePath){
 system2("irb", 
         args = c("fixResults.rb", filePath),
         wait = TRUE,
         stdout = NULL)
}



args <- commandArgs(trailingOnly = TRUE)
userData <- fromJSON(args[1])

KEGGWorkflow()

print("Workflow Complete")


#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

TFWorkflow <- function(tsvFile, csvFile, startCol, filtering, theta){
  
  tf.pathways = load.WebGestalt(tsvFile, 'TF')
  TFgene.ids = get.genes.tf(tf.pathways)
  
  startCol = as.numeric(startCol)
  theta = as.numeric(theta)
  
  transc.rna = load.gene.data(csvFile,startCol)
  TFprioritized.data = list.filter(transc.rna$transposed.data,TFgene.ids)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {
    return(NULL)
  } else if (filtering == "m") {
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
  } else if (filtering == "v") {
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
  } else if (filtering == "mv") {
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
    
  }
}

args <- commandArgs(trailingOnly = TRUE)

TFWorkflow(args[1], args[2], args[3], args[4], args[5])

print("Workflow Complete")


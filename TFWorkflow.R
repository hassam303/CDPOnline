#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

TFWorkflow <- function(tsvFile, csvFile, startCol, filter = NULL, theta = NULL){
  
  tf.pathways = load.WebGestalt(tsvFile, 'TF')
  TFgene.ids = get.genes.tf(tf.pathways)
  
  transc.rna = load.gene.data(csvFile,startCol)
  TFprioritized.data = list.filter(transc.rna$transposed.data,TFgene.ids)
  
  if (is.null(filter)) {
    next
  } else if (filter == 1) {
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
  } else if (filter == 2) {
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
  } else {
    TFprioritized.50meanfiltered.data = overall.mean.filter(TFprioritized.data, theta)
    TFprioritized.50varfiltered.data = overall.var.filter(TFprioritized.data, theta)
    
  }
}

args <- commandArgs(trailingOnly = TRUE)

TFWorkflow(args[1], args[2], args[3])

print("Workflow Complete")


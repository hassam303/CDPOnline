#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

KEGGWorkflow <- function(tsvFile, csvFile, startCol, filtering, theta){
  
  kegg.pathways = load.WebGestalt(tsvFile, 'Kegg')
  KEGGgene.ids = get.genes.kegg(kegg.pathways)
  
  startCol = as.numeric(startCol)
  theta = as.numeric(theta)
  
  transc.rna = load.gene.data(csvFile, startCol) 
  KEGGprioritized.data = list.filter(transc.rna$transposed.data,KEGGgene.ids)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {
    return(NULL)
  } else if (filtering == "m") { 
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
  } else if (filtering == "v") {
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
  } else {
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
  }
}

args <- commandArgs(trailingOnly = TRUE)

KEGGWorkflow(args[1], args[2], args[3], args[4], args[5])

print("Workflow Complete")


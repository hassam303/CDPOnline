#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

KEGGWorkflow <- function(tsvFile, csvFile, startCol, filtering, theta){
  # temporariliy set filtering and theta != NULL to troubleshoot. 
  
  kegg.pathways = load.WebGestalt(tsvFile, 'Kegg')
  KEGGgene.ids = get.genes.kegg(kegg.pathways)
  
  startCol = as.numeric(startCol)
  theta = as.numeric(theta)
  
  transc.rna = load.gene.data(csvFile, startCol) # works now. 
  KEGGprioritized.data = list.filter(transc.rna$transposed.data,KEGGgene.ids)
  
  if (is.null(filtering)) {
    return(NULL)
  } else if (filtering == 1) { 
    # problem: this option is true when 1) only mean selected. 2) both mean and variance selected.
    # means that filtering length is not greater than 1. 
    # filtering[2] is NA. when both mean and var are selected. 
    # potential fix is three radio buttons. But doesn't look as nice. 
    # working on making checkboxes work.
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    paste(filtering)
  } else if (filtering == 2) {
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)
  } else {
    KEGGprioritized.50meanfiltered.data = overall.mean.filter(KEGGprioritized.data, theta)
    KEGGprioritized.50varfiltered.data = overall.var.filter(KEGGprioritized.data, theta)  
  }
}

args <- commandArgs(trailingOnly = TRUE)

KEGGWorkflow(args[1], args[2], args[3], args[4], args[5])

print("Workflow Complete")


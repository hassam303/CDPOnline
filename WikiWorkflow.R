#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

WikiWorkflow <- function(tsvFile, csvFile, startCol, filter = NULL, theta = NULL){
  
  wiki.pathways = load.WebGestalt(tsvFile, 'Wiki')
  Wikigene.ids = get.genes.wiki(wiki.pathways)
  
  transc.rna = load.gene.data(csvFile,startCol)
  Wikiprioritized.data = list.filter(transc.rna$transposed.data,Wikigene.ids)
  
  if (is.null(filter)) {
    next
  } else if (filter == 1) {
    Wikiprioritized.50meanfiltered.data = overall.mean.filter(Wikiprioritized.data, theta)
  } else if (filter == 2) {
    Wikiprioritized.50varfiltered.data = overall.var.filter(Wikiprioritized.data, theta)
  } else {
    Wikiprioritized.50meanfiltered.data = overall.mean.filter(WIkiprioritized.data, theta)
    Wikiprioritized.50varfiltered.data = overall.var.filter(Wikiprioritized.data, theta)
    
  }
}

args <- commandArgs(trailingOnly = TRUE)

WikiWorkflow(args[1], args[2], args[3])

print("Workflow Complete")


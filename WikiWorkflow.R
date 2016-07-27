#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)

WikiWorkflow <- function(jsonLoc){
  
  wiki.pathways = load.WebGestalt(tsvFile, 'Wiki')
  Wikigene.ids = get.genes.wiki(wiki.pathways)
  
  startCol = as.numeric(startCol)
  theta = as.numeric(theta)
  
  transc.rna = load.gene.data(csvFile, startCol)
  Wikiprioritized.data = list.filter(transc.rna$transposed.data,Wikigene.ids)
  
  if (is.null(filtering) || filtering == "" || is.null(theta)) {
    return(NULL)
  } else if (filtering == "m") {
    Wikiprioritized.50meanfiltered.data = overall.mean.filter(Wikiprioritized.data, theta)
  } else if (filtering == "v") {
    Wikiprioritized.50varfiltered.data = overall.var.filter(Wikiprioritized.data, theta)
  } else if (filtering == "mv") {
    Wikiprioritized.50meanfiltered.data = overall.mean.filter(Wikiprioritized.data, theta)
    Wikiprioritized.50varfiltered.data = overall.var.filter(Wikiprioritized.data, theta)
    
  }
}

args <- commandArgs(trailingOnly = TRUE)

WikiWorkflow(args[1])

print("Workflow Complete")


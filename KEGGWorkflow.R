#!/usr/bin/env Rscript
library(ComplementaryDomainPrioritization)


KEGGWorkflow <- function(tsvFile, csvFile, theta = NULL){
  
  
  
  kegg.pathways = load.WebGestalt(tsvFile, 'Kegg')
  KEGGgene.ids = get.genes.kegg(kegg.pathways)
  
  Cattaneo.rna = load.gene.data(csvFile,5)
  KEGGprioritized.data = list.filter(Cattaneo.rna$transposed.data,KEGGgene.ids)
}


args <- commandArgs(trailingOnly = TRUE)

KEGGWorkflow(args[1], args[2])

print("Workflow Complete")


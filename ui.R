library(shiny)

shinyUI(fluidPage( theme = "bootstrap.css", 
  # Important! : JavaScript functionality to add the Tabs
  # Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
  tags$head(tags$script(HTML("
                             /* In coherence with the original Shiny way, tab names are created with random numbers. 
                             To avoid duplicate IDs, we collect all generated IDs.  */
                             var hrefCollection = [];
                             
                             Shiny.addCustomMessageHandler('addTabToTabset', function(message){
                             var hrefCodes = [];
                             /* Getting the right tabsetPanel */
                             var tabsetTarget = document.getElementById(message.tabsetName);
                             
                             /* Iterating through all Panel elements */
                             for(var i = 0; i < message.titles.length; i++){
                             /* Creating 6-digit tab ID and check, whether it was already assigned. */
                             do {
                             hrefCodes[i] = Math.floor(Math.random()*100000);
                             } 
                             while(hrefCollection.indexOf(hrefCodes[i]) != -1);
                             hrefCollection = hrefCollection.concat(hrefCodes[i]);
                             
                             /* Creating node in the navigation bar */
                             var navNode = document.createElement('li');
                             var linkNode = document.createElement('a');
                             
                             linkNode.appendChild(document.createTextNode(message.titles[i]));
                             linkNode.setAttribute('data-toggle', 'tab');
                             linkNode.setAttribute('data-value', message.titles[i]);
                             linkNode.setAttribute('href', '#tab-' + hrefCodes[i]);
                             
                             navNode.appendChild(linkNode);
                             tabsetTarget.appendChild(navNode);
                             };
                             
                             /* Move the tabs content to where they are normally stored. Using timeout, because
                             it can take some 20-50 millis until the elements are created. */ 
                             setTimeout(function(){
                             var creationPool = document.getElementById('creationPool').childNodes;
                             var tabContainerTarget = document.getElementsByClassName('tab-content')[0];
                             
                             /* Again iterate through all Panels. */
                             for(var i = 0; i < creationPool.length; i++){
                             var tabContent = creationPool[i];
                             tabContent.setAttribute('id', 'tab-' + hrefCodes[i]);
                             
                             tabContainerTarget.appendChild(tabContent);
                             };
                             }, 100);
                             });
                             "))),
  # End Important 
  #Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
  
  shinyjs::useShinyjs(),
  
  navbarPage("CDP Online",
             id = "navbar", 
             ###Start Home Layout###
             tabPanel("Home",
                      sidebarLayout(
                         sidebarPanel(
                          tags$div(title="Please select a .tsv file.",
                            fileInput("WG_file", label="WEBGESTALT OUTPUT", accept = '.tsv')),
                          
                          radioButtons("pathway", label = "ENRICHMENT PATHWAY", 
                                       choices = list("KEGG" = "Kegg", 
                                                      "Transcription Factor" = "TF", 
                                                      "WikiPathways" = "Wiki"), 
                                       selected="Kegg"),
                          
                          br(),
                          
                          tags$div(title="Please select a .csv file.",
                            fileInput("TRANS_file", label = "TRANSCRIPTOMIC DATA", accept = '.csv')),
                          
                          numericInput("col_start", 
                                       label = "COLUMN WHERE TRANSCRIPTOMIC DATA BEGINS",
                                       min=2, step=1, value=2),
                          
                          tags$hr(),
                          
                          checkboxGroupInput("filtering", label = "INDEPENDENT FILTERING",
                                             choices = c("Mean Abundance" = 1, "Variance" = 2)),
                          
                          numericInput("theta", 
                                       label="Theta", 
                                       min = 0, 
                                       step = 0.1, 
                                       value=0.0),
                          
                          tags$hr(),
                          
                          textInput("email", label="EMAIL RESULTS TO:"),
                          
                          fluidRow(
                            actionButton("submit", "Submit"),
                            uiOutput("toJobResults")         
                          )
                        ),
                        
                        mainPanel(
                          h3("Stage 1: Gene List Generation"),
                          h4("Enrichment Analysis with WebGestalt"),
                          br(),
                          p("Gene list generation is driven by proteomic data analysis. Quantitative proteomic
                            data is used along with class labels to detect significant proteins at a given threshold. 
                            "),
                          p("Following KEGG, WikiPathways (WikiP) or TF enrichment
                            analysis, the resulting pathways and gene sets are downloaded from WebGestalt as
                            .tsv files. The result of this stage is a set of pathways or gene sets derived from
                            proteomic data. View an ", 
                            tags$a(href="http://freyja.cs.cofc.edu/downloads/ComplementaryDomainPrioritization/Marra_5percentFDR_kegg_protein_enrichment.tsv", "example "),
                            "WebGestalt output file."),
                          
                          br(),
                          
                          h3("Stage 2: Gene Prioritization and Filtering"),
                          h4("Gene List Prioritization with Pathway Enrichment"),
                          br(),
                          p("The enriched pathways or gene sets are then queried against the relevant database
                            to extract the genes belonging to each pathway or gene set of interest."),
                          
                          tags$ul(
                            tags$li("Pathway information for KEGG is extracted using the KEGGREST R package."),
                            tags$li("Pathway information for WikiPathways is retrieved using the official web service provided
                                    by WikiPathways."),
                            tags$li("Gene set information from the transcription factor database
                                    (via MSigDB) is downloaded and queried locally.")
                            ),
                          
                          p("Resulting gene lists are applied to the entire transcriptomics data set,
                            thus prioritizing genes involved in pathways showing enrichment at the protein expression level and removing genes not present in these pathways. View an ", 
                            tags$a(href="http://freyja.cs.cofc.edu/downloads/ComplementaryDomainPrioritization/Catteno_array.csv", "example"), 
                            " transcriptomic data file."),
                          br(),
                          
                          h4("Independent Filters"),
                          br(),
                          p("Invariant filtering is applied to further enhance the power of detection by applying variance or mean abundance filtering."), 
                          
                          tags$ul(
                            tags$li("Variance filtering is defined as ranking
                                    the genes according to variance across samples."),
                            tags$li("Mean abundance filtering ranks the genes by the mean
                                    abundance of each gene.")
                            ),
                          p("For either variance or abundance based filtering, a θ can be specified, which is the target number of ranked variables; otherwise, it is the top θ fraction of ranked variables."),
                          br()
                            )
                          )
                      )
             ###End Home Layout###
  ),
  
  # Important! : 'Freshly baked' tabs first enter here.
  #Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
  uiOutput("creationPool", style = "display: none;")
  # End Important
  #Credits: K. Rohde (http://stackoverflow.com/questions/35020810/dynamically-creating-tabs-with-plots-in-shiny-without-re-creating-existing-tabs/)
))


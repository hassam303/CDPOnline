#CDP_WebGestalt_Watir_Script.rb
#Created by: Hassam Solano-Morel, Paul Anderson
#


##Planning: Use JSON file to transer over data from main workflow



require 'watir-webdriver'
require 'headless'
require "open-uri"
Watir.default_timeout = 300

DOWNLOAD_PATH = "#{Dir.pwd}/downloads" + "/test.tsv" #REPLACE text.tsv w/ "JSON:jobID"
ENTREZ_IDS_FILE = "entrez-ids.txt" #ARGV[0]


headless = Headless.new
headless.start
b = Watir::Browser.start 'http://bioinfo.vanderbilt.edu/webgestalt/login.php'

puts b.title#*

b.text_field(:name => 'j_username').set 'hassam303@gmail.com'
b.button(:name => 'submit').click

puts b.title#*

#Paste in entrez ids 
b.select_list(:name => 'organism').select 'hsapiens'
# Options
#<option>hsapiens</option>
#<option>mmusculus</option>
#<option>rnorvegicus</option>
#<option>drerio</option>
#<option>celegans</option>	
#<option>scerevisiae</option>
#<option>cfamiliaris</option>
#<option>dmelanogaster</option>
b.select_list(:name => 'idtype').select 'hsapiens__entrezgene'
ids = IO.read(ENTREZ_IDS_FILE)
b.textarea(:name => 'pastefile').set ids
b.button(:index => 1).click

puts b.title#*



#Selecting Enrichment Options
b.element(:id => "one-ddheader").hover
b.link(:text =>"KEGG Analysis").click #"JSON:enrichmentType"
b.select_list(:name => "refset").select "hsapiens__entrezgene_protein-coding"#"JSON:refSet"
b.select_list(:name => "cutoff").select ".05"#"JSON:sigLevel"
b.select_list(:name => "min").select "5"#Minimum Number of genes in category "JSON:minGenes"

b.button(:value => "Run Enrichment Analysis").click


b.windows.last.use #Previous action opens a new window


#Download TSV Results 
File.open(DOWNLOAD_PATH, 'w') do |file|
  file.write open(b.link(:text => "Export TSV Only").href).read
end



b.close
headless.destroy






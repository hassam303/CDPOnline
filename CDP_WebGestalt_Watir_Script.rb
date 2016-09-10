#CDP_WebGestalt_Watir_Script.rb
#Created by: Hassam Solano-Morel, Paul Anderson
#


require 'watir-webdriver'
require 'headless'
require "open-uri"
require "json"
Watir.default_timeout = 300

file = File.read("#{Dir.pwd}/users/" + ARGV[0] +"/userData.txt")
userData = JSON.parse(file)


DOWNLOAD_PATH = "#{Dir.pwd}/users/" + ARGV[0]+ "/webGResults.tsv" #REPLACE text.tsv w/ "JSON:jobID"
ENTREZ_IDS = userData['entrezIDs']



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
sleep(2)
b.select_list(:name => 'idtype').select 'hsapiens__entrezgene'
b.textarea(:name => 'pastefile').set ENTREZ_IDS.join("\n")
b.button(:index => 1).click

puts b.title#*

enrichment = userData['enrichmentType']

case enrichment 
when "KEGG"
	enrichment = "KEGG Analysis"
when "TF"
	enrichment = "Transcription Factor Target Analysis"
when "WIKI"
	enrichment = "Wikipathways Analysis"

end 

#Selecting Enrichment Options
b.element(:id => "one-ddheader").hover
sleep(2)
b.link(:text => enrichment).click #"JSON:enrichmentType"
b.select_list(:name => "refset").select "hsapiens__entrezgene_protein-coding"#"JSON:refSet"
b.select_list(:name => "cutoff").select userData['cutoff']#"JSON:sigLevel"
b.select_list(:name => "min").select userData['minGenes'] #Minimum Number of genes in category

b.button(:value => "Run Enrichment Analysis").click


b.windows.last.use #Previous action opens a new window


#Download TSV Results 
File.open(DOWNLOAD_PATH, 'w') do |file|
  file.write open(b.link(:text => "Export TSV Only").href).read
end



b.close
headless.destroy


userData['WG_file_path'] = DOWNLOAD_PATH

puts userData.to_json

File.open("#{Dir.pwd}/users/" + ARGV[0] +"/userData.txt",'w') do |f|
  f << userData.to_json
end








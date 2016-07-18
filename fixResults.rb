original_file = ARGV[0]
new_file = original_file + '.new'

lineFixed = 0 

File.open(new_file, 'w') do |fo|
  File.foreach(original_file) do |li|
  	if lineFixed == 0
  		fo.puts "Gene id," + li
  		lineFixed = 1
  	else
  		fo.puts li
  	end 
  end
end

File.delete(original_file)
File.rename(new_file, original_file)
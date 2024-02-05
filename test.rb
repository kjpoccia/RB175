data_path = File.expand_path("../Temp/data", __FILE__)

pattern = File.join(data_path, "*")

files = Dir.glob(pattern).map do |path|
  File.basename(path)
end

file_path = File.join(data_path, "file_2.txt")
# p file_path
new_file = File.new(file_path, "w+")
new_file.close

puts "The file has been created"
sleep(10)

File.delete(new_file)

puts "The file has been deleted"
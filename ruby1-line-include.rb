abort "usage: ruby ruby1-line-include.rb search file" unless ARGV.length == 2
search, file = *ARGV

File.open(file) do |f|
	f.each_line do |line|
		puts line if line.include? search
	end
end
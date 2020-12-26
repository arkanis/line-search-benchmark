abort "usage: ruby ruby1-line-include.rb search file" unless ARGV.length == 2
search, file = *ARGV

data = File.read(file)
pos = 0
while (pos = data.index(search, pos)) != nil do
	start_pos = data.rindex("\n", pos)
	start_pos = (start_pos == nil) ? 0 : start_pos + 1  # the +1 skips the \n of the prev line
	end_pos = data.index("\n", pos)
	end_pos = data.bytesize if end_pos == nil
	puts data.byteslice(start_pos..end_pos)
	
	pos += search.bytesize
end
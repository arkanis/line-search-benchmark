require "base64"

abort "usage: ruby gen-lines.rb line-count" unless ARGV.first

line_count = ARGV.first.to_i  # 80_000_000
sample_label_count = 10

random = Random.new
labels = []
line_count.times do |i|
  name = Base64.strict_encode64(random.bytes(8 + random.rand(24)))
  label = Base64.strict_encode64(random.bytes(8 + random.rand(128)))
  labels << label if random.rand(line_count / sample_label_count) == 1
  puts "http://mediagraph.link/vndb/#{i}/#{name}\t#{label}"
end

$stderr.puts labels
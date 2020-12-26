# Small script to generate test files with a given number of lines in a
# deterministic way, e.g.:
# 
# ruby gen-lines.rb 80_000_000 > lines-80m.txt
# 
# This generates 80 million sample lines and saves them in lines-80m.txt (ruby
# allows underscores in numbers).
# A random sample of about 10 lines is taken and printed to STDERR. Those
# samples can then be used to test the search programs.
# 
# The generated lines are always the same since the random number generator is
# always seeded with the same value.

abort "usage: ruby gen-lines.rb line-count" unless ARGV.first

line_count = ARGV.first.to_i
sample_label_count = 10

random = Random.new 1234
samples = []
line_count.times do |i|
  # ID is a random group of 4 byte hex chars separated by "-", e.g. "ec9e-7c1f-1a1f"
  id = Array.new(random.rand(2..8)){ random.bytes(2).unpack("H*").first }.join("-")
  # Label is a random group of words, each word a random group of [a-z] chars
  label = Array.new(random.rand(2..8)) do
    Array.new(random.rand(3..20)){ random.rand("a".ord.."z".ord).chr }.join("")
  end.join("_")
  
  line = "http://example.com/#{i}/#{id}\t#{label}"
  samples << line if random.rand(line_count / sample_label_count) == 1
  puts line
end

$stderr.puts samples
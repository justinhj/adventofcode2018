require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

width = lines[0].length
height = lines.length

map = Array.new(height)

def draw_map(m)
  m.each do |row|
    row.each do |c|
      print "#{c}"
    end
    print "\n"
  end
  print "\n"
end

lines.each_with_index do |line, index|
  row = Array.new(width)
  x = 0
  line.each_char do |c|
    row[x] = c
    x += 1
  end
  map[index] = row
end

draw_map(map)


# require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

points = []
lines.each do |line|
  points << /(-?[0-9]+),(-?[0-9]+),(-?[0-9]+),(-?[0-9]+)/.match(line).captures.map(&:to_i)
end

def manhattan_distance(p1, p2)
  d = p1.zip(p2).map { |a, b| (a-b).abs }.inject(0) { |acc, n| acc + n }
 #print "d #{p1} #{p2} #{d}\n"
  d
end

# establish connected points (n^2)

connected = []
points.each_with_index do |p1,i1|
  points.each_with_index do |p2,i2|
    next if i1 >= i2

    if manhattan_distance(p1,p2) <= 3
      connected << [i1,i2]
    end
  end
end

pp connected

def find_connected(first, h, i, connections)

  connections.each do |a,b|
    c = nil
    c = a if b == first
    c = b if a == first

    next if c.nil? or h[c]

    h[c] = a

    h = find_connected(c, h, i, connections)
  end
  
  h
end

i = 0
h = {}

# Algorithm
# find first node not in h, if none then done 
# search all nodes connected recursively and set node = i in h
# i + 1

while h.length < points.length

  first = (0...points.length).find_index { |p| h[p] == nil }

  h[first] = i
  h = find_connected(first, h, i, connected)

  i += 1

end

pp h
pp i

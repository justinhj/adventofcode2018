require 'set'

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

class Coord
  attr_accessor :id
  attr_accessor :x
  attr_accessor :y

  def initialize(id, str)
    @id = id
    raw_x, raw_y = str.split(",")
    @x = raw_x.to_i
    @y = raw_y.to_i
  end
  
end

coords = []

lines.each_with_index do |line, id|
  c = Coord.new(id, line)
  coords << c
  # print "#{id} (#{c.x}, #{c.y})\n"
end

# Find the minimum and maximum extents of the area

min_x = coords.min_by { |c| c.x }.x
max_x = coords.max_by { |c| c.x }.x
min_y = coords.min_by { |c| c.y }.y
max_y = coords.max_by { |c| c.y }.y

# Find the total distance to all coords
def find_total_distance(x,y, coords)

  distances = coords.map do |c|
    xd = (c.x - x).abs
    yd = (c.y - y).abs

    xd + yd
  end

  distances.sum

end

good_count = 0

(min_x..max_x).each do |x|
  (min_y..max_y).each do |y|
    td = find_total_distance(x,y,coords)
    
    good_count += 1 unless td >= 10000
  end
end

puts good_count 

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

# Finding the nearest location to a given x,y

def find_nearest(x,y, coords)

  distances = coords.map do |c|
    xd = (c.x - x).abs
    yd = (c.y - y).abs

    [xd + yd, c.id]
  end

  distances = distances.sort 

  # The first one is the one we want, unless the distance is the same as the second one (a tie)
  # in which case return -1 for the ID
  
  if distances[0][0] == distances[1][0]
    -1
  else
    distances[0][1]
  end
  
end

# Build a hash of x,y coord to the location nearest to it (-1 if a tie)

view = {}

(min_x..max_x).each do |x|
  (min_y..max_y).each do |y|
    nearest = -1
    view[[x,y]] = find_nearest(x,y,coords)
  end
end

# Count the number of locations by id

location_counts = Hash.new(0)

view.values.each do |location|
  location_counts[location] += 1
end

# All that remains is to find the ones that are infinite
# Which means one of their coords is at the limits of the view

infinite_locations = Set[]

view.each do |coord, id|
  if coord[0] == min_x || coord[0] == max_x || coord[1] == min_y || coord[1] == max_y
    infinite_locations << id
  end
end

# Remove these from the location_counts and sort by number of locations

location_counts = location_counts.delete_if { |location, count| infinite_locations.include?(location) }

location = location_counts.max_by { |location, count| count }
print "#{location[0]}, #{location[1]}\n"

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

def next_turn(current)
  case current
  when :left
    :straight
  when :straight
    :right
  when :right
    :left
  end
end

# define cars, extract cars from map

class Car
  attr_accessor :x,:y,:direction,:next_turn

  def initialize(x,y,direction)
    @x = x
    @y = y
    @direction = direction
    @next_turn = :left
  end
end

# Returns boolean whether character is a car or not
# and the direction it's going
def is_car(c)
  case c
  when 'v'
    [true, :down]
  when '^'
    [true, :up]
  when '>'
    [true, :right]
  when '<'
    [true, :left]
  else
    [false, nil]
  end
end

# removes cars from map, returns a new map with no
# cars and a list of cars
def cars_from_map(map)
  cars = []
  map.each_with_index do |row,y|
    x = 0
    row.each do |c|
      is_car, direction = is_car(c)

      if is_car == true
        
        
      end
      x += 1
    end
  end

  map, cars
end

    
  






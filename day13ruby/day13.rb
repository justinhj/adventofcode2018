require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

$width = lines[0].length
$height = lines.length

map = Array.new($height)

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
  row = Array.new($width)
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

def track_from_car(car)
  case car
  when 'v'
    '|'
  when '^'
    '|'
  when '<'
    '-'
  when '>'
    '-'
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
        cars << Car.new(x,y,direction)
        
        track = track_from_car(c)

        map[y][x] = track
        
      end
      x += 1
    end
  end

  [map, cars]
end

map, cars = cars_from_map(map)

def sort_cars(cars)
  cars.sort_by { |car| [car.y, car.x] }
end

# Movement

$move_up = "\u001b[1A"
$move_down = "\u001b[1B"
$move_right = "\u001b[1C"
$move_left = "\u001b[1D"

def draw_cars(cars)
  cars.each do |car|    
    # Move up
    printf("\u001b[%dA", $height - car.y + 1)
    # Move right
    printf("\u001b[%dC", car.x)
    
    printf car.direction + $move_left

    # Move down
    printf("\u001b[%dB", $height - car.y + 1)
    # Move left
    printf("\u001b[%dD", car.x)
  end
end

draw_map(map)

cars = sort_cars(cars)
draw_cars(cars)



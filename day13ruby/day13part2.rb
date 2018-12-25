require 'pry-byebug'
require 'io/console'
require 'set'

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

# Parse the map data
lines.each_with_index do |line, index|
  row = Array.new($width)
  x = 0
  line.each_char do |c|
    row[x] = c
    x += 1
  end
  map[index] = row
end

def turn_direction(direction, turn)
  case turn
  when :left
    case direction
    when :up
      :left
    when :down
      :right
    when :left
      :down
    when :right
      :up
    end
  when :straight
    direction
  when :right
    case direction
    when :up
      :right
    when :down
      :left
    when :left
      :up
    when :right
      :down
    end
  end
end

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

# Just for fun an explosion class

class Explosion
  attr_accessor :x,:y,:animation
  def initialize(x,y)
    @x = x
    @y = y
    @animation = "oO@*o"
  end

  def next_frame
    f = @animation[0]
    @animation[0] = ""
    f
  end
end
  
# define cars, extract cars from map

class Car
  attr_accessor :x,:y,:direction,:next_turn,:id
  
  def initialize(id,x,y,direction)
    @id = id
    @x = x
    @y = y
    @direction = direction
    @next_turn = :left
  end
end

def car_direction_to_s(direction)
  case direction
  when :down
    'v'
  when :up
    '^'
  when :right
    '>'
  when :left
    '<'
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
  id = 0
  map.each_with_index do |row,y|
    x = 0
    row.each do |c|
      is_car, direction = is_car(c)

      if is_car == true
        cars << Car.new(id, x,y,direction)
        id += 1
        
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

$bright_green = "\u001b[32;1m"
$bright_red = "\u001b[31;1m"

$reset = "\u001b[0m"

def draw_explosions(explosions)
  explosions.each do |explode|

    frame = explode.next_frame()
    
    next if frame.nil?
    
    # Move up
    printf("\u001b[%dA", $height - explode.y + 1)
    # Move right
    printf("\u001b[%dC", explode.x) unless explode.x == 0
    
    printf $bright_red + frame + $move_left + $reset
    
    # Move down
    printf("\u001b[%dB", $height - explode.y + 1)
    # Move left
    printf("\u001b[%dD", explode.x) unless explode.x == 0
  end
  
end

def draw_cars(cars)
  cars.each do |car|    
    # Move up
    printf("\u001b[%dA", $height - car.y + 1)
    # Move right
    printf("\u001b[%dC", car.x) unless car.x == 0
    
    printf $bright_green + car_direction_to_s(car.direction) + $reset + $move_left
    # Move down
    printf("\u001b[%dB", $height - car.y + 1)
    # Move left
    printf("\u001b[%dD", car.x) unless car.x == 0
  end
end

def move_cars(cars, explosions, map)
  
  positions = cars.each_with_object(Hash.new {Set.new()} ) do |car, acc|
    s = acc[[car.x, car.y]]
    s.add car.id
    acc[[car.x, car.y]] = s
    acc
  end

  deleted_cars = Set.new()

#  binding.pry
  cars = sort_cars(cars)
  cars.map do |car|

    next if deleted_cars.include? car.id
    
    m = map[car.y][car.x]

    positions[[car.x,car.y]].delete(car.id)
    
    if m == '-' and car.direction == :right
      car.x = car.x + 1
    elsif m == '-' and car.direction == :left
      car.x = car.x - 1
    elsif m == '|' and car.direction == :up
      car.y = car.y - 1
    elsif m == '|' and car.direction == :down
      car.y = car.y + 1
    elsif m == '/' and car.direction == :up
      car.x = car.x + 1
      car.direction = :right
    elsif m == '/' and car.direction == :left
      car.y = car.y + 1
      car.direction = :down
    elsif m == '/' and car.direction == :down
      car.x = car.x - 1
      car.direction = :left
    elsif m == '/' and car.direction == :right
      car.y = car.y - 1
      car.direction = :up
    elsif m == '\\' and car.direction == :right
      car.y = car.y + 1
      car.direction = :down
    elsif m == '\\' and car.direction == :up
      car.x = car.x - 1
      car.direction = :left
    elsif m == '\\' and car.direction == :left
      car.y = car.y - 1
      car.direction = :up
    elsif m == '\\' and car.direction == :down
      car.x = car.x + 1
      car.direction = :right
    elsif m == '+'
      car.direction = turn_direction(car.direction, car.next_turn)
      car.next_turn = next_turn(car.next_turn)
      case car.direction
      when :up
        car.y = car.y - 1
      when :down
        car.y = car.y + 1
      when :left
        car.x = car.x - 1
      when :right
        car.x = car.x + 1
      end
    end

    positions[[car.x,car.y]] = positions[[car.x,car.y]].add car.id

    if positions[[car.x,car.y]].length > 1
      positions[[car.x,car.y]].each { |c| deleted_cars.add c }
      positions[[car.x, car.y]] = Set.new()
    end
    
  end

  cars.each do |car|
    if deleted_cars.include? car.id
      explosions << Explosion.new(car.x, car.y)
    end
  end
  
  # Remove cars at collide positions
  [cars.delete_if { |car| deleted_cars.include? car.id }, explosions]
  
end

cars = sort_cars(cars)
#draw_cars(cars)

animate = true
explosions = []

draw_map(map)

if animate
  # Animate the solution
  loop do
    draw_map(map)
    print $move_up * ($height + 1)
    print $move_left * 1000
    cars, explosions = move_cars(cars, explosions, map)
    draw_explosions(explosions)
    draw_cars(cars)
    sleep 0.5
    if cars.length == 1
      car = cars.first
      print "Last car is at #{car.x},#{car.y}"
      k = STDIN.getch
      if k == 'q'
        exit
      end
    end
  end
else
  loop do
    cars, explosions = move_cars(cars, explosions, map)
    if cars.length == 1
      car = cars.first
      print "Last car is at #{car.x},#{car.y}"
      k = STDIN.getch
      if k == 'q'
        exit
      end
    end
  end
end

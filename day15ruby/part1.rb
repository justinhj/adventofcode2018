require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

walls = Array.new(lines.length) { Array.new(lines[0].length) }

class Unit
  attr_accessor :x,:y,:kind,:hp
  
  def initialize(x,y,kind,hp)
    @x = x
    @y = y
    @kind = kind
    @hp = hp
  end
end

units = []

lines.each_with_index do |line, row|
  col = 0
  line.each_char do |cell|

    if cell == 'E'
      units << Unit.new(col, row, 'E', 200)
      walls[row][col] = '.'
    elsif cell == 'G'
      units << Unit.new(col, row, 'G', 200)
      walls[row][col] = '.'
    else
      walls[row][col] = cell
    end
    
    col += 1
  end
end

# Ansi escape codes

$move_up = "\u001b[1A"
$move_down = "\u001b[1B"
$move_right = "\u001b[1C"
$move_left = "\u001b[1D"

$bright_white = "\u001b[37;1m"
$bright_red = "\u001b[31;1m"
$bright_green = "\u001b[32;1m"
$blue = "\u001b[34m"
$bright_blue = "\u001b[34;1m"

$reset = "\u001b[0m"

# later add units
def draw_world(walls, units)
  walls.each_with_index do |line, row|
    line.each_with_index do |cell, col|
      if walls[row][col].is_a? Numeric
        print walls[row][col] % 10
      else
        print walls[row][col]
      end
    end
    print "\n"
  end

  units.each do |unit|

    print $move_up * (walls.length - unit.y)
    print ($move_right * unit.x)

    print unit.type

    print $move_down * (walls.length - unit.y)
    print $move_left * (unit.x + 1)
  end
  
end

# Returns the nearest target after doing Dijkstra graph traversal
# to determin shortest path to enemies
def find_target(walls, units, unit)

  me = units[unit]
  
  height = walls.length
  width = walls[0].length

  target_map = walls.clone

  # add everyone to the map with enemies as E and friendlies as walls
  units.each do |unit|
    if unit.kind != me.kind
      target_map[unit.y][unit.x] = 'E'
    else
      target_map[unit.y][unit.x] = '#'
    end
  end

  # for all enemnies mark the target attack positions with ?
  (0...width).each do |row|
    (0...height).each do |col|
      this_unit = target_map[row][col]

      if target_map[row][col] == 'E'
        # left target
        if col >=1 and target_map[row][col-1] == '.'
          target_map[row][col-1] = '?'
        end

        # right target
        if col < width-1 and target_map[row][col+1] == '.'
          target_map[row][col+1] = '?'
        end

        # above target
        if row >=1 and target_map[row-1][col] == '.'
          target_map[row-1][col] = '?'
        end

        # below target
        if row < height-1 and target_map[row+1][col] == '.'
          target_map[row+1][col] = '?'
        end
        
      end

    end
  end
  
  draw_world(target_map, [])

  path_map = target_map.clone
  
  # Now iteratively fill out the distances from me

  path_map[me.y][me.x] = 0
  changes = 0

  loop do

    (0...width).each do |row|
      (0...height).each do |col|
        if ['.', '?'].include? path_map[row][col]
          lowest_value = [1000]
          # left
          if col >=1 and path_map[row][col-1].is_a? Numeric
            lowest_value << path_map[row][col-1]
          end
          
          # right target
          if col < width-1 and path_map[row][col+1].is_a? Numeric
            lowest_value << path_map[row][col+1]
          end
          
          # above target
          if row >=1 and path_map[row-1][col].is_a? Numeric
            lowest_value << path_map[row-1][col]
          end
          
          # below target
          if row < height-1 and path_map[row+1][col].is_a? Numeric
            lowest_value << path_map[row+1][col]
          end
          
          lowest_value = lowest_value.min
          
          if lowest_value < 1000
            path_map[row][col] = lowest_value + 1
            changes += 1
          end
          
        end
      end
    end

    if changes == 0
      break
    else
      changes = 0
    end
    
  end

  draw_world(path_map, [])
  
end

# puts units

find_target(walls, units, 4)

# Data
# 2d grid of walls



# Unit health (200) and attack power (3), kind (G or E) , x and y position

# Turn
#   identify targets
#   if none, end of turn
#   if immediate target up down left or right, that's your target
#   (don't forget to  this in reading order)
#   otherwise need to move towards a target
#   calculate nearest in terms of moves (manhattan distance)
#   reading order for ties in distance
#   HP loweest is attacked 


# Combat
# Each unit not dead
#   resolve all actions
# Decide who does what based on row then column
#   try to move in range
#   attack
#   if multiple targets priority is top to bottom then left to right
#    no diagonal attack
# step 1
#    identify targets


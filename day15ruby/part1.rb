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

# later add units
def draw_world(walls)
  walls.each_with_index do |line, row|
    line.each_with_index do |cell, col|
      print walls[row][col]
    end
    print "\n"
  end
end

draw_world(walls)

# Returns the nearest target after doing Dijkstra graph traversal
# to determin shortest path to enemies
def find_target(walls, units, unit)

  me = units[unit]
  
  height = walls.length
  width = walls[0].length

  path_map = walls.clone

  # add everyone to the map with enemies as E and friendlies as walls
  units.each do |unit|
    if unit.kind != me.kind
      path_map[unit.y][unit.x] = 'E'
    else
      path_map[unit.y][unit.x] = '#'
    end
  end

  # for all enemnies mark the target attack positions with ?
  (0...width).each do |row|
    (0...height).each do |col|
      this_unit = path_map[row][col]

      if path_map[row][col] == 'E'
        # left target
        if col >=1 and path_map[row][col-1] == '.'
          path_map[row][col-1] = '?'
        end

        # right target
        if col < width-1 and path_map[row][col+1] == '.'
          path_map[row][col+1] = '?'
        end
        
      end

    end
  end
  
  draw_world(path_map)
  
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


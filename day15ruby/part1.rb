require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

walls = Array.new(lines.length) { Array.new(lines[0].length) }

class Unit
  attr_accessor :x,:y,:type,:hp
  
  def initialize(x,y,type,hp)
    @x = x
    @y = y
    @type = type
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
      print walls[row][col]
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

draw_world(walls, units)

# Data
# 2d grid of walls



# Unit health (200) and attack power (3), type (G or E) , x and y position

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


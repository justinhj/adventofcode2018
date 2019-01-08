require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

walls = Array.new(lines.length) { Array.new(lines[0].length) }

lines.each_with_index do |line, row|
  col = 0
  line.each_char do |cell|
    walls[row][col] = cell
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


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

# Deep copy a world
def copy_world(world)
  world.map(&:dup)
end

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

    print unit.kind

    print $move_down * (walls.length - unit.y)
    print $move_left * (unit.x + 1)
  end
  
end

# Returns the nearest target after doing Dijkstra graph traversal
# to determine shortest path to enemies
def move_to_target(walls, units, unit, debug_draw)

  me = units[unit]
  
  height = walls.length
  width = walls[0].length
  
  target_map = copy_world(walls)

  # add everyone to the map with enemies as E and friendlies as walls
  units.each do |unit|
    if unit.kind != me.kind
      target_map[unit.y][unit.x] = 'E'
    else
      target_map[unit.y][unit.x] = '#'
    end
  end

  # Don't move if already in range of a target
  # This is checked in reading order

  target = nil

  row = me.y
  col = me.x
  
  # Up?
  if row >=1 and target_map[row-1][col] == 'E'
    target = [[row-1][col]]
  end

  # Left?
  if col >=1 and target_map[row][col-1] == 'E'
    target = [[row][col-1]]
  end

  # Right?
  if col < width-1  and target_map[row][col+1] == 'E'
    target = [[row][col+1]]
  end
  
  # Down?
  if row < height-1 and target_map[row+1][col] == 'E'
    target = [[row+1][col]]
  end

  return unless target.nil?
  
  # for all enemies mark the target attack positions with ?
  (0...height).each do |row|
    (0...width).each do |col|

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
  
  draw_world(target_map, []) if debug_draw

  path_map = copy_world(target_map)
  
  # Now iteratively fill out the distances from me

  path_map[me.y][me.x] = 0
  changes = 0

  loop do

    (0...height).each do |row|
      (0...width).each do |col|
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

  draw_world(path_map, []) if debug_draw
  
  # Target locations - Anywhere where the original map has a question nmark
  # and the path map has a number ...
  # The targets will be a map of coordinates and cost

  reachable_targets = {}
  
  (0...height).each do |row|
    (0...width).each do |col|

      if target_map[row][col] == '?' and path_map[row][col].is_a? Numeric

        reachable_targets[[row,col]] = path_map[row][col]
        
      end
      
    end
  end

  min = reachable_targets.values.min || 0
  nearest_targets = reachable_targets.filter {|coord,distance| distance == min}

  return if nearest_targets.length == 0
  
  # Sort by reading order
  # Default sorting of arrays will do this for us

  target = nearest_targets.sort.first[0]

  # Sadly we need to now path find again to find the best route to that target

  path_map = copy_world(target_map)

  # This time the target is the centre of the path finding...
  path_map[target[0]][target[1]] = 0
  changes = 0

  loop do

    (0...height).each do |row|
      (0...width).each do |col|
        if ['.', '?'].include? path_map[row][col]
          lowest_value = [1000]
          # left target
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

  draw_world(path_map, []) if debug_draw

  # now we must choose where to move to, meaning the square around us
  # with smallest path find value... if there more than one sort by reading
  # order

  moves = {}

  row = me.y
  col = me.x
  
  # Left?
  if col >=1 and path_map[row][col-1].is_a? Numeric
    moves[[row,col-1]] = path_map[row][col-1]
  end

  # Right?
  if col < width-1  and path_map[row][col+1].is_a? Numeric
    moves[[row,col+1]] = path_map[row][col+1]
  end

  # Up?
  if row >=1 and path_map[row-1][col].is_a? Numeric
    moves[[row-1,col]] = path_map[row-1][col]
  end
  
  # Down?
  if row < height-1 and path_map[row+1][col].is_a? Numeric
    moves[[row+1,col]] = path_map[row+1][col]
  end

  min = moves.values.min
  best_moves = moves.filter {|coord,distance| distance == min}

  best_move = best_moves.sort.first[0]
  
  # Now we can move
  me.y = best_move[0]
  me.x = best_move[1]
  
end

# puts units

draw_world(walls, units)

(1..4).each do |_|
  units.each_with_index do |_, index|
    move_to_target(walls, units, index, false)
  end

  draw_world(walls, units)
end

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


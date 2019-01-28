require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

walls = Array.new(lines.length) { Array.new(lines[0].length) }

$attack_power = 3

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

# Find the unit at location
def get_unit_at(units,row,col)
  units.find{|u| u.y == row and u.x == col} 
end

# Returns the nearest target after doing Dijkstra graph traversal
# to determine shortest path to enemies
# We'll return a map of what to do and where to do it...
# :attack coord
# :move coord
def determine_action(walls, units, unit, debug_draw, attack_only)

  me = units[unit]

  return {} unless me.hp > 0
  
  height = walls.length
  width = walls[0].length
  
  target_map = copy_world(walls)

  target_count = 0
  
  # add everyone to the map with enemies as E and friendlies as walls
  # excluding those with no hitpoints
  units.each do |unit|
    next if unit.hp <= 0 
    
    if unit.kind != me.kind
      target_map[unit.y][unit.x] = 'E'
      target_count += 1
    else
      target_map[unit.y][unit.x] = '#'
    end
  end

  return {end: true} if target_count == 0
  
  # Don't move if already in range of a target
  # We need the targets ordered by hitpoints then reading
  # order

  targets = []

  row = me.y
  col = me.x

  # classify the targets into a coordinate array, hit point count and reading order
  if row >=1 and target_map[row-1][col] == 'E'
    # Up
    unit = get_unit_at(units,row-1,col)
    targets << [[row-1,col],unit.hp,0]
  end
  
  if col >=1 and target_map[row][col-1] == 'E'
    # Left
    unit = get_unit_at(units,row,col-1)
    targets << [[row,col-1],unit.hp,1]
  end
  
  if col < width-1  and target_map[row][col+1] == 'E'
    # Right
    unit = get_unit_at(units,row,col+1)
    targets << [[row,col+1],unit.hp,2]
  end
  
  if row < height-1 and target_map[row+1][col] == 'E'
    # Down
    unit = get_unit_at(units,row+1,col)
    targets << [[row+1,col],unit.hp,3]
  end

  unless targets.empty?
    min_hp = targets.map{|n| n[1]}.min

    targets = targets.filter{|n| n[1] == min_hp}

    targets = targets.sort_by{|n| n[2]}

    target = targets.first[0]
    target_unit = get_unit_at(units, target[0], target[1])
    
    return {attack: target_unit}
  end

  return {} if attack_only
  
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

  # No reachable target, return no action
  return {} if nearest_targets.length == 0
  
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
  
  {move: [best_move[0], best_move[1]]}
  
end

# puts units

draw_world(walls, units)

turn = 0

loop do

  print "Turn #{turn}\n"
  
  # Sort the units into reading order
  units = units.sort_by{|u| [u.y,u.x]}

  units.each_with_index do |unit, index|

    printf "unit at #{unit.y},#{unit.x} #{unit.kind} #{unit.hp}\n"

    unit_turn = 1
    
    loop do
      if unit_turn == 1
        action = determine_action(walls, units, index, false, false)
      else
        action = determine_action(walls, units, index, false, true)
      end
      
      if action[:end]
        printf("Combat complete at turn #{turn}\n")
        remaining_hp = units.inject(0) do |acc,u|
          if u.hp > 0
            acc + u.hp
          else
            acc
          end
        end
        printf("#{remaining_hp} hp remain\n")
        
        units.each do |u|
          printf "unit #{u.kind} #{u.hp}\n"
        end

        printf "answer part1 #{remaining_hp * turn}\n" 
        
        exit
      elsif action[:move]
        move = action[:move]
        me = units[index]
        me.y = move[0]
        me.x = move[1]
      elsif action[:attack]
        attack = action[:attack]
        printf "unit at #{unit.y},#{unit.x} attack! new hp = #{attack.hp - $attack_power}\n"
        attack.hp -= $attack_power
        unit_turn += 1
      end
      
      unit_turn += 1
      if unit_turn >= 3
        break
      end
    end
  end

  # Remove dead units
  units = units.filter{|u| u.hp > 0}

#  draw_world(walls, units)

  printf "after turn #{turn}\n"
  
  units.each do |u|
    printf "unit at #{u.y},#{u.x} #{u.kind} #{u.hp}\n"
  end

  turn += 1
end

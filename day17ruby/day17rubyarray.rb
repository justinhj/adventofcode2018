require 'pry-byebug'
require 'io/console'

# Use arrays not a hash

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

$min_y = 9999999
$max_y = -9999999
$min_x = 999999
$max_x = -999999

# Parse each line into a pair of walls, x1,y1 to x2,y2
# While doing so create the global min and max 

walls = []

lines.each do |line|

  xm = /x=(-?[0-9]+), y=(-?[0-9]+)\.\.(-?[0-9]+)/.match(line)
  
  unless xm.nil?
    x1,y1,y2 = xm.captures.map(&:to_i)
    x2 = x1
    walls << {x1: x1, y1: y1, x2: x2, y2: y2}

    if x1 < $min_x
      $min_x = x1
    end

    if x1 > $max_x
      $max_x = x1
    end

    if y1 < y2
      if y1 < $min_y
        $min_y = y1
      end

      if y2 > $max_y
        $max_y = y2
      end

    else
      if y2 < $min_y
        $min_y = y2
      end

      if y1 > $max_y
        $max_y = y1
      end

    end
    
  end
  
  ym = /y=(-?[0-9]+), x=(-?[0-9]+)\.\.(-?[0-9]+)/.match(line)
  
  unless ym.nil?
    y1,x1,x2 = ym.captures.map(&:to_i)
    y2 = y1
    walls << {x1: x1, y1: y1, x2: x2, y2: y2}

    if y1 < $min_y
      $min_y = y1
    end

    if y1 > $max_y
      $max_y = y1
    end

    if x1 < x2
      if x1 < $min_x
        $min_x = x1
      end

      if x2 > $max_x
        $max_x = x2
      end

    end
    
  end
  
end

#pp walls

#pp $min_x, $min_y, $max_x, $max_y

# Create the 2d array and populate it with the walls
# Note, add 3 to the left and right to allow for correct edge handling

$min_x -= 3
$max_x += 3

print "Walls: #{$min_x},#{$min_y} -> #{$max_x},#{$max_y}\n"

$width = $max_x - $min_x + 1
$height = $max_y - $min_y + 1

print "World array: w #{$width} h #{$height}\n"

world = Array.new($height) { Array.new($width, '.') }

# Handle our shifting of the world to a zero based array
def convert(x,y)
  x = x - $min_x
  y = y - $min_y
  [x,y]
end

def draw_world(world)
  ($min_y..$max_y).each do |y|
    ($min_x..$max_x).each do |x|
      cx,cy = convert(x,y)
      print "#{world[cy][cx]} "
    end
    print "\n"
  end
  print "\n"
end

walls.each do |wall|
  (wall[:y1]..wall[:y2]).each do |y|
    (wall[:x1]..wall[:x2]).each do |x|
      cx,cy = convert(x,y)

      world[cy][cx] = '#'
    end
  end
end

# start the water
wx, wy = convert(500,$min_y)
world[wy][wx] = 'w'

#draw_world(world)

def settle_right?(world, x, y)

  if x < $min_x || x > $max_x
    false
  end
  
  if world[y][x] == 'w' || world[y][x] == 'W'
    settle_right?(world, x + 1, y)
  elsif world[y][x] == '#'
    true
  else
    false
  end
end

def settle_left?(world, x, y)

  if x < $min_x || x > $max_x
    false
  end
  
  if world[y][x] == 'w' || world[y][x] == 'W'
    settle_left?(world, x - 1, y)
  elsif world[y][x] == '#'
    true
  else
    false
  end
end

# Returns count of water
def iterate(world)

  water = 0
  settled = 0

  ($min_y..$max_y).each do |wy|
    ($min_x..$max_x).each do |wx|
      x,y = convert(wx,wy)

      thing = world[y][x]
      
      if thing == 'W'
        water += 1
        settled += 1
      end
    
      if thing == 'w'
        water +=1
        
        next if y >= $max_y - $min_y

        # Water can move down
        if world[y+1][x] == '.'
          world[y+1][x] = 'w'
        end
        
        # hitting water can move left or right into empty space if supported by
        # settled water 'W' or clay 
        if world[y+1][x] == 'W' && (world[y+1][x-1] == 'W' || world[y+1][x-1] == '#')  && world[y][x-1] == '.'
          world[y][x-1] = 'w'
        end
        if world[y+1][x] == 'W' && (world[y+1][x+1] == 'W' || world[y+1][x+1] == '#') && world[y][x+1] == '.'
          world[y][x+1] = 'w'
        end
        
        # Hitting a floor can move left or right into empty space
        if world[y+1][x] == '#'
          if world[y][x-1] == '.'
            world[y][x-1] = 'w'
          end
          
          if world[y][x+1] == '.'
            world[y][x+1] = 'w'
          end
        end
        
        # This can become settled water if there is nothing but water or clay to the left and right
        if settle_left?(world, x, y) && settle_right?(world, x, y)
          world[y][x] = 'W'
          settled += 1
        end
        
      end
    end
  end

  [water, settled]
end

prev_count = -1
same_for = 0

animate = true
key_wait = false

# Ansi escape codes

$move_up = "\u001b[1A"
$move_down = "\u001b[1B"
$move_right = "\u001b[1C"
$move_left = "\u001b[1D"

$bright_red = "\u001b[31;1m"
$bright_green = "\u001b[32;1m"

loop do

  count, settled = iterate(world)

  if animate
    draw_world(world)
    print "water #{count} settled #{settled}\n"
    print $move_up * ($height + 2)
    sleep 0.4
  end
    
  if count == prev_count
    same_for += 1
    if same_for > 5
      print $move_down * ($height + 2)
      print "water #{count} settled #{settled}\n"
      break
    end
  else
    same_for = 0
  end

  prev_count = count

  if key_wait
    k = STDIN.getch
    
    if k == 'q'
      break
    end
  end
end



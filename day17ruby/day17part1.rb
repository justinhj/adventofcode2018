require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

world = Hash.new('.')

min_y = 9999999
max_y = -9999999
min_x = 999999
max_x = -999999

lines.each do |line|

  xm = /x=(-?[0-9]+), y=(-?[0-9]+)\.\.(-?[0-9]+)/.match(line)
  
  unless xm.nil?
    x,y1,y2 = xm.captures.map(&:to_i)
    #print "#{x},#{y1},#{y2}\n"

    if x < min_x
      min_x = x
    end
    
    if y1 < y2
      if y1 < min_y
        min_y = y1
      end

      if y2 > max_y
        max_y = y2
      end

      (y1..y2).each do |y|
        world[[x,y]] = '#'
      end
      
    else
      if y2 < min_y
        min_y = y2
      end

      if y1 > max_y
        max_y = y1
      end

      (y2..y1).each do |y|
        world[[x,y]] = '#'
      end
      
    end
    
  end
  
  ym = /y=(-?[0-9]+), x=(-?[0-9]+)\.\.(-?[0-9]+)/.match(line)
  
  unless ym.nil?
    y,x1,x2 = ym.captures.map(&:to_i)

    if y < min_y
      min_y = y
    end

    if y > max_y
      max_y = y
    end

    if x1 < x2

      if x1 < min_x
        min_x = x1
      end

      if x2 > max_x
        max_x = x2
      end

      (x1..x2).each do |x|
        world[[x,y]] = '#'
      end
        
    else

      (x2..x1).each do |x|
        world[[x,y]] = '#'
      end

    end
    
  end
  
end

def draw_world(world, min_x, max_x, min_y, max_y)

  (min_y..max_y).each do |y|
    (min_x..max_x).each do |x|
       print "#{world[[x,y]]} "
    end
    print "\n"
  end
  print "\n"
  
end

# start the water
world[[500,0]] = 'w'

draw_world(world, 490, 505, min_y, max_y)

def settle_right?(world, x, y, min_x, max_x)

  if x < min_x || x > max_x
    false
  end
  
  if world[[x,y]] == 'w' || world[[x,y]] == 'W'
    settle_right?(world, x + 1, y, min_x, max_x)
  elsif world[[x,y]] == '#'
    true
  else
    false
  end
end

def settle_left?(world, x, y, min_x, max_x)

  if x < min_x || x > max_x
    false
  end
  
  if world[[x,y]] == 'w' || world[[x,y]] == 'W'
    settle_left?(world, x - 1, y, min_x, max_x)
  elsif world[[x,y]] == '#'
    true
  else
    false
  end
end

# Returns count of water
def iterate(world, min_x, max_x, min_y, max_y)

  water = 0

  old_world = world.to_a
  
  old_world.each do |coord, thing|

    x,y = coord

    if thing == 'W'
      water += 1
    end
    
    if thing == 'w'
#      binding.pry
      water +=1

      next if y == max_y
      
      # Water can move down
      if world[[x,y+1]] == '.'
          world[[x,y+1]] = 'w'
      end

      # hitting water can move left or right into empty space if supported by
      # settled water 'W' or clay 
      if world[[x,y+1]] == 'W' && (world[[x-1,y+1]] == 'W' || world[[x-1,y+1]] == '#')  && world[[x-1,y]] == '.'
        world[[x-1,y]] = 'w'
      end
      if world[[x,y+1]] == 'W' && (world[[x+1,y+1]] == 'W' || world[[x+1,y+1]] == '#') && world[[x+1,y]] == '.'
        world[[x+1,y]] = 'w'
      end
      
      # Hitting a floor can move left or right into empty space
      if world[[x,y+1]] == '#'
        if world[[x-1,y]] == '.'
          world[[x-1,y]] = 'w'
        end

        if world[[x+1,y]] == '.'
          world[[x+1,y]] = 'w'
        end
      end

      # This can become settled water if there is nothing but water or clay to the left and right
      if settle_left?(world, x, y, min_x, max_x) && settle_right?(world, x, y, min_x, max_x)
        world[[x,y]] = 'W'
      end
      
    end
  end

  water
end

printf("Bounds x %d,%d y %d,%d\n", min_x,max_x, min_y, max_y)

loop do

#  binding.pry
  
  count = iterate(world, min_x - 2, max_x + 2, min_y, max_y)
#  draw_world(world, min_x - 2, max_x + 2, min_y, max_y)

  print "water #{count}\n"
  
  # k = STDIN.getch
  
  # if k == 'q'
  #   break
  # end
end


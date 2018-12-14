require 'pry-byebug'
require 'chunky_png'

# Find the fuel cell's rack ID, which is its X coordinate plus 10.
# Begin with a power level of the rack ID times the Y coordinate.
# Increase the power level by the value of the grid serial number (your puzzle input).
# Set the power level to itself multiplied by the rack ID.
# Keep only the hundreds digit of the power level (so 12345 becomes 3; numbers with no hundreds digit become 0).
# Subtract 5 from the power level

def power_level(x,y,serial)
  rack_id = x + 10
  pl = rack_id * y
  pl += serial
  pl *= rack_id

  pl = (pl / 100) % 10

  pl -= 5
end

# puts power_level(3,5,8)

# Fuel cell at  122,79, grid serial number 57: power level -5.
# Fuel cell at 217,196, grid serial number 39: power level  0.
# Fuel cell at 101,153, grid serial number 71: power level  4

# puts power_level(122,79,57)
# puts power_level(217,196,39)
# puts power_level(101,153,71)

def make_grid(serial)
  grid = Hash.new(0)
  (1..300).each do |y|
    (1..300).each do |x|
      grid[[x,y]] = power_level(x,y,serial)
    end
  end
  grid
end

# return best score and the best size
def find_best_size(sat, x, y)

#  print "Analyze #{x},#{y}\n"
  
  best = -1000
  best_size = -1
  size = 1

  while x + size < 300 do
    
    sum = sat_sum(sat, x, y, x + size - 1, y + size - 1)
    
    if sum > best
      best = sum
      best_size = size
    end

    size += 1
  end

  #print "Best #{best} best size #{best_size}\n"
  
  [best, best_size]
  
end

def find_best(sat)
  best = -1000
  best_coord = [0,0]
  best_size = -1
  
  (1..300).each do |y|
    (1..300).each do |x|

      sum, size = find_best_size(sat, x, y)
      
      if sum > best
        print "\nnew best #{sum} coord #{x},#{y} size #{size}\n"
        best = sum
        best_coord = [x,y]
        best_size = size
      end
    end
  end
  
  print "best #{best} at #{best_coord}\n"
  
end

# take the grid and make the summed-area table which
# then allows O(1) sub region summing
def summed_area_table(grid, size)
  out = grid.clone

  (1..size).each do |y|
    (1..size).each do |x|
      out[[x,y]] = out[[x,y]] + out[[x-1,y]] + out[[x,y-1]] - out[[x-1,y-1]]
    end
  end
  out
end

def sat_sum(sat,x1d,y1d,x2,y2)
  x1 = x1d - 1
  y1 = y1d - 1
  sat[[x2,y2]] + sat[[x1,y1]] - sat[[x2,y1]] - sat[[x1,y2]]
end

grid = make_grid(5719)

test_grid = {
  [1,1] => 31, [2,1] => 2, [3,1] => 4, [4,1] => 33, [5,1] => 5, [6,1] => 36,
  [1,2] => 12, [2,2] => 26, [3,2] => 9, [4,2] => 10, [5,2] => 29, [6,2] => 25,
  [1,3] => 13, [2,3] => 17, [3,3] => 21, [4,3] => 22, [5,3] => 20, [6,3] => 18,
  [1,4] => 24, [2,4] => 23, [3,4] => 15, [4,4] => 16, [5,4] => 14, [6,4] => 19,
  [1,5] => 30, [2,5] => 8, [3,5] => 28, [4,5] => 27, [5,5] => 11, [6,5] => 7,
  [1,6] => 1, [2,6] => 35, [3,6] => 34, [4,6] => 3, [5,6] => 32, [6,6] => 6 }

test_grid.default = 0

sat_small = summed_area_table(test_grid, 6)

draw_small = false

if draw_small
  (1..6).each do |y|
    (1..6).each do |x|
      print "#{sat_small[[x,y]]} "
    end
    print "\n"
  end
  print "\n"
end

sat_large = summed_area_table(grid, 300)

def png_grid(grid)
  size = Integer.sqrt(grid.length)
  
  print "create\n"
  png = ChunkyPNG::Image.new(size, size, ChunkyPNG::Color::BLACK)

  print "drawing\n"
  grid.each do |coord,power|
    x = coord[0] - 1
    y = coord[1] - 1
    base = 128
    scale = 30
    if power > 0
      png[x,y] = ChunkyPNG::Color(base + power * scale, 0, 0)
    elsif power < 0
      png[x,y] = ChunkyPNG::Color(0, base + power * -scale, 0)
    end
  end
  
  print "save\n"
  png.save("power.png", :interlace => true)
  
end

png_grid(grid)

# find_best(sat_large)

# best 39405 at [1, 295]
# best 38826 at [1, 295]
# new best 39974 coord 1,300 size 298
# best 39974 at [1, 300]
